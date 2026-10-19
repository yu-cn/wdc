#Requires -Version 7
# verify-machine.ps1 — 机器状态断言（工单 10 验收清单的可执行版）
# 只读验证本机是否与声明完全一致；任何一项 FAIL 即退出码 1。跑一遍约 2-4 分钟（含三域漂移检查）。
# 用法：pwsh scripts/verify-machine.ps1          （VM 验收 / 大改后 / 心里没底时）
#       pwsh scripts/verify-machine.ps1 -Quick   （跳过 winget 漂移检查，秒级）
[CmdletBinding()]
param([switch]$Quick)
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
. (Join-Path $PSScriptRoot 'lib/common.ps1')

$repo = Split-Path $PSScriptRoot -Parent
$script:Fail = 0
function Assert {
    param([string]$Name, [scriptblock]$Body)
    try {
        $ok = & $Body
        if ($ok) { Write-Step $Name 'OK' } else { Write-Step $Name 'FAIL'; $script:Fail++ }
    } catch { Write-Step $Name 'FAIL' $_.Exception.Message; $script:Fail++ }
}

Write-Phase '1/6 · Windows 侧 dotfiles 符号链接'
$docs = [Environment]::GetFolderPath('MyDocuments')
$map = @{
    'gitconfig'    = Join-Path $HOME '.gitconfig'
    'bashrc'       = Join-Path $HOME '.bashrc'
    'pwsh profile' = Join-Path $docs 'PowerShell\Microsoft.PowerShell_profile.ps1'
    'VSCode 设置'  = Join-Path $env:APPDATA 'Code\User\settings.json'
    'WT 设置'      = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
    'starship'     = Join-Path $HOME '.config\starship.toml'
}
foreach ($k in $map.Keys) {
    $name = $k
    Assert $name { (Get-Item $map[$name] -ErrorAction SilentlyContinue).LinkType -eq 'SymbolicLink' }
}
# dotfiles 是符号链接的落点，被机器侧工具写穿会直接污染仓库（gh auth login 实锤，工单14）——验收前必须与 HEAD 一致
Assert 'dotfiles 模板与 HEAD 一致（防写穿）' { @(git -C $repo status --porcelain -- dotfiles).Count -eq 0 }

Write-Phase '2/6 · 身份与注册表断言'
Assert '身份文件有实值' { (git config --file (Join-Path $HOME '.gitidentity') --get user.name) -and (git config --file (Join-Path $HOME '.gitidentity') --get user.email) }
Assert '远程桌面关闭(=1)' { (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -EA SilentlyContinue).fDenyTSConnections -eq 1 }
Assert '系统通知开启(=1)' { (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings' -Name NOC_GLOBAL_SETTING_TOASTS_ENABLED -EA SilentlyContinue).NOC_GLOBAL_SETTING_TOASTS_ENABLED -eq 1 }
Assert '长路径开启' { (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name LongPathsEnabled -EA SilentlyContinue).LongPathsEnabled -eq 1 }

Write-Phase '3/6 · 移除清单核销'
Assert 'oh-my-posh 已卸' { -not (Get-Command oh-my-posh -ErrorAction SilentlyContinue) }
Assert 'nvm 目录已清' { -not (Test-Path (Join-Path $env:LOCALAPPDATA 'nvm')) -and -not (Test-Path 'C:\nvm4w') }
Assert '.NET SDK 已卸' { $null = winget list --id Microsoft.DotNet.SDK.10 -e --accept-source-agreements 2>$null; $LASTEXITCODE -ne 0 }
Assert 'VSCode 单版本(MSIX 已卸)' { -not (Get-AppxPackage -Name 'Microsoft.VisualStudioCode' -ErrorAction SilentlyContinue) }
Assert '.NET Desktop 运行时保留' { ((Get-ChildItem "$env:ProgramFiles\dotnet\shared\Microsoft.WindowsDesktop.App" -EA SilentlyContinue | Measure-Object).Count -ge 1) -or ((Get-ChildItem "${env:ProgramFiles(x86)}\dotnet\shared\Microsoft.WindowsDesktop.App" -EA SilentlyContinue | Measure-Object).Count -ge 1) }
# 清单精确核销（只核有无缺失；机器自装扩展属自留地不核销，ADR-0003）
Assert '扩展清单全部在位' {
    $wanted = @(Get-Content (Join-Path $repo 'configs\vscode-extensions.txt') | Where-Object { $_ -and $_ -notmatch '^\s*#' })
    $have = @(& code --list-extensions 2>$null)
    @($wanted | Where-Object { $have -notcontains $_ }).Count -eq 0
}

Write-Phase '4/6 · 语言栈'
# 两种官方布局都认（工单12）：单体 ~/.vite-plus（安装器默认/复用现有安装）与 LOCALAPPDATA\vite-plus（选根模式）
$vpWinCandidates = @(
    (Join-Path $env:USERPROFILE '.vite-plus\bin\vp.exe')
    (Join-Path $env:LOCALAPPDATA 'vite-plus\bin\vp.exe')
)
Assert 'vp Windows 侧 = 钉子' {
    $vp = $vpWinCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    $vp -and ((& $vp --version) -match '1\.3\.0')
}
Assert 'node 走 vp shim' { (Get-Command node -ErrorAction SilentlyContinue).Source -like '*vite-plus*' }
Assert 'uv 就位' { Get-Command uv -ErrorAction SilentlyContinue }

# WSL 默认用户自动探测（与 install-wsl-env.ps1 同法；硬编码 ubuntu 会误伤默认用户名不同的机器，工单12族）
$wslUser = (((& wsl.exe -d Ubuntu -e bash -c 'whoami') 2>$null) -replace "`0", '').Trim()
Write-Phase '5/6 · WSL 侧'
$wslProbe = (& wsl.exe -d Ubuntu -u $wslUser -e bash -c 'echo "bash:$(getent passwd $(whoami) | cut -d: -f7) go:$(/usr/local/go/bin/go version 2>/dev/null | cut -d" " -f3) uv:$(~/.local/bin/uv --version 2>/dev/null | cut -d" " -f2) node:$(if [ -x ~/.vite-plus/bin/node ]; then ~/.vite-plus/bin/node -v; elif [ -x ~/.local/share/vite-plus/bin/node ]; then ~/.local/share/vite-plus/bin/node -v; else echo MISSING; fi) links:$(readlink ~/.bashrc 2>/dev/null | grep -ci wdc) id:$(git config user.name 2>/dev/null)"') 2>&1
$p = ($wslProbe -replace "`0", '') -join ' '
Write-Step 'WSL 探测' 'INFO' $p
Assert 'WSL bash 默认' { $p -match 'bash:/bin/bash' }
Assert 'WSL Go 1.27.2' { $p -match 'go:go1\.27\.2' }
Assert 'WSL uv' { $p -match 'uv:0\.' }
Assert 'WSL node(vp)' { $p -match 'node:v' }
Assert 'WSL dotfiles 链接' { $p -match 'links:[1-9]' }
Assert 'WSL 身份带过' { $p -match 'id:\S+' }

Write-Phase '6/6 · 三域漂移'
if ($Quick) { Write-Step '漂移检查' 'SKIP' '-Quick 模式跳过' }
else {
    foreach ($d in 'base-windows', 'cli-tools', 'editors') {
        $domain = $d
        Assert "$domain 漂移=0" {
            $out = (winget configure test --file (Join-Path $repo "configs\$domain.winget") --accept-configuration-agreements 2>&1 | ForEach-Object { $_ -replace "`0", '' }) -join "`n"
            (([regex]::Matches($out, '未处于')).Count -eq 0) -and ($LASTEXITCODE -eq 0)
        }
    }
}

Write-Phase '汇总'
if ($script:Fail -eq 0) { Write-Step '机器断言' 'OK' '全部通过——与声明一致'; exit 0 }
Write-Step '机器断言' 'FAIL' "$($script:Fail) 项未通过"; exit 1

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
. (Join-Path $PSScriptRoot 'lib/dotfiles-map.ps1')

$repo = Split-Path $PSScriptRoot -Parent
$script:Fail = 0
function Assert {
    param([string]$Name, [scriptblock]$Body, [string]$FailHint = '')
    try {
        $ok = & $Body
        if ($ok) { Write-Step $Name 'OK' } else { Write-Step $Name 'FAIL' $FailHint; $script:Fail++ }
    } catch { Write-Step $Name 'FAIL' $_.Exception.Message; $script:Fail++ }
}

Write-Phase '1/6 · Windows 侧 dotfiles 符号链接'
# 断言面 = 安装面：落点清单来自 Get-DotfilesMap 单一来源（含 keybindings——此前 6 项清单已实际漏验它）
foreach ($m in (Get-DotfilesMap)) {
    $target = $m.Target
    Assert $m.Name { (Get-Item $target -ErrorAction SilentlyContinue).LinkType -eq 'SymbolicLink' }
}
# dotfiles 是符号链接的落点，被机器侧工具写穿会直接污染仓库（gh auth login 实锤，工单14）——验收前必须与 HEAD 一致
Assert 'dotfiles 模板与 HEAD 一致（防写穿）' { @(git -C $repo status --porcelain -- dotfiles).Count -eq 0 } '写穿漂移——处置：pwsh scripts/triage-dotfiles-drift.ps1（逐文件 吸收/还原）'
# 钩子接线断言（工单23）：collaboration 承诺 pre-commit 把关；接线由 bootstrap Stage 6 幂等保证
Assert 'pre-commit 钩子已接线' { (git -C $repo config core.hooksPath) -eq '.githooks' } 'git config core.hooksPath .githooks（repo-local；下次 bootstrap 会自动接上）'
# WT 的 WSL profile 走机器适配 fragment（ADR-0004）：模板不含 WSL 条目，fragment 应已渲染且含本机发行版
Assert 'WT WSL fragment 已渲染' {
    $frag = Join-Path (Get-WtLocalStateDir) 'fragments\wdc-wsl.json'
    (Test-Path $frag) -and ((Get-Content $frag -Raw) -match 'Ubuntu')
}

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
Assert 'vp Windows 侧 = 钉子' {
    $vp = Get-VpWinExe
    $vp -and ((& $vp --version) -match [regex]::Escape((Get-VpPin)))
}
Assert 'node 走 vp shim' { (Get-Command node -ErrorAction SilentlyContinue).Source -like '*vite-plus*' }
Assert 'uv 就位' { Get-Command uv -ErrorAction SilentlyContinue }

# WSL 默认用户自动探测（Get-WslDefaultUser；硬编码用户名会误伤默认用户名不同的机器，工单12族）
$wslUser = Get-WslDefaultUser
Write-Phase '5/6 · WSL 侧'
# 探测走 scripts/wsl/probe.sh（与安装期 install-wsl-env.ps1 同源，工单05；key:value 单行输出）
$probeSh = ConvertTo-WslPath (Join-Path $repo 'scripts\wsl\probe.sh')
$probe = Invoke-WslScript -Distro 'Ubuntu' -User $wslUser -Script $probeSh
$probeMap = @{}
foreach ($line in ($probe.Lines | Where-Object { $_ })) { $k, $v = $line -split ':', 2; $probeMap[$k] = $v }
Write-Step 'WSL 探测' 'INFO' (($probe.Lines | Where-Object { $_ }) -join ' ')
Assert 'WSL bash 默认' { $probeMap['shell'] -eq '/bin/bash' }
Assert 'WSL docker' { $probeMap['docker'] -match '^[0-9]' }
Assert 'WSL uv' { $probeMap['uv'] -ne 'MISSING' }
Assert 'WSL node(vp)' { $probeMap['node'] -match '^v' }
Assert 'WSL dotfiles 链接' { [int]$probeMap['links'] -ge 1 }
Assert 'WSL 身份带过' { $probeMap['id'] -ne 'MISSING' }

Write-Phase '6/6 · 三域漂移'
if ($Quick) { Write-Step '漂移检查' 'SKIP' '-Quick 模式跳过' }
else {
    try { $domains = Get-WdcDomains } catch { Write-Step '域清单' 'FAIL' $_.Exception.Message; exit 1 }
    foreach ($d in $domains) {
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

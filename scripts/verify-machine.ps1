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

Write-Phase '1/6 · Windows 侧 dotfiles 渲染拷贝'
# 断言面 = 安装面：落点清单来自 Get-DotfilesMap 单一来源（含 keybindings——此前 6 项清单已实际漏验它）；
# 状态判定单一来源 = Test-DotfileInSync。断效果不断实现（坑11 教训）：断「落点与模板内容一致」，
# 不断言链接形态；「dotfiles 模板与 HEAD 一致（防写穿）」断言随渲染拷贝模型退役（ADR-0015——机器侧
# 工具直改的是落点渲染物，仓库不再可能被写穿；落点漂移由下面的逐项比对抓取）
$dotfilesRoot = Join-Path $repo 'dotfiles'
foreach ($m in (Get-DotfilesMap)) {
    $src = Join-Path $dotfilesRoot $m.Source
    $target = $m.Target
    Assert $m.Name { (Test-DotfileInSync -Source $src -Target $target) -eq 'ok' } "落点缺失或与模板不一致——重跑 bootstrap 渲染（幂等）；机器侧直改的取舍走 wdc triage（逐文件 吸收/还原）"
}
# 钩子接线断言（工单23）：collaboration 承诺 pre-commit 把关；接线由 bootstrap Stage 6 幂等保证
Assert 'pre-commit 钩子已接线' { (git -C $repo config core.hooksPath) -eq '.githooks' } 'git config core.hooksPath .githooks（repo-local；下次 bootstrap 会自动接上）'
# 续跑任务断言（GLOSSARY「续跑任务」）：任务只在「请求过重启」时登记、任何 bootstrap 启动即清除——
# 存续即说明有一次重启后的收敛没跑完（效果级断言，坑11：断言效果不断言中间产物）
Assert '续跑任务已清' { -not (Test-WdcResumeTaskExists) } '存在待续跑任务——重启登录后自动续跑，或直接重跑 bootstrap.ps1 接管'
# WSL profile 为模板静态声明（ADR-0006），无机器侧产物需要断言；WT settings 渲染本身由上面的映射断言覆盖
Assert 'Ubuntu WSL 图标资产在位' { Test-Path (Join-Path $env:LOCALAPPDATA 'wdc\ubuntu.ico') } '缺失：重跑 bootstrap（install-dotfiles 会装 dotfiles/windows/ubuntu.ico）'

Write-Phase '2/6 · 身份与注册表断言'
# 效果级断言：全栈查询才展开 include（--global 按设计不展开会假阴性，坑⑤）——直接证明 git 能经 include 链取到身份
Assert 'git 身份经 include 生效' { [bool](git -C $repo config user.name) -and [bool](git -C $repo config user.email) } '身份未生效：查 ~/.gitidentity 实值与 gitconfig 的 include.path'
Assert '远程桌面关闭(=1)' { (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -EA SilentlyContinue).fDenyTSConnections -eq 1 }
Assert '系统通知开启(=1)' { (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings' -Name NOC_GLOBAL_SETTING_TOASTS_ENABLED -EA SilentlyContinue).NOC_GLOBAL_SETTING_TOASTS_ENABLED -eq 1 }
Assert '长路径开启' { (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name LongPathsEnabled -EA SilentlyContinue).LongPathsEnabled -eq 1 }

Write-Phase '3/6 · 移除清单核销'
# VSCode 自更新会在安装目录内注册 Developer 签名的 identity MSIX（1.0.x sparse 包，坑13）——非商店第二份；
# 商店安装必为 Store 签名，按签名只拦真商店版（identity 包按包名卸了会随每次自更新回归）
Assert 'VSCode 单版本(商店 MSIX 已卸)' { -not (Get-AppxPackage -Name 'Microsoft.VisualStudioCode' -ErrorAction SilentlyContinue | Where-Object SignatureKind -eq 'Store') }
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
Write-Phase '5/6 · WSL 侧（LDC 委托，工单32/LDC-0007）'
# WSL 特有项走 scripts/wsl/probe.sh（与安装期 install-wsl-env.ps1 同源，工单05）：默认 shell、systemd——
# WDC 保留职责（LDC-0007 契约），不随委托移交
$probeSh = ConvertTo-WslPath (Join-Path $repo 'scripts\wsl\probe.sh')
$probe = Invoke-WslScript -Distro 'Ubuntu' -User $wslUser -Script $probeSh
$probeMap = @{}
foreach ($line in ($probe.Lines | Where-Object { $_ })) { $k, $v = $line -split ':', 2; $probeMap[$k] = $v }
Write-Step 'WSL 探测' 'INFO' (($probe.Lines | Where-Object { $_ }) -join ' ')
Assert 'WSL bash 默认' { $probeMap['shell'] -eq '/bin/bash' } 'root 阶段重跑（setup-ubuntu.sh 的 WDC opinion chsh）'
Assert 'WSL systemd 开启' { $probeMap['systemd'] -eq 'yes' } '/etc/wsl.conf 已写入但未生效——wsl --shutdown 后下次进入生效'
# 发行版内一切（包/语言栈/dotfiles/身份/docker）委托 LDC verify —— 断言面即 LDC 单一实现（工单32）
$verifySh = ConvertTo-WslPath (Join-Path $repo 'scripts\wsl\verify-ldc.sh')
$ldc = Invoke-WslScript -Distro 'Ubuntu' -User $wslUser -Script $verifySh
$ldc.Lines | ForEach-Object { Write-Host $_ }
Assert 'WSL LDC verify --quick' { $ldc.Ok } 'LDC 断言未全绿——重跑 bootstrap（幂等）或发行版内 ldc sync'

Write-Phase '6/6 · 三域漂移'
if ($Quick) { Write-Step '漂移检查' 'SKIP' '-Quick 模式跳过' }
else {
    # 工单01 方案A：未提权会话对含 HKLM/机器级单元的域评估不可靠（评估失败被记为「未处于」，整域假警报）——
    # 相关域降级 SKIP，退出码不因假警报红；提权重跑才计入 FAIL。域的相关性由 Test-WdcDomainNeedsElevation 单一来源声明。
    $unelevated = -not (Test-IsElevated)
    if ($unelevated) { Write-Step '提权状态' 'INFO' '未提权会话对含 HKLM/机器级单元的域评估不可靠——相关域降为 SKIP，提权重跑才计入' }
    try { $domains = Get-WdcDomains } catch { Write-Step '域清单' 'FAIL' $_.Exception.Message; exit 1 }
    foreach ($d in $domains) {
        $domain = $d
        if ($unelevated -and (Test-WdcDomainNeedsElevation -Domain $domain)) {
            Write-Step "$domain 漂移" 'SKIP' '含 HKLM/机器级单元——未提权评估不可靠（工单01），提权重跑验证'
            continue
        }
        Assert "$domain 漂移=0" {
            $out = (winget configure test --file (Join-Path $repo "configs\$domain.winget") --accept-configuration-agreements 2>&1 | ForEach-Object { $_ -replace "`0", '' }) -join "`n"
            (([regex]::Matches($out, '未处于')).Count -eq 0) -and ($LASTEXITCODE -eq 0)
        } '漂移≠0 或评估失败——先看会话是否提权：HKLM/机器级域未提权评估不可靠（工单01）；真漂移用 winget configure 应用收敛'
    }
}

Write-Phase '汇总'
if ($script:Fail -eq 0) { Write-Step '机器断言' 'OK' '全部通过——与声明一致'; exit 0 }
Write-Step '机器断言' 'FAIL' "$($script:Fail) 项未通过"; exit 1

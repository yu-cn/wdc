#Requires -Version 7
# install-wsl-env.ps1 — WSL 侧发行版内环境编排（工单32：薄委托 LDC，ADR-0007 统筹）
# WDC 保留 WSL 生命周期引导（apt 引导依赖 / wsl.conf systemd / 默认 shell）+ WDC 特有 opinion
# （移除清单 Go 等）+ 身份带过；包/语言栈/dotfiles/验收全部委托姊妹仓库 LDC（~/dev/ldc）——
# root 委托其 install-packages.sh，user 委托其 bootstrap.sh。全部幂等。
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/common.ps1')

# WSL/Ubuntu 未就位则跳过（install-wsl.ps1 会先处理）
if ((Get-WslDistros) -notcontains 'Ubuntu') {
    Write-Step 'WSL 环境' 'SKIP' 'Ubuntu 未就位（install-wsl.ps1 先行）'
    exit 0
}

# 仓库路径 -> WSL 视角
$repoWsl = ConvertTo-WslPath (Split-Path $PSScriptRoot -Parent)

# WSL 默认用户
$wslUser = Get-WslDefaultUser
if (-not $wslUser) {
    Write-Step 'WSL 用户' 'FAIL' '无法探测 Ubuntu 默认用户（发行版可能未完成初始化）'
    exit 1
}
$setupSh = "$repoWsl/scripts/wsl/setup-ubuntu.sh"
$probeSh = "$repoWsl/scripts/wsl/probe.sh"
$winIdentity = "/mnt/c/Users/$env:USERNAME/.gitidentity"

Write-Phase "WSL root 阶段（用户 $wslUser）"
$root = Invoke-WslScript -Distro 'Ubuntu' -User 'root' -Script $setupSh -ScriptArgs @('root', $wslUser)
$root.Lines | ForEach-Object { Write-Host $_ }
if (-not $root.Ok) { Write-Step 'root 阶段' 'FAIL' "退出码 $($root.Exit)"; exit 1 }
Write-Step 'root 阶段' 'OK' 'LDC 委托（apt/gh/Docker）+ WDC opinion（systemd/Go/shell/docker组）完成'

Write-Phase 'WSL user 阶段'
$user = Invoke-WslScript -Distro 'Ubuntu' -User $wslUser -Script $setupSh -ScriptArgs @('user', $wslUser, $winIdentity)
$user.Lines | ForEach-Object { Write-Host $_ }
if (-not $user.Ok) { Write-Step 'user 阶段' 'FAIL' "退出码 $($user.Exit)"; exit 1 }
Write-Step 'user 阶段' 'OK' 'LDC bootstrap 完成（uv/vp/starship/dotfiles 归 LDC 单一实现）'

# WSL 特有项探测（scripts/wsl/probe.sh：shell/systemd 两键——发行版内其余断言已归 LDC，工单32）
$probe = Invoke-WslScript -Distro 'Ubuntu' -User $wslUser -Script $probeSh
Write-Step '环境探测' 'INFO' (($probe.Lines | Where-Object { $_ }) -join ' ')
exit 0

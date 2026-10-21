#Requires -Version 7
# install-wsl-env.ps1 — WSL 侧发行版内环境编排（工单 07）
# 以 root 跑 apt/Docker/chsh（并移除退出通用核心的 Go，工单21/22），以默认用户跑 uv/vp/dotfiles/身份；全部幂等。
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
$root = Invoke-WslScript -Distro 'Ubuntu' -User 'root' -Script $setupSh -ScriptArgs @('root', $wslUser, $repoWsl)
$root.Lines | ForEach-Object { Write-Host $_ }
if (-not $root.Ok) { Write-Step 'root 阶段' 'FAIL' "退出码 $($root.Exit)"; exit 1 }
Write-Step 'root 阶段' 'OK' 'apt/gh/Docker/默认shell 完成'

Write-Phase 'WSL user 阶段'
$user = Invoke-WslScript -Distro 'Ubuntu' -User $wslUser -Script $setupSh -ScriptArgs @('user', $wslUser, $repoWsl, $winIdentity)
$user.Lines | ForEach-Object { Write-Host $_ }
if (-not $user.Ok) { Write-Step 'user 阶段' 'FAIL' "退出码 $($user.Exit)"; exit 1 }
Write-Step 'user 阶段' 'OK' 'uv/vp/starship/dotfiles/身份 完成'

# 环境探测（scripts/wsl/probe.sh：key:value 单行输出，与 verify-machine 断言共口径——工单05）
$probe = Invoke-WslScript -Distro 'Ubuntu' -User $wslUser -Script $probeSh
Write-Step '环境探测' 'INFO' (($probe.Lines | Where-Object { $_ }) -join ' ')
exit 0

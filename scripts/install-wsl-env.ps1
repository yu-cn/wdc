#Requires -Version 7
# install-wsl-env.ps1 — WSL 侧发行版内环境编排（工单32：薄委托 LDC，LDC-0007 统筹）
# WDC 保留 WSL 生命周期引导（apt 引导依赖 / wsl.conf systemd / 默认 shell）+ 身份带过；
# 包/语言栈/dotfiles/验收全部委托姊妹仓库 LDC（~/dev/ldc）——
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
# CI 冒烟降级开关：Windows 侧判定（$env:GITHUB_ACTIONS）显式传参——WSL 发行版不继承宿主 env
#（仅 WSLENV 声明的跨界），在发行版内探测恒空（run 40217849824 实录）；LDC_SMOKE 让 LDC bootstrap
# 的占位身份待办降级不计（LDC ADR-0004），真机不传、护栏不动
$smokeArg = @(); if ($env:GITHUB_ACTIONS) { $smokeArg = @('1') }
# CI 冒烟交界面化（工单 02）：SKIP_LDC=1 时发行版内不 clone LDC、不委托安装/bootstrap——
# 只跑 WDC 保留职责面（wsl.conf systemd / 默认 shell / 身份带过），LDC 本体收敛归 LDC 容器冒烟
$skipLdcArg = @(); if ($env:GITHUB_ACTIONS) { $skipLdcArg = @('1') }

if ($env:GITHUB_ACTIONS) { Write-Step 'WSL 冒烟模式' 'INFO' 'CI 交界面化（工单 02）：跳过 LDC 本体安装，只验 wsl.conf/shell/身份/probe 交界面' }

Write-Phase "WSL root 阶段（用户 $wslUser）"
# $3 必须占位（root 角色不用身份文件，但 SKIP_LDC 在 $5——少占位会把 '1' 顶进 IDENT_SRC、SKIP_LDC 落空，
# run 40222841315 实录：冒烟绿但 root 段交界面化未生效，日志 grep 才抓出）
$root = Invoke-WslScript -Distro 'Ubuntu' -User 'root' -Script $setupSh -ScriptArgs (@('root', $wslUser, '') + $smokeArg + $skipLdcArg)
$root.Lines | ForEach-Object { Write-Host $_ }
if (-not $root.Ok) { Write-Step 'root 阶段' 'FAIL' "退出码 $($root.Exit)"; exit 1 }
if ($skipLdcArg) {
    Write-Step 'root 阶段' 'SKIP' 'CI 交界面化——LDC install-packages 委托未跑（WDC opinion wsl.conf/shell 已落地）'
} else {
    Write-Step 'root 阶段' 'OK' 'LDC 委托（apt/gh/Docker）+ WDC opinion（systemd/shell/docker组）完成'
}

Write-Phase 'WSL user 阶段'
$user = Invoke-WslScript -Distro 'Ubuntu' -User $wslUser -Script $setupSh -ScriptArgs (@('user', $wslUser, $winIdentity) + $smokeArg + $skipLdcArg)
$user.Lines | ForEach-Object { Write-Host $_ }
if (-not $user.Ok) { Write-Step 'user 阶段' 'FAIL' "退出码 $($user.Exit)"; exit 1 }
if ($skipLdcArg) {
    Write-Step 'user 阶段' 'SKIP' 'CI 交界面化——LDC bootstrap 委托未跑（身份带过已完成）'
} else {
    Write-Step 'user 阶段' 'OK' 'LDC bootstrap 完成（uv/vp/starship/dotfiles 归 LDC 单一实现）'
}

# WSL 特有项探测（scripts/wsl/probe.sh：shell/systemd 两键——发行版内其余断言已归 LDC，工单32）
$probe = Invoke-WslScript -Distro 'Ubuntu' -User $wslUser -Script $probeSh
Write-Step '环境探测' 'INFO' (($probe.Lines | Where-Object { $_ }) -join ' ')
exit 0

#Requires -Version 7
# install-wsl-env.ps1 — WSL 侧发行版内环境编排（工单32：薄委托 LDC，LDC-0007 统筹）
# 工单41 边界最小核心化后 WDC 只保留编排者最小面：apt 引导依赖 + LDC 定位 + 身份带过；
# 包/语言栈/dotfiles/机器形态（默认 shell/wsl.conf systemd/docker 组）/验收全部归 LDC
# 单一实现（~/dev/ldc，LDC 工单12 承接）——root 委托其 install-packages.sh（LDC_USER 传
# WSL 默认用户，ADR-0007），user 委托其 bootstrap.sh。全部幂等。
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
$winIdentity = "/mnt/c/Users/$env:USERNAME/.gitidentity"
# CI 冒烟降级开关：Windows 侧判定（$env:GITHUB_ACTIONS）显式传参——WSL 发行版不继承宿主 env
#（仅 WSLENV 声明的跨界），在发行版内探测恒空（run 40217849824 实录）；LDC_SMOKE 让 LDC bootstrap
# 的占位身份待办降级不计（LDC ADR-0004），真机不传、护栏不动
$smokeArg = @(); if ($env:GITHUB_ACTIONS) { $smokeArg = @('1') }
# CI 冒烟交界面化（工单 02）：SKIP_LDC=1 时发行版内不 clone LDC、不委托安装/bootstrap——
# 只跑 WDC 最小面（身份带过），LDC 本体收敛归 LDC 容器冒烟
$skipLdcArg = @(); if ($env:GITHUB_ACTIONS) { $skipLdcArg = @('1') }

if ($env:GITHUB_ACTIONS) { Write-Step 'WSL 冒烟模式' 'INFO' 'CI 交界面化（工单 02）：跳过 LDC 本体安装，只验 wsl.conf/shell/身份/probe 交界面' }

Write-Phase "WSL root 阶段（用户 $wslUser）"
# $3 必须占位（root 角色不用身份文件，但 SKIP_LDC 在 $5——少占位会把 '1' 顶进 IDENT_SRC、SKIP_LDC 落空，
# run 40222841315 实录）；占位用 '-' 不能用空串——Start-Process ArgumentList 拒绝空串元素
#（run 40224424790 实录：Cannot bind argument 'ArgumentList' ... empty string）
$root = Invoke-WslScript -Distro 'Ubuntu' -User 'root' -Script $setupSh -ScriptArgs (@('root', $wslUser, '-') + $smokeArg + $skipLdcArg)
$root.Lines | ForEach-Object { Write-Host $_ }
if (-not $root.Ok) { Write-Step 'root 阶段' 'FAIL' "退出码 $($root.Exit)"; exit 1 }
if ($skipLdcArg) {
    Write-Step 'root 阶段' 'SKIP' 'CI 交界面化——LDC install-packages 委托未跑（WDC 最小面无发行版内动作）'
} else {
    Write-Step 'root 阶段' 'OK' 'LDC 委托完成（apt/gh/Docker/机器形态三件归 LDC 单一实现，工单41）'
}

Write-Phase 'WSL user 阶段'
$user = Invoke-WslScript -Distro 'Ubuntu' -User $wslUser -Script $setupSh -ScriptArgs (@('user', $wslUser, $winIdentity) + $smokeArg + $skipLdcArg)
$user.Lines | ForEach-Object { Write-Host $_ }
if (-not $user.Ok) { Write-Step 'user 阶段' 'FAIL' "退出码 $($user.Exit)"; exit 1 }
if ($skipLdcArg) {
    Write-Step 'user 阶段' 'SKIP' 'CI 交界面化——LDC bootstrap 委托未跑（身份带过已完成）'
} else {
    Write-Step 'user 阶段' 'OK' 'LDC bootstrap 完成（uv/mise/starship/dotfiles 归 LDC 单一实现）'
}

exit 0

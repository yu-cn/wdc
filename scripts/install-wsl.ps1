#Requires -Version 7
# install-wsl.ps1 — WSL 侧安装编排（工单 06；工单 30 重写：全程提权下安全执行）
# 全新机器路径：提权回合内启用 WSL（安装命令新控制台、不捕获——坑①纪律）→ 重启 → 重跑 bootstrap 装 Ubuntu。
# 启用/安装均 BestEffort：自动路径失败或超时降级为手工指引，不打红 bootstrap（上游 Set-DevConfigStepUnverified 同思想）。
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/common.ps1')

$elevated = Test-IsElevated

# --- 1) WSL 功能 ---
if (Test-WslEnabled) {
    Write-Step 'WSL 功能' 'OK' '已启用'
} elseif (-not $elevated) {
    Write-Step 'WSL 功能' 'SKIP' '未启用且本回合非提权——提权重跑 bootstrap 自动启用（或手工：管理员终端 wsl --install 后重启续跑）'
    exit 0
} else {
    # 安装类命令：新控制台、绝不捕获输出（上游实证姿势——wsl 安装引导需要真控制台；坑①的「管道捕获」条件在此不成立）
    $p = Start-Process wsl.exe -ArgumentList '--install', '--no-distribution' -PassThru
    try { $code = Wait-WdcProcess -Process $p -TimeoutSeconds 900 -Label 'wsl --install --no-distribution' }
    catch [System.TimeoutException] {
        Write-Step 'WSL 功能' 'INFO' "自动启用超时被终止——手工路径：管理员终端 wsl --install 并重启，再重跑 bootstrap"
        exit 0
    }
    if ($code -eq 0 -or $code -eq 3010 -or $code -eq 1641) {
        # 3010/1641 = 需重启（上游同款判定）
        Write-Step 'WSL 功能' 'CHANGED' '已启用（需重启激活）——重启电脑后重跑 bootstrap 安装 Ubuntu'
    } else {
        Write-Step 'WSL 功能' 'INFO' "自动启用未成（退出码 $code）——手工路径：管理员终端 wsl --install 并重启，再重跑 bootstrap"
    }
    exit 0
}

# --- 2) Ubuntu 发行版 ---
if ((Get-WslDistros) -contains 'Ubuntu') {
    Write-Step 'Ubuntu' 'OK' '已就位'
    exit 0
}
if (-not $elevated) {
    Write-Step 'Ubuntu' 'SKIP' '未安装且本回合非提权——提权重跑 bootstrap 时安装'
    exit 0
}
$p = Start-Process wsl.exe -ArgumentList '--install', '-d', 'Ubuntu', '--no-launch' -PassThru
try { $code = Wait-WdcProcess -Process $p -TimeoutSeconds 1200 -Label 'wsl --install -d Ubuntu' }
catch [System.TimeoutException] {
    Write-Step 'Ubuntu' 'INFO' "自动安装超时被终止——手工路径：管理员终端 wsl --install -d Ubuntu，完成后重跑 bootstrap"
    exit 0
}
if ($code -ne 0) {
    Write-Step 'Ubuntu' 'INFO' "自动安装未成（退出码 $code）——手工路径：管理员终端 wsl --install -d Ubuntu，完成后重跑 bootstrap"
    exit 0
}
# 效果确认（上游 Wait-DevConfigUbuntuVisible 同款）：--no-launch 安装完成后 wsl -l 的列表可能滞后
$visible = $false
for ($i = 1; $i -le 10; $i++) {
    if ((Get-WslDistros) -contains 'Ubuntu') { $visible = $true; break }
    if ($i -eq 1) { Write-Step 'Ubuntu' 'INFO' '等待发行版出现在 wsl -l…' }
    Start-Sleep -Seconds 3
}
if ($visible) {
    Write-Step 'Ubuntu' 'CHANGED' '已安装；首次进入完成初始用户设置（终端输 wsl 回车），随后重跑 bootstrap 配发行版环境'
} else {
    Write-Step 'Ubuntu' 'INFO' '命令成功但 wsl -l 暂未见 Ubuntu——稍后重跑 bootstrap 复查'
}
exit 0

#Requires -Version 7
# install-wsl.ps1 — WSL 侧安装编排（工单 06）：确保 WSL 功能 + Ubuntu 就位
# 全新机器路径需要提权与一次重启；已就位机器上幂等通过。
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/common.ps1')

$elevated = Test-IsElevated

# --- 1) WSL 功能 ---
$wslStatus = (& wsl.exe --status) 2>&1
$wslWorks = ($LASTEXITCODE -eq 0)
if (-not $wslWorks) {
    if (-not $elevated) {
        Write-Step 'WSL 功能' 'SKIP' '本机未启用 WSL 且需要管理员+重启——提权运行 bootstrap 并重启后续跑'
        exit 0
    }
    & wsl.exe --install --no-distribution
    Write-Step 'WSL 组件' 'CHANGED' '已启用，需要一次重启；重启后重跑 bootstrap 继续（安装 Ubuntu）'
    exit 0
}
Write-Step 'WSL 功能' 'OK' '已启用'

# --- 2) Ubuntu 发行版 ---
$distros = @((& wsl.exe -l -q) 2>$null | ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ })
if ($distros -contains 'Ubuntu') {
    Write-Step 'Ubuntu' 'OK' '已就位'
    exit 0
}
if (-not $elevated) {
    Write-Step 'Ubuntu' 'SKIP' '未安装且 wsl --install 需要管理员——提权重跑 bootstrap 时安装'
    exit 0
}
& wsl.exe --install -d Ubuntu --no-launch
Write-Step 'Ubuntu' 'CHANGED' '已安装；首次进入需完成初始用户设置，然后重跑 bootstrap'
exit 0

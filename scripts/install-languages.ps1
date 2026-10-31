#Requires -Version 7
# install-languages.ps1 — 编排层：语言默认环境（mise · node@lts）
# 用户级操作，无需提权。mise 本体由 cli-tools 域声明安装（winget jdx.mise，useLatest 免钉），
# 此脚本只管默认环境——对齐 LDC 侧同款（LDC ADR-0016；vp 已退役，存量机清除走 remove-leftovers 迁移通道）。
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/common.ps1')

Write-Phase 'Languages - 默认环境（mise node@lts）'
$miseCmd = Get-Command mise -ErrorAction SilentlyContinue
if (-not $miseCmd) {
    Write-Step 'mise' 'FAIL' '未找到——cli-tools 域应已 winget 安装（jdx.mise），重跑 bootstrap'
    exit 1
}
$mise = $miseCmd.Source
# ensure 型（幂等重发即随最新 LTS，零维护口径）：报 OK 不报 CHANGED——
# 首装变更信号由 winget 域安装记账承担（幂等重跑零 [CHANGED] 基线，对齐 LDC 同款）
$useOut = (& $mise use -g 'node@lts' 2>&1 | Out-String)
if ($LASTEXITCODE -ne 0) {
    # FAIL 带错误尾证（冒烟实录：吞输出致瞬态无诊断面，对齐 LDC 同款）
    $tail = ($useOut -split "`n" | Select-Object -Last 3) -join ' '
    Write-Step 'mise use -g node@lts' 'FAIL' "退出码 $LASTEXITCODE：$tail"
    exit 1
}
$nodeV = (& $mise exec node -- node -v) 2>$null
if ($LASTEXITCODE -eq 0 -and $nodeV) {
    Write-Step 'node 默认环境' 'OK' "已确保就位（$nodeV，经 mise 解析）"
} else {
    Write-Step 'node 默认环境' 'FAIL' 'mise exec node 解析失败——重跑本脚本'
    exit 1
}
exit 0

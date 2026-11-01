#Requires -Version 7
# install-languages.ps1 — 编排层：语言默认环境（mise · node@lts）
# 用户级操作，无需提权。mise 本体由 cli-tools 域声明安装（winget jdx.mise，useLatest 免钉），
# 此脚本只管默认环境——对齐 LDC 侧同款（LDC ADR-0016；vp 已退役，存量机清除走 remove-leftovers 迁移通道）。
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/common.ps1')

Write-Phase 'Languages - 默认环境（mise node@lts）'
# mise 探测（strict 安全 + 多级兜底）：common.ps1 Set-StrictMode Latest 下 $null.Source 会抛
# PropertyNotFound 终止脚本（run 41210369668 重跑腿实录——兜底代码没跑到先炸）——三步走：
# ① 会话 PATH ② 注册表 PATH 刷新再试（winget 安装期写入 Links 条目，早启进程树的会话
# PATH 快照可能未含）③ WinGet Links 绝对路径（Get-VpWinExe 同款智慧）。全败才 FAIL 带证据。
$mise = $null
$miseCmd = Get-Command mise -ErrorAction SilentlyContinue
if ($miseCmd) { $mise = $miseCmd.Source }
if (-not $mise) {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    $miseCmd = Get-Command mise -ErrorAction SilentlyContinue
    if ($miseCmd) { $mise = $miseCmd.Source }
}
if (-not $mise) {
    $links = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\mise.exe'
    if (Test-Path $links) { $mise = $links }
}
if (-not $mise) {
    $linksDir = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links'
    $inPath = @($env:Path -split ';' | Where-Object { $_ -like '*WinGet*' }) -join ','
    Write-Step 'mise' 'FAIL' "未找到——PATH 含 WinGet 条目=[$inPath]；Links 目录=$(Test-Path $linksDir)；mise.exe=$(Test-Path (Join-Path $linksDir 'mise.exe'))"
    exit 1
}
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

# 用户 PATH 注册表确保 mise shims（vp 安装器的对等动作，vp→mise 迁移补齐）：非 shell 进程
# （如 IDE/agent 的 MCP 插件按裸 node 拉起）依赖全局 node 解析——vp 时代由其安装器写入
# ~/.vite-plus\bin，mise 无此动作须补（实录：ZCode 上下文插件经会话残留 PATH 解析进 vp
# shim 链，vp 目录因此无法清除——run 后实录见工单39）
$shims = Join-Path $env:LOCALAPPDATA 'mise\shims'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (($userPath -split ';') -notcontains $shims) {
    [Environment]::SetEnvironmentVariable('Path', ($userPath.TrimEnd(';') + ';' + $shims), 'User')
    Write-Step 'mise shims → 用户 PATH' 'CHANGED' "已写入 $shims"
} else {
    Write-Step 'mise shims → 用户 PATH' 'OK' "已在位（$shims）"
}
exit 0

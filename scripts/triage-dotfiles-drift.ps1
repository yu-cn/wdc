#Requires -Version 7
# triage-dotfiles-drift.ps1 — dotfiles 写穿漂移分流（工单 17）
# 被符号链接的 dotfiles 会被机器侧工具写穿（实录：gh / VSCode / WT / vp env on，见 docs/agents/collaboration.md 坑⑥）；
# verify-machine.ps1 的「dotfiles 与 HEAD 一致」断言负责发现，本脚本负责处置：
# 逐文件二选一——吸收进模板（点名偏好，显式路径 commit）或还原为机器噪声（checkout 回 HEAD）。
# 判据见 ADR-0003：只有点名要的偏好才吸收，其余按机器噪声还原。
# 用法：pwsh scripts/triage-dotfiles-drift.ps1            （交互分流）
#       pwsh scripts/triage-dotfiles-drift.ps1 -DryRun    （只看差异不动手）
[CmdletBinding()]
param([switch]$DryRun)
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
. (Join-Path $PSScriptRoot 'lib/common.ps1')

$repo = Split-Path $PSScriptRoot -Parent
Set-Location $repo

$lines = @(git status --porcelain -- dotfiles)
if ($lines.Count -eq 0) {
    Write-Step 'dotfiles 漂移' 'OK' '与 HEAD 一致，无需分流'
    exit 0
}

Write-Phase "dotfiles 漂移（$($lines.Count) 项）"
$absorb = [System.Collections.Generic.List[string]]::new()
$restored = 0
foreach ($line in $lines) {
    # porcelain 行格式 XY PATH（重命名含 "ORIG -> PATH"，取箭头后段；本仓库 dotfiles 文件名均为简单 ASCII）
    $code = $line.Substring(0, 2)
    $path = ($line.Substring(3) -split ' -> ')[-1]
    if ($code -eq '??') {
        Write-Step $path 'INFO' '未跟踪文件——脚本不动，请人工判断（机器噪声直接删除）'
        continue
    }
    git diff HEAD -- $path | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
    if ($DryRun) { continue }
    $answer = (Read-Host "$path  [a]吸收进模板  [r]还原为噪声(回车默认)  [s]跳过").Trim().ToLower()
    switch ($answer) {
        'a' { $absorb.Add($path); Write-Step $path 'CHANGED' '待吸收（稍后合并为一个 commit）' }
        's' { Write-Step $path 'SKIP' '' }
        default { git checkout HEAD -- $path; $restored++; Write-Step $path 'OK' '已还原为 HEAD 版本' }
    }
}

if ($DryRun) { exit 0 }

# 红线：吸收走显式路径 pathspec commit，绝不 git add -A
if ($absorb.Count -gt 0) {
    $default = "chore(dotfiles): 吸收写穿偏好（$($absorb -join ', ')）"
    $msg = (Read-Host 'commit 信息（回车用默认）').Trim()
    if (-not $msg) { $msg = $default }
    git commit -m $msg -- @($absorb)
    Write-Step '吸收 commit' 'OK' $msg
}
if ($restored -gt 0) { Write-Step '还原' 'INFO' "$restored 个文件已回到 HEAD" }

$left = @(git status --porcelain -- dotfiles)
if ($left.Count -eq 0) { Write-Step '收尾' 'OK' 'dotfiles 与 HEAD 一致' }
else { Write-Step '收尾' 'INFO' "剩余 $($left.Count) 项（跳过/未跟踪）——git status -- dotfiles 复查" }

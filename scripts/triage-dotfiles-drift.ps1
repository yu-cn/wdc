#Requires -Version 7
# triage-dotfiles-drift.ps1 — dotfiles 落点漂移分流（工单 17 立、ADR-0015 渲染拷贝模型平移）
# 渲染拷贝模型下机器侧工具直改的是落点渲染物（VSCode / gh auth setup-git 等），仓库模板不受写穿污染；
# 漂移 = 落点内容 ≠ 模板（判定单一来源 Test-DotfileInSync，install/verify 同面）。逐文件二选一（ADR-0003 判据）：
#   吸收(a) = 落点内容回写模板（Copy-Item），稍后显式 pathspec commit——「禁 git add -A」红线不变
#   还原(r) = 自模板重渲染（丢弃机器改动，不可逆——与旧 checkout 语义对齐）
# 落点缺失（absent）不在分流面：那是「未安装」，重跑 bootstrap 渲染即收敛。
# 用法：pwsh scripts/triage-dotfiles-drift.ps1            （交互分流）
#       pwsh scripts/triage-dotfiles-drift.ps1 -DryRun    （只看差异不动手）
[CmdletBinding()]
param([switch]$DryRun)
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
. (Join-Path $PSScriptRoot 'lib/common.ps1')
. (Join-Path $PSScriptRoot 'lib/dotfiles-map.ps1')

$repo = Split-Path $PSScriptRoot -Parent
$dotfilesRoot = Join-Path $repo 'dotfiles'

$items = @(Get-DotfilesMap | ForEach-Object {
    [pscustomobject]@{
        Name     = $_.Name
        Rel      = $_.Source
        Template = Join-Path $dotfilesRoot $_.Source
        Target   = $_.Target
        State    = Test-DotfileInSync -Source (Join-Path $dotfilesRoot $_.Source) -Target $_.Target
    }
})
foreach ($a in ($items | Where-Object State -eq 'absent')) {
    Write-Step $a.Name 'INFO' '落点缺失——未安装，重跑 bootstrap 渲染即收敛（分流面不处理）'
}
$drift = @($items | Where-Object State -eq 'drift')
if ($drift.Count -eq 0) {
    Write-Step 'dotfiles 漂移' 'OK' '全部落点与模板一致，无需分流'
    exit 0
}

Write-Phase "dotfiles 落点漂移（$($drift.Count) 项）"
$absorbList = [System.Collections.Generic.List[string]]::new()
$restored = 0
$skipped = 0
foreach ($d in $drift) {
    Write-Host "── $($d.Name)（模板 dotfiles/$($d.Rel) ↔ 落点 $($d.Target)）──"
    # -c core.autocrlf=false：--no-index 比对与行尾无关，静音 LF/CRLF 转换告警
    git -c core.autocrlf=false diff --no-index -- $d.Template $d.Target | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
    if ($DryRun) { continue }
    $answer = (Read-Host "dotfiles/$($d.Rel)  [a]吸收进模板  [r]还原(自模板重渲染,丢弃机器改动,不可逆)  [s]跳过(回车默认)").Trim().ToLower()
    switch ($answer) {
        'a' {
            Copy-Item -LiteralPath $d.Target -Destination $d.Template -Force
            $absorbList.Add("dotfiles/$($d.Rel)")
            Write-Step $d.Name 'CHANGED' '已回写模板（吸收）——稍后合并为一个 commit'
        }
        'r' {
            Copy-Item -LiteralPath $d.Template -Destination $d.Target -Force
            $restored++
            Write-Step $d.Name 'OK' '已自模板重渲染（还原——机器改动已丢弃）'
        }
        default { $skipped++; Write-Step $d.Name 'SKIP' '' }
    }
}

if ($DryRun) { exit 0 }

# 红线：吸收走显式路径 pathspec commit，绝不 git add -A
if ($absorbList.Count -gt 0) {
    $default = "chore(dotfiles): 吸收落点漂移偏好（$($absorbList -join ', ')）"
    $msg = (Read-Host 'commit 信息（回车用默认）').Trim()
    if (-not $msg) { $msg = $default }
    git -C $repo commit -m $msg -- @($absorbList.ToArray())
    Write-Step '吸收 commit' 'OK' $msg
}
if ($restored -gt 0) { Write-Step '还原' 'INFO' "$restored 个落点已自模板重渲染" }
if ($skipped -gt 0) { Write-Step '跳过' 'INFO' "$skipped 项留待下次——重跑本脚本继续分流" }

$left = 0
foreach ($d in $drift) {
    if ((Test-DotfileInSync -Source $d.Template -Target $d.Target) -eq 'drift') { $left++ }
}
if ($left -eq 0) { Write-Step '收尾' 'OK' "处置完成：吸收 $($absorbList.Count) / 还原 $restored / 跳过 $skipped" }
else { Write-Step '收尾' 'INFO' "剩余 $left 项漂移（跳过项）——重跑本脚本继续分流" }

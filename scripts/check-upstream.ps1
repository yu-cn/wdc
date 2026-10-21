#Requires -Version 7
# check-upstream.ps1 — 上游吸收机制的事实收集器（ADR-0001 补充：人工挑选，不做自动同步）
# 做什么：拉取 microsoft/WindowsDeveloperConfig 当前状态，与「吸收账本基线」及我们的声明对比，
#         输出「上游新增了什么 / 我们是否已有等价物」的差异报告。只陈述事实，不改任何配置。
# 注册表键维度已删（工单07：keys 从未参与差异输出、还把我们的键灌进上游集合污染基线；包维度即「值得考虑」提示的全部，YAGNI）
# 移植决策永远由环境主人做；吸收后在 docs/upstream-ledger.md 记一笔。
# 用法：
#   pwsh scripts/check-upstream.ps1                 # 对比基线出报告
#   pwsh scripts/check-upstream.ps1 -UpdateBaseline # 首次或确认无遗漏后，把当前上游状态固化为新基线
[CmdletBinding()]
param([switch]$UpdateBaseline)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/common.ps1')

$upstreamRepo = 'microsoft/WindowsDeveloperConfig'
$apiHeaders = @{ 'User-Agent' = 'wdc-check-upstream' }
$baselineFile = Join-Path $PSScriptRoot '..\docs\upstream-baseline.json'

# --- 1) 上游 HEAD ---
$head = Invoke-RestMethod -Headers $apiHeaders "https://api.github.com/repos/$upstreamRepo/commits/main"
$headSha = $head.sha
$headDate = $head.commit.committer.date
Write-Step '上游 HEAD' 'INFO' "$($headSha.Substring(0,10)) @ $headDate"

# --- 2) 拉取 src/ 下相关文件并提取 winget 包 ID ---
$tree = Invoke-RestMethod -Headers $apiHeaders "https://api.github.com/repos/$upstreamRepo/git/trees/main?recursive=1"
$interesting = @($tree.tree | Where-Object {
    $_.type -eq 'blob' -and $_.path -like 'src/*' -and (
        $_.path -like '*.ps1' -or $_.path -like '*.winget' -or $_.path -like '*.sh' -or
        $_.path -like '*packages*' -or $_.path -like '*registry*' -or $_.path -like '*devconfig*' -or $_.path -like '*wsl*'
    )
})
Write-Step '上游扫描范围' 'INFO' "$($interesting.Count) 个文件（src/ 下的脚本与配置）"

$idPattern = "[A-Za-z0-9][A-Za-z0-9_.-]*\.[A-Za-z0-9][A-Za-z0-9_.-]*/[A-Za-z0-9][A-Za-z0-9_.-]*"
$upstreamIds = [System.Collections.Generic.SortedSet[string]]::new()
foreach ($f in $interesting) {
    $raw = Invoke-RestMethod -Headers $apiHeaders "https://raw.githubusercontent.com/$upstreamRepo/main/$($f.path)"
    foreach ($m in [regex]::Matches($raw, $idPattern)) { $null = $upstreamIds.Add($m.Value) }
}

# --- 3) 我们的声明（configs/*.winget）---
$ours = [System.Collections.Generic.SortedSet[string]]::new()
foreach ($f in Get-ChildItem (Join-Path $PSScriptRoot '..\configs') -Filter '*.winget') {
    foreach ($m in [regex]::Matches((Get-Content $f.FullName -Raw), '(?m)^\s*id:\s*(\S+)')) { $null = $ours.Add($m.Groups[1].Value) }
}

# --- 4) 与基线对比 / 或写基线 ---
if ($UpdateBaseline -or -not (Test-Path $baselineFile)) {
    @{ head = $headSha; date = $headDate; packages = @($upstreamIds) } |
        ConvertTo-Json -Depth 3 | Set-Content $baselineFile -Encoding utf8
    Write-Step '基线' 'CHANGED' "已固化 $($upstreamIds.Count) 个包 到 docs/upstream-baseline.json"
    if ($UpdateBaseline) { exit 0 }
}

$baseline = Get-Content $baselineFile -Raw | ConvertFrom-Json
$baseIds = [System.Collections.Generic.SortedSet[string]]::new()
foreach ($i in $baseline.packages) { $null = $baseIds.Add($i) }

$newIds = @($upstreamIds | Where-Object { -not $baseIds.Contains($_) })
$goneIds = @($baseIds | Where-Object { -not $upstreamIds.Contains($_) })

Write-Phase '上游差异报告（基线 -> 现在）'
if ($newIds.Count -eq 0 -and $goneIds.Count -eq 0) {
    Write-Step '包差异' 'OK' '无变化（上游与基线一致）'
} else {
    foreach ($id in $newIds) {
        $have = $ours.Contains($id) ? '我们已有等价声明' : '我们尚无 —— 评估是否值得吸收'
        Write-Step "新增 $id" 'INFO' $have
    }
    foreach ($id in $goneIds) { Write-Step "移除 $id" 'INFO' '上游已删（若我们从未吸收则无影响）' }
}
Write-Phase '吸收提醒'
Write-Step '下一步' 'INFO' '若决定移植某项：改我们的 configs/dotfiles，然后在 docs/upstream-ledger.md 记一笔（日期+条目+上游链接），再跑本脚本 -UpdateBaseline 固化新基线'
exit 0

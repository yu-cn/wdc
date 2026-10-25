#Requires -Version 7
# check-upstream.ps1 — 上游吸收机制的事实收集器（ADR-0001 补充：人工挑选，不做自动同步）
# 做什么：拉取 microsoft/WindowsDeveloperConfig 当前状态，与「吸收账本基线」及我们的声明对比，
#         输出「上游新增了什么 / 我们是否已有等价物」的差异报告。只陈述事实，不改任何配置。
# 注册表键维度已删（工单07：keys 从未参与差异输出、还把我们的键灌进上游集合污染基线；包维度即「值得考虑」提示的全部，YAGNI）
# 包维度抓取已修（2026-10-25）：原全文件正则要求 X.Y/Z 带斜杠 token——winget 包 ID（Git.Git 等）无斜杠
# 一个都匹配不上，抓到的全是 DSC 资源类型与 URL 片段（旧基线 31 条零个真包 ID，账本 10-21「31 包」表述失实）。
# 现改为只抓包目录真源 steps/packages.ps1，按 `Id = '…'` 结构化字段提取。
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

# --- 2) 上游包目录（真源：steps/packages.ps1 的 Get-DevConfigPackageCatalog）---
$catalogRaw = Invoke-RestMethod -Headers $apiHeaders "https://raw.githubusercontent.com/$upstreamRepo/main/src/windows-dev-config/steps/packages.ps1"
$upstreamIds = [System.Collections.Generic.SortedSet[string]]::new()
foreach ($m in [regex]::Matches($catalogRaw, "(?m)^\s*Id\s*=\s*'([^']+)'")) { $null = $upstreamIds.Add($m.Groups[1].Value) }
# 目录里 Id = $vcRedistId 按机器架构取变量；两种变体都记入，比对时人工对齐
if ($catalogRaw -match 'Id\s*=\s*\$vcRedistId') {
    foreach ($id in @('Microsoft.VCRedist.2015+.x64', 'Microsoft.VCRedist.2015+.arm64')) { $null = $upstreamIds.Add($id) }
}
Write-Step '上游包目录' 'INFO' "steps/packages.ps1 Get-DevConfigPackageCatalog：$($upstreamIds.Count) 个包"

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

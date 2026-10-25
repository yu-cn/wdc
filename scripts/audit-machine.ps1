#Requires -Version 7
# audit-machine.ps1 — winget 清单准入对账（只读，exit 恒 0；这是对账报告不是断言——核销语义在 verify）
# 两个方向（对齐 LDC audit-machine.sh，LDC v0.7.0；定位讨论「WDC 是否在干包管理」的对账面）：
#   ① 已声明未装：configs/*.winget 声明的包 Id − 已装 → 收敛待办（winget configure 应用可补）
#   ② 自装未声明：已装全量 − 声明 Id 并集 → 清单准入候选。Windows 侧系统组件/框架噪声大——
#      首版降级为 INFO 计数 + 头部样例（-SampleCount），逐项判读交清单准入流程（ADR-0003 判据：
#      每台机器都该有的吸收进清单，仅本机要的属机器自留）
# 已装面经 `winget export`（JSON，winget 视角的 ARP 全量）——比解析 winget list 表格可靠
#（列布局随 locale 变、NUL 泄漏见坑③族）。
[CmdletBinding()]
param([int]$SampleCount = 10)
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
. (Join-Path $PSScriptRoot 'lib/common.ps1')

$repo = Split-Path $PSScriptRoot -Parent

# 声明面：configs/*.winget 中 Microsoft.WinGet/Package 单元的 id（附所属域）
# registry/字体/扩展等非包单元不进对账面（扩展另有 verify 断言，工单34 族同思路）
$declared = @{}
foreach ($f in (Get-ChildItem (Join-Path $repo 'configs') -Filter '*.winget')) {
    $domain = $f.BaseName
    foreach ($m in (Select-String -Path $f.FullName -Pattern '^\s*id:\s*(\S+)')) {
        $declared[$m.Matches[0].Groups[1].Value] = $domain
    }
}
Write-Phase "audit · 声明面（$($declared.Count) 个包 Id）"

# 已装面：winget export JSON
$exportFile = Join-Path ([System.IO.Path]::GetTempPath()) "wdc-audit-$PID.json"
winget export -o $exportFile --accept-source-agreements --disable-interactivity 2>&1 | Out-Null
$installedIds = @()
try {
    $j = Get-Content $exportFile -Raw | ConvertFrom-Json
    $installedIds = @($j.Sources.Packages.PackageIdentifier | Where-Object { $_ })
} finally { Remove-Item $exportFile -Force -ErrorAction SilentlyContinue }
if ($installedIds.Count -eq 0) { Write-Step '已装面' 'FAIL' 'winget export 空输出——对账无据'; exit 0 }

Write-Phase 'audit · 已声明未装'
$missing = @($declared.Keys | Where-Object { $installedIds -notcontains $_ })
if ($missing.Count -eq 0) { Write-Step '已声明未装' 'OK' '零项——声明面全部核销' }
else {
    Write-Step '已声明未装' 'INFO' "$($missing.Count) 项收敛待办——winget configure 应用可补："
    foreach ($id in $missing) { Write-Host ("  {0}（{1}）" -f $id, $declared[$id]) }
}

Write-Phase 'audit · 自装未声明'
$candidates = @($installedIds | Where-Object { -not $declared.ContainsKey($_) } | Sort-Object)
if ($candidates.Count -eq 0) { Write-Step '自装未声明' 'OK' '零项——机器自装面全部被声明面覆盖' }
else {
    Write-Step '自装未声明' 'INFO' "$($candidates.Count) 项准入候选——吸收进清单或确认机器自留（ADR-0003），样例头部 $SampleCount 项："
    $candidates | Select-Object -First $SampleCount | ForEach-Object { Write-Host "  $_" }
}

exit 0

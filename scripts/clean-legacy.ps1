#Requires -Version 7
# clean-legacy.ps1 — 版本残留清扫（exit-mechanism 工单02；wdc clean-legacy 的执行体）
# 按签名识别历史残留物，不按版本号识别——版本→残留映射不可靠（一个残留跨多版本存在），
# 签名幂等、扫不到即 OK、新机器零误伤。默认只报告（对账口径，恒 exit 0，对齐 audit）；
# -Fix 才清理且只清 SafeToFix 项——uv 遮蔽/符号链接/Cascadia/状态目录陈旧物/LDC 孤儿
# 永远只报告（处置各有正道：重跑 bootstrap 自愈 / 主人 triage / 手动删 / LDC 侧定夺）。
[CmdletBinding()]
param([switch]$Fix)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\common.ps1')
. (Join-Path $PSScriptRoot 'lib\dotfiles-map.ps1')

$script:found = 0
function Add-Finding {
    param([string]$Name, [bool]$SafeToFix, [string]$Note)
    $script:found++
    if ($SafeToFix) { Write-Step $Name 'CHANGED' $Note } else { Write-Step $Name 'INFO' $Note }
}

# ---------------------------------------------------------------------------
# 1/8 · pre-ADR-0015 符号链接落点残形（报告：重跑 bootstrap/install-dotfiles 自愈——
#       渲染时「符号链接残形直接替换不备份」，处置归安装面，本命令不抢）
# ---------------------------------------------------------------------------
Write-Phase '残留清扫 1/8 - 符号链接落点（pre-ADR-0015 残形）'
$base = $script:found
foreach ($m in Get-DotfilesMap) {
    if (Test-Path -LiteralPath $m.Target) {
        $item = Get-Item -LiteralPath $m.Target -Force
        if ($item.LinkType) {
            Add-Finding "符号链接 $($m.Name)" $false "$($m.Target)（LinkType=$($item.LinkType)）——重跑 bootstrap/install-dotfiles 自愈"
        }
    }
}
if ($script:found -eq $base) { Write-Step '符号链接落点' 'OK' '无残形（全部为渲染拷贝实体文件）' }

# ---------------------------------------------------------------------------
# 2/8 · WT fragments 四路径（上游注入物 + 本仓退役机制；与 remove-leftovers 1/3 同清单）
# ---------------------------------------------------------------------------
Write-Phase '残留清扫 2/8 - WT fragments'
$base = $script:found
$fragRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments'
$wtLocal = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'
foreach ($p in @(
    (Join-Path $fragRoot 'ComfortShell'), (Join-Path $fragRoot 'DevConfig'),
    (Join-Path $fragRoot 'WDC'), (Join-Path $wtLocal 'fragments\wdc-wsl.json')
)) {
    if (Test-Path $p) {
        if ($Fix) { Remove-Item -Path $p -Recurse -Force; Add-Finding "fragment $p" $true '已删除' }
        else { Add-Finding "fragment $p" $true '存在（-Fix 删除）' }
    }
}
if ($script:found -eq $base) { Write-Step 'WT fragments' 'OK' '无' }

# ---------------------------------------------------------------------------
# 3/8 · vp 退役残留（三布局目录 + 用户 PATH 注入；与 remove-leftovers 2/3 同清单）
# ---------------------------------------------------------------------------
Write-Phase '残留清扫 3/8 - vp 退役残留'
$base = $script:found
foreach ($d in @(
    (Join-Path $env:USERPROFILE '.vite-plus'),
    (Join-Path $env:LOCALAPPDATA 'vite-plus'),
    (Join-Path $env:APPDATA 'vite-plus')
)) {
    if (Test-Path $d) {
        if ($Fix) {
            try { Remove-Item -Path $d -Recurse -Force -ErrorAction Stop; Add-Finding "vp 目录 $d" $true '已删除' }
            catch { Add-Finding "vp 目录 $d" $false "占用未删（重启经 vp 运行的应用后重跑）：$($_.Exception.Message)" }
        } else { Add-Finding "vp 目录 $d" $true '存在（-Fix 删除）' }
    }
}
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -like '*vite-plus*') {
    if ($Fix) {
        $kept = @(($userPath -split ';') | Where-Object { $_ -ne '' -and $_ -notlike '*vite-plus*' })
        [Environment]::SetEnvironmentVariable('Path', ($kept -join ';'), 'User')
        Add-Finding '用户 PATH vite-plus 注入' $true '已清除'
    } else { Add-Finding '用户 PATH vite-plus 注入' $true '存在（-Fix 清除）' }
}
if ($script:found -eq $base) { Write-Step 'vp 退役残留' 'OK' '无' }

# ---------------------------------------------------------------------------
# 4/8 · Cascadia 字体 per-user 安装残形（报告：winget 包已从源除名，处置见
#       .scratch/cascadia-font-source/ 档案——只扫 %LOCALAPPDATA% 用户字体位，
#       C:\Windows\Fonts 的 OS 内置 Cascadia 不属残留）
# ---------------------------------------------------------------------------
Write-Phase '残留清扫 4/8 - Cascadia per-user 字体'
$userFonts = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$cascadia = @(Get-ChildItem -Path $userFonts -Filter 'Cascadia*' -File -ErrorAction SilentlyContinue)
if ($cascadia.Count -gt 0) {
    Add-Finding 'Cascadia per-user 字体' $false "$($cascadia.Count) 个文件——手动处置：设置→字体卸载，或删文件+清 HKCU 字体注册值"
} else { Write-Step 'Cascadia per-user 字体' 'OK' '无' }

# ---------------------------------------------------------------------------
# 5/8 · uv 双装遮蔽（报告：~/.local/bin 副本遮蔽 winget 版——去留归主人 triage）
# ---------------------------------------------------------------------------
Write-Phase '残留清扫 5/8 - uv 双装遮蔽'
$uvLocal = Join-Path $HOME '.local\bin\uv.exe'
if (Test-Path $uvLocal) {
    Add-Finding 'uv 双装' $false "$uvLocal 在位——若 winget 版（声明）也在装则前者遮蔽 PATH，去留 triage（历史实录：.local/bin 0.13.0 遮蔽 winget 0.13.7）"
} else { Write-Step 'uv 双装' 'OK' '无 .local/bin 副本' }

# ---------------------------------------------------------------------------
# 6/8 · 死计划任务（WdcBootstrapResume 一次性续跑 / WDC-GitUpgrade-* 一次性升级通道——
#       按设计自清，残留即死任务）。CSV 表头随系统语言本地化（中文系统无 TaskName 属性，
#       坑1「输出随语言变」同族）——按首列位置取值（schtasks CSV 列序稳定，首列即任务名）
# ---------------------------------------------------------------------------
Write-Phase '残留清扫 6/8 - 死计划任务'
$base = $script:found
$tasks = @((& schtasks.exe /Query /FO CSV 2>$null | ConvertFrom-Csv) |
    ForEach-Object { ($_.PSObject.Properties | Select-Object -First 1).Value } |
    Where-Object { $_ -match '^\\?(WdcBootstrapResume|WDC-GitUpgrade-)' })
foreach ($t in $tasks) {
    if ($Fix) {
        $null = & schtasks.exe /Delete /TN $t /F 2>$null
        if ($LASTEXITCODE -eq 0) { Add-Finding "计划任务 $t" $true '已删除' }
        else { Add-Finding "计划任务 $t" $false '删除失败（可能需管理员——提权终端重跑）' }
    } else { Add-Finding "计划任务 $t" $true '存在（-Fix 删除）' }
}
if ($script:found -eq $base) { Write-Step '死计划任务' 'OK' '无' }

# ---------------------------------------------------------------------------
# 7/8 · %LOCALAPPDATA%\wdc 状态目录陈旧物（报告：已知集合外的文件——核对内容后再手删，
#       坑18 教训：盲删不如看一眼）
# ---------------------------------------------------------------------------
Write-Phase '残留清扫 7/8 - 状态目录陈旧物'
$stateDir = Join-Path $env:LOCALAPPDATA 'wdc'
$known = @('converged.json', 'rendered.sha256', 'ubuntu.ico', 'cache', 'pre-install')
if (Test-Path $stateDir) {
    $stale = @(Get-ChildItem -Path $stateDir -Force | Where-Object { $_.Name -notin $known })
    if ($stale.Count -gt 0) {
        Add-Finding '状态目录陈旧物' $false "$($stale.Name -join ' / ')——核对内容无取证价值后手删（永远只报告）"
    } else { Write-Step '状态目录' 'OK' "全部为已知物（$($known -join ' / ')）" }
} else { Write-Step '状态目录' 'OK' '不存在（未 bootstrap 过）' }

# ---------------------------------------------------------------------------
# 8/8 · LDC 孤儿 backup（WSL 侧，报告：~/dev/ldc/backup/orphan-*——处置归 LDC 侧定夺）
# ---------------------------------------------------------------------------
Write-Phase '残留清扫 8/8 - LDC 孤儿 backup'
if (Test-WslEnabled) {
    $r = Invoke-WslBounded -ArgumentList @('-e', 'bash', '-lc', 'ls -d ~/dev/ldc/backup/orphan-* 2>/dev/null') -TimeoutSeconds 15
    $orphans = @()
    if ($null -ne $r -and $r.Exit -eq 0) { $orphans = @($r.Lines | Where-Object { $_ -match 'orphan-' }) }
    if ($orphans.Count -gt 0) {
        Add-Finding 'LDC 孤儿 backup' $false (($orphans -join '；') + '——处置归 LDC 侧')
    } else { Write-Step 'LDC 孤儿 backup' 'OK' '无' }
} else { Write-Step 'LDC 孤儿 backup' 'SKIP' 'WSL 未启用' }

Write-Phase '残留清扫汇总'
$mode = if ($Fix) { '（-Fix：SafeToFix 项已处置）' } else { '（报告模式——加 -Fix 清理 SafeToFix 项）' }
Write-Step '残留清扫' 'OK' "发现 $found 项$mode；exit 0（对账报告不是断言）"
exit 0

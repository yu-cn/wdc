#Requires -Version 7
# wdc.ps1 — wdc 命令的唯一实现（工单 20：使用体验优化；2026-10-23 体验修订见工单20 补记）
# pwsh profile 与 Git Bash bashrc 只做薄包装转发到这里，逻辑单一来源，防两处漂移。
# 输出复用 lib/common.ps1 的 Write-Phase/Write-Step，与 bootstrap/verify 同一观感。
# 体验约定（业界对齐：jj 裸命令=只读状态、git/gh 裸命令不跑长操作）：
#   裸命令不触发同步——长操作/改状态一律显式子命令；裸 wdc 给只读快照并提示下一步。
# 用法：
#   wdc | wdc status    只读快照（秒级）：与 origin/main 差距 / dotfiles 写穿漂移 / 身份与 WSL 首跑状态 / 最近 bootstrap 结果
#   wdc sync            全量同步：fetch → 落后则 pull（--ff-only）→ bootstrap → verify 全量（会请求一次 UAC）
#   wdc verify [-Full]  机器断言；默认 -Quick 秒级，-Full 含三域漂移（约 3 分钟）
#   wdc triage          dotfiles 写穿漂移分流（工单 17 工具入口，交互式）
#   wdc log [-Lines N]  最近一次 bootstrap 日志尾部（默认 40 行，连带提权子回合日志）
#   wdc help [命令]     总览或单命令详解；-h/--help 同义
#   wdc version         版本（git describe）；-v/--version 同义
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = 'status',
    [Parameter(Position = 1)]
    [string]$Topic,
    [Alias('h')]
    [switch]$Help,
    [Alias('v')]
    [switch]$Version,
    [switch]$Full,
    [int]$Lines = 40
)
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
. (Join-Path $PSScriptRoot 'lib/common.ps1')

$wdcCommands = 'sync', 'status', 'verify', 'triage', 'log', 'help', 'version'

# --- 子命令校验在仓库定位之前（工单29）：help/version 与友好报错不依赖 ~/.wdc 指针 ---
$script:SelfRepo = Split-Path $PSScriptRoot -Parent

function Get-WdcVersion {
    $v = & git -C $script:SelfRepo describe --tags --always --dirty 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $v) { return 'v0.0.0-unknown' }
    return ($v -join '')
}

function Get-WdcCommandSuggestion {
    # 打错子命令时的「你是不是想输…」：先看唯一前缀命中，再看编辑距离 ≤2
    param([string]$Input_)
    $hit = @($wdcCommands | Where-Object { $_.StartsWith($Input_, [StringComparison]::OrdinalIgnoreCase) })
    if ($hit.Count -eq 1) { return $hit[0] }
    $best = $null; $bestD = 99
    foreach ($k in $wdcCommands) {
        $a = $Input_.ToLowerInvariant(); $b = $k
        if ([Math]::Abs($a.Length - $b.Length) -gt 2) { continue }
        $d = [int[,]]::new($a.Length + 1, $b.Length + 1)
        for ($i = 0; $i -le $a.Length; $i++) { $d[$i, 0] = $i }
        for ($j = 0; $j -le $b.Length; $j++) { $d[0, $j] = $j }
        for ($i = 1; $i -le $a.Length; $i++) {
            $pi = $i - 1
            for ($j = 1; $j -le $b.Length; $j++) {
                $pj = $j - 1
                $cost = if ($a[$pi] -eq $b[$pj]) { 0 } else { 1 }
                # 索引括号内的算术必须预计算：$d[$i - 1, $j] 会被解析成 $i - (1, $j)——PowerShell 逗号优先级坑
                $m1 = [Math]::Min(($d[$pi, $j]) + 1, ($d[$i, $pj]) + 1)
                $d[$i, $j] = [Math]::Min($m1, ($d[$pi, $pj]) + $cost)
            }
        }
        $dist = $d[$a.Length, $b.Length]
        if ($dist -le 2 -and $dist -lt $bestD) { $best = $k; $bestD = $dist }
    }
    return $best
}

$helpOverview = @'
wdc — WDC 开发环境一键工具（裸命令只读快照；仓库在 ~/.wdc 指向的路径）

  wdc | wdc status     只读快照（秒级）：远端差距 / dotfiles 漂移 / 身份与 WSL / 最近 bootstrap
  wdc sync             全量同步：fetch → pull → bootstrap → verify 全量（会请求一次 UAC）
  wdc verify [-Full]   机器断言（默认 -Quick；-Full 含三域漂移约 3 分钟）
  wdc triage           dotfiles 写穿漂移分流（逐文件 吸收/还原，交互式）
  wdc log [-Lines N]   最近一次 bootstrap 日志尾部（默认 40 行）
  wdc help [命令]      本总览或单命令详解（-h/--help 同义）
  wdc version          版本（-v/--version 同义）
'@

$helpDetail = @{
    'status' = @'
wdc status — 只读快照（秒级，不改任何状态）
  远端差距（fetch 后与 origin/main 的领先/落后）、dotfiles 写穿漂移（>0 提示 wdc triage）、
  身份文件是否生效（占位未填则 git 拒绝提交护栏仍在）、WSL/Ubuntu 首跑状态、
  距上次上游检查天数（>30 天提示补课）、最近一次 bootstrap 判定行。
  裸 wdc 等价于 wdc status。
'@
    'sync' = @'
wdc sync — 全量同步（日常一键收敛；会请求一次 UAC）
  顺序：fetch → 落后则 pull --ff-only（本地领先/分叉一律中止交人工）→
  bootstrap 七阶段（提权子回合一回合跑完，日志落 logs/elevated-*.log）→ verify 全量。
  任一段失败即非零退出，并自动贴出 bootstrap 与提权日志尾部。
'@
    'verify' = @'
wdc verify [-Full] — 机器断言
  六组断言：dotfiles 符号链接 / 身份与注册表 / 移除清单核销 / 语言栈 / WSL 侧 / 三域漂移。
  默认 -Quick（秒级）；-Full 加三域 winget configure test 漂移（约 3 分钟）。
'@
    'triage' = @'
wdc triage — dotfiles 写穿漂移分流（交互式）
  WT/VSCode 等 UI 会把设置写穿符号链接进仓库文件；本命令逐文件给出「吸收进模板 / 还原为机器噪声」
  的处置入口（ADR-0003 判据）。verify 的「dotfiles 与 HEAD 一致」断言 FAIL 时也会指向这里。
'@
    'log' = @'
wdc log [-Lines N] — 最近一次 bootstrap 日志尾部（默认 40 行）
  正常汇总在 logs/bootstrap-*.log，提权子回合七阶段明细在 logs/elevated-*.log——两条一起展示。
'@
}

function Show-WdcHelp([string]$topic) {
    if ($topic -and $helpDetail.ContainsKey($topic)) {
        Write-Host $helpDetail[$topic]
    } elseif ($topic) {
        Write-Host "wdc: 「$topic」没有单独的帮助（可用：sync / status / verify / triage / log）" -ForegroundColor Yellow
        Write-Host $helpOverview
    } else {
        Write-Host $helpOverview
    }
}

if ($Version -or $Command -in 'version', '-v', '--version') {
    Write-Host ("wdc " + (Get-WdcVersion))
    exit 0
}
if ($Help -or $Command -in 'help', '-h', '--help') {
    Show-WdcHelp $Topic
    exit 0
}
if ($Command -notin $wdcCommands) {
    $sug = Get-WdcCommandSuggestion $Command
    Write-Host "wdc: 未知子命令「$Command」（可用：sync / status / verify / triage / log / help / version）" -ForegroundColor Yellow
    if ($sug) { Write-Host "wdc: 你是想输「$sug」吗？" -ForegroundColor Yellow }
    Write-Host $helpOverview
    exit 1
}

# --- 仓库定位：~/.wdc 指针（bootstrap 的 dotfiles 阶段写入）---
$repo = (Get-Content (Join-Path $HOME '.wdc') -ErrorAction SilentlyContinue | Select-Object -First 1)
if (-not $repo -or -not (Test-Path (Join-Path $repo 'bootstrap.ps1'))) {
    Write-Host 'wdc: 未配置仓库路径——先在仓库跑一次 bootstrap.ps1（会自动写 ~/.wdc 指针）' -ForegroundColor Yellow
    exit 1
}
$bare = -not $PSBoundParameters.ContainsKey('Command')

function Get-LastBootstrapLog {
    Get-ChildItem (Join-Path $repo 'logs') -Filter 'bootstrap-*.log' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

function Get-LastElevatedLog {
    # 提权子回合并行日志（工单19）：bootstrap 汇总在 bootstrap-*.log，子回合明细在 elevated-*.log
    Get-ChildItem (Join-Path $repo 'logs') -Filter 'elevated-*.log' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

function Get-AheadBehind {
    # 返回 @(领先, 落后)——基于 HEAD 与 origin/main
    $c = (git -C $repo rev-list --left-right --count 'HEAD...origin/main') -join ''
    if ($LASTEXITCODE -ne 0 -or -not $c) { return @(0, 0) }
    ($c -split '\s+') | ForEach-Object { [int]$_ }
}

switch ($Command) {
    'status' {
        Write-Phase 'wdc status · 只读快照'
        git -C $repo fetch --quiet
        $ab = Get-AheadBehind
        if ($ab[0] -eq 0 -and $ab[1] -eq 0) { Write-Step '仓库' 'OK' '与 origin/main 一致' }
        else { Write-Step '仓库' 'INFO' "领先 $($ab[0]) / 落后 $($ab[1])——wdc sync 同步之" }
        $drift = @(git -C $repo status --porcelain -- dotfiles)
        if ($drift.Count -eq 0) { Write-Step 'dotfiles 漂移' 'OK' '与 HEAD 一致' }
        else { Write-Step 'dotfiles 漂移' 'FAIL' "$($drift.Count) 项写穿——wdc triage 分流" }
        # 首跑两件手工事的状态可见（工单29）：身份占位未填则「拒提交」护栏仍在；WSL 未启用/Ubuntu 未装则收敛未完成
        if (Test-GitIdentityEffective) { Write-Step '身份文件' 'OK' 'name/email 经 include 生效' }
        else { Write-Step '身份文件' 'FAIL' '未填写——编辑 ~/.gitidentity（占位已生成）；不填则 git 拒绝提交' }
        if (Test-IsElevated) { Write-Step 'WSL' 'SKIP' '提权上下文保守跳过探测（坑①）——普通终端再跑 wdc status' }
        elseif (-not (Test-WslEnabled)) { Write-Step 'WSL' 'FAIL' '未启用——管理员终端 wsl --install 并重启，然后重跑 bootstrap' }
        elseif ((Get-WslDistros) -notcontains 'Ubuntu') { Write-Step 'WSL' 'FAIL' 'Ubuntu 未装——管理员终端 wsl --install -d Ubuntu，然后重跑 bootstrap' }
        else { Write-Step 'WSL' 'OK' 'Ubuntu 已就位' }
        # 上游 watch 提醒（工单20）：距上次 check-upstream 超过 30 天提示补课（工单18 定了不做定时巡检，只提醒）
        $ledger = Join-Path $repo 'docs\upstream-ledger.md'
        if (Test-Path $ledger) {
            $last = Select-String -Path $ledger -Pattern '\| (\d{4}-\d{2}-\d{2}) \|' |
                ForEach-Object { $_.Matches[0].Groups[1].Value } | Sort-Object -Descending | Select-Object -First 1
            if ($last) {
                $days = [int]((Get-Date) - [datetime]$last).TotalDays
                if ($days -gt 30) { Write-Step '上游检查' 'INFO' "距上次 $days 天——跑 scripts/check-upstream.ps1 并记账 docs/upstream-ledger.md" }
                else { Write-Step '上游检查' 'OK' "距上次 $days 天" }
            }
        }
        $log = Get-LastBootstrapLog
        if ($log) {
            # 正常收尾的日志有 "[OK|FAIL] bootstrap" 汇总行；UAC 被取消等早退日志没有——兜底显示最后一条判定行
            $m = Select-String -Path $log.FullName -Pattern '^\[(OK|FAIL)\] ' | Select-Object -Last 1
            $verdict = if ($m) { $m.Line } else { '（无判定行）' }
            Write-Step '最近 bootstrap' 'INFO' "$($log.Name) → $verdict"
        } else { Write-Step '最近 bootstrap' 'INFO' 'logs/ 尚无日志' }
        if ($bare) {
            Write-Step '提示' 'INFO' '裸 wdc 即本快照（只读）。同步收敛：wdc sync；全部命令：wdc help'
        }
    }

    'verify' {
        $vArgs = @(); if (-not $Full) { $vArgs += '-Quick' }
        & pwsh -NoProfile -File (Join-Path $repo 'scripts\verify-machine.ps1') @vArgs
        exit $LASTEXITCODE
    }

    'triage' {
        & pwsh -NoProfile -File (Join-Path $repo 'scripts\triage-dotfiles-drift.ps1')
        exit $LASTEXITCODE
    }

    'log' {
        $log = Get-LastBootstrapLog
        if (-not $log) { Write-Step '日志' 'INFO' 'logs/ 尚无 bootstrap 日志'; exit 0 }
        Write-Step '日志' 'INFO' $log.FullName
        Get-Content $log.FullName -Tail $Lines
        $elog = Get-LastElevatedLog
        if ($elog) {
            Write-Host ''
            Write-Step '提权子回合日志' 'INFO' $elog.FullName
            Get-Content $elog.FullName -Tail $Lines
        }
    }

    'sync' {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        Write-Phase 'wdc sync · 仓库'
        git -C $repo fetch --quiet
        $ab = Get-AheadBehind
        if ($ab[0] -gt 0 -and $ab[1] -gt 0) {
            Write-Step '仓库' 'FAIL' "本地与远端分叉（领先 $($ab[0]) / 落后 $($ab[1])）——人工处理后再同步"; exit 1
        }
        if ($ab[0] -gt 0) {
            Write-Step '仓库' 'FAIL' "本地领先 $($ab[0]) 个提交未推送——先 push 再 wdc"; exit 1
        }
        if ($ab[1] -gt 0) {
            git -C $repo pull --ff-only
            if ($LASTEXITCODE -ne 0) { Write-Step '仓库' 'FAIL' 'pull --ff-only 失败，中止'; exit 1 }
            Write-Step '仓库' 'CHANGED' "已拉取 $($ab[1]) 个提交"
        } else { Write-Step '仓库' 'OK' '已与 origin/main 一致' }

        Write-Step '提示' 'INFO' 'bootstrap 即将开始，会请求一次 UAC 提权'
        Write-Phase 'wdc sync · bootstrap'
        & pwsh -NoProfile -File (Join-Path $repo 'bootstrap.ps1')
        if ($LASTEXITCODE -ne 0) {
            Write-Step 'bootstrap' 'FAIL' '未全绿——最近日志尾部（完整见 logs/）'
            $log = Get-LastBootstrapLog
            if ($log) { Get-Content $log.FullName -Tail 30 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray } }
            $elog = Get-LastElevatedLog
            if ($elog) {
                Write-Host ''
                Write-Step '提权子回合尾部' 'INFO' $elog.FullName
                Get-Content $elog.FullName -Tail 20 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
            }
            exit 1
        }

        Write-Phase 'wdc sync · verify（全量）'
        & pwsh -NoProfile -File (Join-Path $repo 'scripts\verify-machine.ps1')
        $code = $LASTEXITCODE
        Write-Phase 'wdc sync · 汇总'
        if ($code -eq 0) { Write-Step 'wdc' 'OK' "同步完成，机器与声明一致（$([int]$sw.Elapsed.TotalSeconds)s）" }
        else { Write-Step 'wdc' 'FAIL' 'verify 未全绿——排障后 wdc verify 复查' }
        exit $code
    }
}

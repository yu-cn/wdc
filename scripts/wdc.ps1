#Requires -Version 7
# wdc.ps1 — wdc 命令的唯一实现（工单 20：使用体验优化）
# pwsh profile 与 Git Bash bashrc 只做薄包装转发到这里，逻辑单一来源，防两处漂移。
# 输出复用 lib/common.ps1 的 Write-Phase/Write-Step，与 bootstrap/verify 同一观感。
# 用法：
#   wdc | wdc sync        全量同步：fetch → 落后则 pull（--ff-only）→ bootstrap → verify 全量
#   wdc status            只读快照（秒级）：与 origin/main 差距 / dotfiles 写穿漂移 / 身份与 WSL 首跑状态 / 最近一次 bootstrap 结果
#   wdc verify [-Full]    机器断言；默认 -Quick 秒级，-Full 含三域漂移（约 3 分钟）
#   wdc triage            dotfiles 写穿漂移分流（工单 17 工具入口，交互式）
#   wdc log [-Lines N]    最近一次 bootstrap 日志尾部（默认 40 行）
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = 'sync',
    [switch]$Full,
    [int]$Lines = 40
)
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
. (Join-Path $PSScriptRoot 'lib/common.ps1')

# --- 子命令校验在仓库定位之前（工单29）：help 与友好报错不依赖 ~/.wdc 指针 ---
$helpText = @'
wdc — WDC 开发环境一键工具（仓库在 ~/.wdc 指向的路径）

  wdc | wdc sync        全量同步：fetch → 落后则 pull → bootstrap → verify 全量（会请求一次 UAC）
  wdc status            只读快照：远端差距 / dotfiles 写穿漂移 / 身份与 WSL 首跑状态 / 最近 bootstrap 结果（秒级）
  wdc verify [-Full]    机器断言（默认 -Quick；-Full 含三域漂移约 3 分钟）
  wdc triage            dotfiles 写穿漂移分流（逐文件 吸收/还原，交互式）
  wdc log [-Lines N]    最近一次 bootstrap 日志尾部（默认 40 行）
'@
if ($Command -notin 'sync', 'status', 'verify', 'triage', 'log', 'help') {
    Write-Host "wdc: 未知子命令「$Command」（可用：sync / status / verify / triage / log / help）" -ForegroundColor Yellow
    Write-Host $helpText
    exit 1
}

# --- 仓库定位：~/.wdc 指针（bootstrap 的 dotfiles 阶段写入）---
$repo = (Get-Content (Join-Path $HOME '.wdc') -ErrorAction SilentlyContinue | Select-Object -First 1)
if (-not $repo -or -not (Test-Path (Join-Path $repo 'bootstrap.ps1'))) {
    Write-Host 'wdc: 未配置仓库路径——先在仓库跑一次 bootstrap.ps1（会自动写 ~/.wdc 指针）' -ForegroundColor Yellow
    exit 1
}

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
    'help' {
        Write-Host $helpText
    }

    'status' {
        Write-Phase 'wdc status · 只读快照'
        git -C $repo fetch --quiet
        $ab = Get-AheadBehind
        if ($ab[0] -eq 0 -and $ab[1] -eq 0) { Write-Step '仓库' 'OK' '与 origin/main 一致' }
        else { Write-Step '仓库' 'INFO' "领先 $($ab[0]) / 落后 $($ab[1])（wdc 同步之）" }
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

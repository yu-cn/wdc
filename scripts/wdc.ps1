#Requires -Version 7
# wdc.ps1 — wdc 命令的唯一实现（工单 20：使用体验优化；2026-10-23 体验修订见工单20 补记）
# pwsh profile 与 Git Bash bashrc 只做薄包装转发到这里，逻辑单一来源，防两处漂移。
# 输出复用 lib/common.ps1 的 Write-Phase/Write-Step，与 bootstrap/verify 同一观感。
# 体验约定（业界对齐：jj 裸命令=只读状态、git/gh 裸命令不跑长操作）：
#   裸命令不触发同步——长操作/改状态一律显式子命令；裸 wdc 给只读快照并提示下一步。
# 用法：
#   wdc | wdc status    只读快照（秒级）：与 origin/main 差距 / dotfiles 落点漂移 / 身份与 WSL 首跑状态 / 最近 bootstrap 结果
#                       -Json 出单行机器可读出口（包装层把 --json 归一为 -Json）
#   wdc plan            干跑预演（只读零变更）：重跑 wdc sync 会做什么——UAC/重跑前先看一眼
#   wdc sync [-Full]    同步收敛：fetch → 落后则 pull（--ff-only）→ bootstrap → verify -Quick 收尾（会请求一次 UAC）；
#                       已收敛且声明未变走快速路径跳过 bootstrap（秒级）；-Full 强制全量
#   wdc verify [-Full]  机器断言；默认 -Quick 秒级，-Full 含三域漂移（约 3 分钟）
#   wdc triage          dotfiles 落点漂移分流（工单 17 工具入口，交互式；ADR-0015 口径）
#   wdc log [-Lines N]  最近一次 bootstrap 日志尾部（默认 40 行，连带提权子回合日志）
#   wdc help [命令]     总览或单命令详解；-h/--help 同义；子命令后接 -h 出该命令详解
#   wdc version         版本（git describe）；-v/--version 同义
# 退出码：0 成功 · 1 失败 · 3 收敛锁占用（sync）
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
    [switch]$Json,
    [int]$Lines = 40
)
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
. (Join-Path $PSScriptRoot 'lib/common.ps1')
. (Join-Path $PSScriptRoot 'lib/dotfiles-map.ps1')

$wdcCommands = 'status', 'sync', 'verify', 'plan', 'triage', 'audit', 'upgrade-git', 'log', 'help', 'version'
# 报错/提示文案的命令列表一律由 $wdcCommands 动态拼（cli-ux 工单04：加命令只改这一处）
$wdcCommandsDetail = @($wdcCommands | Where-Object { $_ -notin 'help', 'version' })

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

function Invoke-WdcFetchBounded {
    # 有界、禁交互的 git fetch（cli-ux 工单01，对齐 ldc 的 timeout+GIT_TERMINAL_PROMPT 口径）：
    # 进程级硬超时——pwsh 无 timeout(1)，Wait-WdcProcess 是轮询壳，这里直接 WaitForExit(ms)；
    # 子进程环境注入 GIT_TERMINAL_PROMPT=0 + GCM_INTERACTIVE=never：凭据过期时 GCM 弹 GUI 等待，
    # 在 agent 会话里即无提示挂死。fetch 只读可安全 kill；Kill($true) 连 gcm 子进程一起收
    param(
        [Parameter(Mandatory)][string]$Repo,
        [Parameter(Mandatory)][ValidateRange(1, 600)][int]$TimeoutSec
    )
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'git'
    $psi.Arguments = "-C `"$Repo`" fetch --quiet"
    $psi.UseShellExecute = $false
    $psi.EnvironmentVariables['GIT_TERMINAL_PROMPT'] = '0'
    $psi.EnvironmentVariables['GCM_INTERACTIVE'] = 'never'
    $p = [System.Diagnostics.Process]::Start($psi)
    if (-not $p.WaitForExit($TimeoutSec * 1000)) {
        try { $p.Kill($true) } catch { try { $p.Kill() } catch { } }
        return $false
    }
    return ($p.ExitCode -eq 0)
}

$helpOverview = @'
wdc — WDC 开发环境一键工具（裸命令只读快照；仓库在 ~/.wdc 指向的路径）

  wdc | wdc status     只读快照（秒级）：远端差距 / dotfiles 漂移 / 身份与 WSL / 最近 bootstrap；
                       -Json 出单行机器可读出口（包装层把 --json 归一为 -Json）
  wdc plan             干跑预演（只读零变更）：重跑 wdc sync 会做什么——UAC/重跑前先看一眼
  wdc sync [-Full]     同步收敛：fetch → pull → bootstrap → verify -Quick（会请求一次 UAC）；
                       已收敛且声明未变走快速路径跳过 bootstrap（秒级），-Full 强制全量
  wdc verify [-Full]   机器断言（默认 -Quick；-Full 含三域漂移约 3 分钟）
  wdc triage           dotfiles 落点漂移分流（逐文件 吸收/还原，交互式）
  wdc audit            winget 清单准入对账（只读恒 exit 0：已声明未装 / 自装未声明）
  wdc upgrade-git      Git for Windows 升级专用通道（坑14：会话内必被 in-use 拦——计划任务脱离进程树）
  wdc log [-Lines N]   最近一次 bootstrap 日志尾部（默认 40 行）
  wdc help [命令]      本总览或单命令详解（-h/--help 同义；子命令后接 -h 出该命令详解）
  wdc version          版本（-v/--version 同义）

  退出码：0 成功 · 1 失败 · 3 收敛锁占用（sync）
'@

$helpDetail = @{
    'status' = @'
wdc status — 只读快照（秒级，不改任何状态）
  远端差距（fetch 后与 origin/main 的领先/落后）、dotfiles 落点漂移（逐项内容比对，ADR-0015；
  >0 提示 wdc triage，落点缺失则重跑 bootstrap）、
  身份文件是否生效（占位未填则 git 拒绝提交护栏仍在）、WSL/Ubuntu 首跑状态、
  最近一次 bootstrap 判定行。
  裸 wdc 等价于 wdc status。-Json 出单行机器可读出口（agent 判定不 scrape 颜色文本；
  包装层把 --json 归一为 -Json——pwsh 绑定器不收 --json）。
'@
    'plan' = @'
wdc plan — 干跑预演（只读，零变更）
  投影重跑 wdc sync 会做什么：仓库三态（一致 OK / 落后将拉取 N 提交 / 领先或分叉将中止交人工）、
  bootstrap 走全量还是快速路径（=会不会弹 UAC、约分钟级还是秒级）及原因、verify 收尾口径。
  UAC/重跑前先看一眼再决定。安装面逐项投影（ldc plan-machine 同款）为后续票——
  三域漂移详查 wdc verify -Full，dotfiles 漂移分流 wdc triage。恒 exit 0（预演不是断言）。
'@
    'sync' = @'
wdc sync [-Full] — 同步收敛（日常一键；会请求一次 UAC）
  顺序：fetch → 落后则 pull --ff-only（本地领先/分叉一律中止交人工）→ bootstrap → verify -Quick 收尾。
  快速路径（工单42）：收敛账本（%LOCALAPPDATA%\wdc\converged.json，bootstrap 全量成功尾部写入）的
  commit == 当前 HEAD 且工作区干净 → 跳过 bootstrap 只跑 verify -Quick，秒级完成；
  有新 pull、工作区有未提交改动、账本缺失/损坏/解析失败 → 全量 bootstrap 照旧
  （宁可慢不可假绿）。-Full 强制全量收敛。三域漂移详查：wdc verify -Full。
  任一段失败即非零退出，并自动贴出 bootstrap 与提权日志尾部。
'@
    'verify' = @'
wdc verify [-Full] — 机器断言
  六组断言：dotfiles 渲染拷贝（内容比对）/ 身份与注册表 / 移除清单核销 / 语言栈 / WSL 侧 / 三域漂移。
  默认 -Quick（秒级）；-Full 加三域 winget configure test 漂移（约 3 分钟）。
'@
    'triage' = @'
wdc triage — dotfiles 落点漂移分流（交互式）
渲染拷贝模型（ADR-0015）下机器侧工具直改的是落点渲染物，仓库模板不受污染；本命令逐文件给出
「吸收进模板 / 自模板还原」的处置入口（ADR-0003 判据）。verify 的内容比对断言 FAIL 时也会指向这里。
'@
    'audit' = @'
wdc audit — winget 清单准入对账（只读恒 exit 0）
两个方向（对齐 LDC audit）：① 已声明未装（configs/*.winget 逐 Id 核销，收敛待办）；
② 自装未声明（清单准入候选，Windows 侧噪声大——首版 INFO 计数 + 头部样例）。
这是对账报告不是断言——机器自装面属机器自留地（ADR-0003），只报不裁。
'@
    'upgrade-git' = @'
wdc upgrade-git — Git for Windows 升级专用通道（坑14，工单43）
  Git.Git 声明 useLatest：出新版后全量收敛即试图升级，而 agent 会话宿主即 Git Bash，
  安装器 in-use 检查必拦（/FORCECLOSEAPPLICATIONS 无效）→ Stage 3 cli-tools 域 FAIL。
  本命令登记 HIGHEST 一次性计划任务（2 分钟后起跑）执行 scripts/adhoc/git-upgrade-task.ps1：
  先等本会话 bash/sh 清零且连续 3×5s 静默 → winget 升级 → 校验/还原 etc\gitconfig（坑14③）。
  未提权会话经 sudo 登记（UAC 弹窗请放行）；完成后 git --version 验证、wdc sync 恢复收敛；
  进度/排障日志：scripts/adhoc/git-upgrade-schtasks.log。
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
        Write-Host ("wdc: 「$topic」没有单独的帮助（可用：" + ($wdcCommandsDetail -join ' / ') + '）') -ForegroundColor Yellow
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
    # 子命令 + -h 落单命令详解（cli-ux 工单04）：显式传了子命令且未给 topic → 按该子命令出详解；
    # 裸 `wdc -h` 的 $Command 是缺省值 status（非用户输入，PSBoundParameters 守卫）→ 仍出总览
    $topic = $Topic
    if (-not $topic -and $PSBoundParameters.ContainsKey('Command') -and $Command -notin 'help', '-h', '--help') { $topic = $Command }
    Show-WdcHelp $topic
    exit 0
}
if ($Command -notin $wdcCommands) {
    $sug = Get-WdcCommandSuggestion $Command
    Write-Host ("wdc: 未知子命令「$Command」（可用：" + ($wdcCommands -join ' / ') + '）') -ForegroundColor Yellow
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
        # 先算后印（cli-ux 工单02）：人读 step 序列与 -Json 单行出口共用同一批判定，防两路口径漂移
        $repoState = 'ok'
        if (-not (Invoke-WdcFetchBounded -Repo $repo -TimeoutSec 5)) {
            # fetch 未达（超时/断网/禁交互拒绝）：按本地缓存的 origin/main 判读（对齐 ldc 口径）
            $repoState = 'fetch-unreachable'
        }
        $ab = Get-AheadBehind
        $ahead = $ab[0]; $behind = $ab[1]
        if ($repoState -eq 'ok') {
            if ($ahead -gt 0 -and $behind -gt 0) { $repoState = 'diverged' }
            elseif ($ahead -gt 0) { $repoState = 'ahead' }
            elseif ($behind -gt 0) { $repoState = 'behind' }
        }
        $drift = @(Get-DotfilesMap | Where-Object { (Test-DotfileInSync -Source (Join-Path (Join-Path $repo 'dotfiles') $_.Source) -Target $_.Target) -ne 'ok' })
        $driftNames = @($drift | ForEach-Object { $_.Source })
        # 首跑两件手工事的状态可见（工单29）：身份占位未填则「拒提交」护栏仍在；WSL 未启用/Ubuntu 未装则收敛未完成
        $identityOk = Test-GitIdentityEffective
        $wslState = 'ok'
        if (Test-IsElevated) { $wslState = 'skipped-elevated' }
        elseif (-not (Test-WslEnabled)) { $wslState = 'not-enabled' }
        elseif ((Get-WslDistros) -notcontains 'Ubuntu') { $wslState = 'no-ubuntu' }
        # 上游检查提醒已撤（2026-11-07 主人定夺：wdc 无严格意义上的上游，ADR-0001 修订标注；账本封卷）
        $lastLog = $null; $lastName = ''; $lastVerdict = ''
        $log = Get-LastBootstrapLog
        if ($log) {
            # 判定行落点随流程而异：提权委托流的七阶段汇总在 elevated-*.log 收尾（工单19），-NoElevate 流在主日志
            # ——取两者中较新者搜判定；UAC 被取消等早退日志没有 bootstrap 汇总行，兜底显示最后一条判定行
            $verdictLog = $log
            $elog = Get-LastElevatedLog
            if ($elog -and $elog.LastWriteTime -gt $log.LastWriteTime) { $verdictLog = $elog }
            $m = Select-String -Path $verdictLog.FullName -Pattern '^\[(OK|FAIL)\] bootstrap' | Select-Object -Last 1
            if (-not $m) { $m = Select-String -Path $verdictLog.FullName -Pattern '^\[(OK|FAIL)\] ' | Select-Object -Last 1 }
            $lastLog = $verdictLog
            $lastName = $verdictLog.Name
            $lastVerdict = if ($m) { $m.Line } else { '（无判定行）' }
        }
        if ($Json) {
            # 单行紧凑 JSON（工单02）：键口径与 ldc status --json 对齐（docs/cli-parity.md）
            $hints = @()
            if ($repoState -in 'ahead', 'behind', 'diverged') { $hints += 'wdc sync' }
            if ($repoState -eq 'fetch-unreachable') { $hints += '远端 fetch 未达——按缓存判读；wdc sync 会先验 fetch 再动' }
            if ($drift.Count -gt 0) { $hints += 'wdc triage' }
            if (-not $identityOk) { $hints += '编辑 ~/.gitidentity' }
            if ($wslState -eq 'not-enabled') { $hints += '管理员终端 wsl --install 并重启' }
            if ($wslState -eq 'no-ubuntu') { $hints += '管理员终端 wsl --install -d Ubuntu' }
            $out = [ordered]@{
                tool     = 'wdc'
                version  = Get-WdcVersion
                command  = 'status'
                repo     = [ordered]@{ state = $repoState; ahead = $ahead; behind = $behind }
                dotfiles = [ordered]@{ drift_count = $drift.Count; drift_items = $driftNames }
                identity = [ordered]@{ ok = [bool]$identityOk }
                wsl      = [ordered]@{ state = $wslState }
                last_bootstrap = if ($lastLog) { [ordered]@{ log = $lastName; verdict = $lastVerdict } } else { $null }
                hints    = $hints
            }
            Write-Host (ConvertTo-Json $out -Compress)
            exit 0
        }
        Write-Phase 'wdc status · 只读快照'
        switch ($repoState) {
            'fetch-unreachable' { Write-Step '仓库' 'INFO' "领先 $ahead / 落后 $behind（远端 fetch 未达：5s 超时/断网）——按上次 fetch 缓存判读；wdc sync 会先验 fetch 再动" }
            'ok' { Write-Step '仓库' 'OK' '与 origin/main 一致' }
            default { Write-Step '仓库' 'INFO' "领先 $ahead / 落后 $behind——wdc sync 同步之" }
        }
        if ($drift.Count -eq 0) { Write-Step 'dotfiles 漂移' 'OK' '全部落点与模板一致' }
        else { Write-Step 'dotfiles 漂移' 'FAIL' "$($drift.Count) 项落点与模板不一致——wdc triage 分流（缺失落点重跑 bootstrap）" }
        if ($identityOk) { Write-Step '身份文件' 'OK' 'name/email 经 include 生效' }
        else { Write-Step '身份文件' 'FAIL' '未填写——编辑 ~/.gitidentity（占位已生成）；不填则 git 拒绝提交' }
        switch ($wslState) {
            'ok' { Write-Step 'WSL' 'OK' 'Ubuntu 已就位' }
            'skipped-elevated' { Write-Step 'WSL' 'SKIP' '提权上下文保守跳过探测（坑①）——普通终端再跑 wdc status' }
            'not-enabled' { Write-Step 'WSL' 'FAIL' '未启用——管理员终端 wsl --install 并重启，然后重跑 bootstrap' }
            'no-ubuntu' { Write-Step 'WSL' 'FAIL' 'Ubuntu 未装——管理员终端 wsl --install -d Ubuntu，然后重跑 bootstrap' }
        }
        if ($log) { Write-Step '最近 bootstrap' 'INFO' "$lastName → $lastVerdict" }
        else { Write-Step '最近 bootstrap' 'INFO' 'logs/ 尚无日志' }
        if ($bare) {
            Write-Step '提示' 'INFO' '裸 wdc 即本快照（只读）。同步收敛：wdc sync；全部命令：wdc help'
        }
    }

    'plan' {
        # 干跑预演 v1（cli-ux 工单03）：sync 流决策投影——「重跑 wdc sync 会做什么」先看一眼再决定。
        # 只读零变更、恒 exit 0（预演不是断言，对齐 ldc plan）。安装面逐项投影（ldc plan-machine 同款）
        # 需逐域解析 winget configure test，另立后续票——本版回答三件事：会拉几个提交 /
        # bootstrap 走全量还是快速路径（=会不会弹 UAC、分钟级还是秒级）/ verify 收尾口径
        Write-Phase 'wdc plan · 干跑预演（只读，零变更）'
        $fetchOk = Invoke-WdcFetchBounded -Repo $repo -TimeoutSec 5
        $ab = Get-AheadBehind
        $ahead = $ab[0]; $behind = $ab[1]
        if (-not $fetchOk) {
            Write-Step '仓库' 'INFO' "领先 $ahead / 落后 $behind（远端 fetch 未达：5s 超时/断网）——按缓存判读；wdc sync 会先验 fetch 再动"
        } elseif ($ahead -gt 0 -and $behind -gt 0) {
            Write-Step '仓库' 'FAIL' "sync 将在此中止：本地与远端分叉（领先 $ahead / 落后 $behind）——人工处理后再同步"
        } elseif ($ahead -gt 0) {
            Write-Step '仓库' 'FAIL' "sync 将在此中止：本地领先 $ahead 个提交未推送——先 push 再 wdc"
        } elseif ($behind -gt 0) {
            Write-Step '仓库' 'PLAN' "将拉取 $behind 个提交（pull --ff-only）"
        } else {
            Write-Step '仓库' 'OK' '已与 origin/main 一致（sync 无拉取）'
        }
        # 快速路径判定（与 sync 同条件只读投影，工单42）：账本 == HEAD 且工作区干净 → 跳过 bootstrap
        $fast = $false; $reasons = @()
        $head = [string](git -C $repo rev-parse HEAD 2>$null)
        $ledger = Get-WdcConvergenceLedger
        if ($LASTEXITCODE -eq 0 -and $ledger -and $ledger -eq $head) {
            $dirty = @(git -C $repo status --porcelain)
            if ($dirty.Count -eq 0) { $fast = $true } else { $reasons += '工作区有未提交改动' }
        } elseif (-not $ledger) {
            $reasons += '收敛账本缺失/无效'
        } else {
            $reasons += 'HEAD 已前移（有新提交未收敛）'
        }
        if ($fast) {
            Write-Step 'bootstrap' 'SKIP' '将走快速路径（账本 == HEAD 且工作区干净）——秒级，不弹 UAC（-Full 强制全量）'
        } else {
            Write-Step 'bootstrap' 'PLAN' ('将全量 bootstrap（约分钟级，将请求一次 UAC）——原因：' + ($reasons -join '；'))
        }
        Write-Step 'verify' 'INFO' 'sync 收尾恒跑 verify -Quick（秒级）；三域漂移详查 wdc verify -Full；dotfiles 漂移分流 wdc triage'
        Write-Step '提示' 'INFO' '本投影只读零变更；实际收敛 wdc sync'
        exit 0
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

    'audit' {
        & pwsh -NoProfile -File (Join-Path $repo 'scripts\audit-machine.ps1')
        exit $LASTEXITCODE
    }

    'upgrade-git' {
        # 坑14 通道（工单43）：agent 会话宿主即 Git Bash——安装器 in-use 检查必拦直接升级，
        # 走 HIGHEST 一次性计划任务脱离会话进程树；剧本本体 scripts/adhoc/git-upgrade-task.ps1
        Write-Phase 'wdc upgrade-git · Git for Windows 升级（坑14 计划任务通道）'
        $creator = Join-Path $repo 'scripts\adhoc\git-upgrade-task-creator.ps1'
        if (-not (Test-Path $creator)) { Write-Step '创建器' 'FAIL' "未找到 $creator"; exit 1 }
        $viaSudo = -not (Test-IsElevated)
        if ($viaSudo) { Write-Step '提权' 'INFO' '本会话未提权——经 sudo 登记任务，UAC 弹窗请放行' }
        $cArgs = @(); if ($viaSudo) { $cArgs += '-ViaSudo' }
        & pwsh -NoProfile -File $creator @cArgs
        if ($LASTEXITCODE -ne 0) { Write-Step '登记' 'FAIL' '任务登记未成（见上）'; exit 1 }
        Write-Step '登记' 'OK' '任务已建（2 分钟后起跑）——接下来三件事：'
        Write-Host '  1. 本会话/终端停手：任务先等 bash/sh 进程清零且连续 3×5s 静默才发起升级（发起即无需再守）'
        Write-Host '  2. UAC 与安装器弹窗由你放行（--silent 仍可能弹交互向导，点 OK 即可——坑14 附注）'
        Write-Host '  3. 完成后验证：git --version 出新版本号；wdc sync 恢复收敛（cli-tools 域回绿）'
        Write-Step '日志' 'INFO' (Join-Path $repo 'scripts\adhoc\git-upgrade-schtasks.log')
        exit 0
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
        # fetch 有界禁交互（cli-ux 工单01）：失败/超时即中止——不盲按陈旧 origin/main 判「一致」漏拉（对齐 ldc）
        if (-not (Invoke-WdcFetchBounded -Repo $repo -TimeoutSec 10)) {
            Write-Step '仓库' 'FAIL' '远端 fetch 失败（网络/超时/禁交互拒绝）——中止，不做盲同步'
            exit 1
        }
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

        # 快速路径判定（工单42）：收敛账本 commit == 当前 HEAD 且工作区干净 → 声明未变，跳过 bootstrap。
        # 任一不成立 → 全量照旧（宁可慢不可假绿）：-Full 强制 / 账本缺失损坏解析失败（Get-WdcConvergenceLedger
        # 返回 $null）/ 有新 pull（HEAD 已变）/ 工作区有未提交改动（未提交的声明编辑不改 HEAD，
        # 只判账本会漏——脏树守卫一并兜住脚本侧未提交改动）。
        $fast = $false
        if (-not $Full) {
            $head = [string](git -C $repo rev-parse HEAD)
            $ledger = Get-WdcConvergenceLedger
            if ($LASTEXITCODE -eq 0 -and $ledger -and $ledger -eq $head) {
                $dirty = @(git -C $repo status --porcelain)
                if ($dirty.Count -eq 0) { $fast = $true }
            }
        }

        Write-Phase 'wdc sync · bootstrap'
        if ($fast) {
            Write-Step 'bootstrap' 'SKIP' '声明未变（收敛账本=HEAD、工作区干净）——快速路径跳过 bootstrap（-Full 可强制全量）'
        } else {
            Write-Step '提示' 'INFO' 'bootstrap 即将开始，会请求一次 UAC 提权'
            # -SkipValidate：sync 走到 bootstrap 时必然 HEAD==origin/main（领先/分叉已退出）——
            # 同一 commit 的 validate 在 push 时 CI 已把关（dev-standard「CI 兜底」），本地 Stage 2 降级 SKIP（工单02）
            & pwsh -NoProfile -File (Join-Path $repo 'bootstrap.ps1') -SkipValidate
            if ($LASTEXITCODE -ne 0) {
                if ($LASTEXITCODE -eq 3) {
                    Write-Step 'bootstrap' 'FAIL' '已有一次收敛在跑（运行锁占用）——等当前收敛结束再 wdc sync'
                    exit 1
                }
                Write-Step 'bootstrap' 'FAIL' '未全绿——最近日志尾部（完整见 logs/）'
                $log = Get-LastBootstrapLog
                if ($log) { Get-Content $log.FullName -Tail 30 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray } }
                $elog = Get-LastElevatedLog
                if ($elog) {
                    Write-Host ''
                    Write-Step '提权子回合尾部' 'INFO' $elog.FullName
                    Get-Content $elog.FullName -Tail 20 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
                }
                # 完成 BEL（工单06）：bootstrap 分钟级长操作失败更需要注意力回收
                [Console]::Write([char]7)
                exit 1
            }
        }

        Write-Phase 'wdc sync · verify（-Quick 收尾，工单02）'
        & pwsh -NoProfile -File (Join-Path $repo 'scripts\verify-machine.ps1') -Quick
        $code = $LASTEXITCODE
        Write-Phase 'wdc sync · 汇总'
        if ($code -eq 0) { Write-Step 'wdc' 'OK' "同步完成，机器与声明一致（$([int]$sw.Elapsed.TotalSeconds)s；-Quick 收尾，三域漂移详查 wdc verify -Full）" }
        else { Write-Step 'wdc' 'FAIL' 'verify 未全绿——排障后 wdc verify 复查' }
        # 完成 BEL（cli-ux 工单06）：分钟级长操作收尾，切走窗口结束有感知（OK/FAIL 两路都响）
        [Console]::Write([char]7)
        exit $code
    }
}

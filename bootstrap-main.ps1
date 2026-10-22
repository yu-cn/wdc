#Requires -Version 7
# bootstrap-main.ps1 - WDC 收敛逻辑本体（PowerShell 7）
# 由根 bootstrap.ps1 引导层定位/自举 PowerShell 7 后带参转发；已有 PS7 的机器也可直调。
# 用法:
#   pwsh bootstrap-main.ps1                # 完整收敛（需要管理员，未提权时自动请求；提权子回合跑完全部七阶段）
#   pwsh bootstrap-main.ps1 -ValidateOnly  # 只做无副作用校验
#   pwsh bootstrap-main.ps1 -NoElevate     # 非提权单回合（排障逃生通道：apply 与 WSL 启用受限跳过）
[CmdletBinding()]
param(
    [switch]$ValidateOnly,
    [switch]$NoElevate,
    [switch]$ElevatedPass   # 内部参数：提权子回合标记（由自动串联产生，勿手动使用）
)
$ErrorActionPreference = 'Stop'
# 控制台统一 UTF-8：修正中文在 GBK 代码页窗口里的乱码（显示问题，不影响执行）
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch { }
. (Join-Path $PSScriptRoot 'scripts/lib/common.ps1')

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$script:Stages = [System.Collections.Generic.List[object]]::new()

# 日志落盘：排障不再依赖事后拍状态快照（logs/ 已被 .gitignore 的 *.log 覆盖）
$logDir = Join-Path $PSScriptRoot 'logs'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
# 日志轮转：只保留最近 20 份，避免长期累积
Get-ChildItem $logDir -Filter '*.log' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -Skip 20 |
    Remove-Item -Force -ErrorAction SilentlyContinue
$logFile = Join-Path $logDir ("bootstrap-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
# 提权子回合不自建 transcript（工单19）：其输出由父进程的 Tee 包装落盘到 elevated-*.log——
# transcript 在原生日令交互下会中断（工单19 实录），外层包装进程持有的管道独立存续
if (-not $ElevatedPass) {
    try { Start-Transcript -Path $logFile -ErrorAction SilentlyContinue | Out-Null } catch { }
}

function Invoke-Stage {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$Body
    )
    Write-Phase $Name
    $stageSw = [System.Diagnostics.Stopwatch]::StartNew()
    $ok = $true
    try { $ok = & $Body } catch {
        Write-Step $Name 'FAIL' $_.Exception.Message
        $ok = $false
    }
    $stageSw.Stop()
    $script:Stages.Add([pscustomobject]@{ Name = $Name; Ok = $ok; Secs = $stageSw.Elapsed.TotalSeconds })
    return $ok
}

# ---------------------------------------------------------------------------
# Stage 1/7 · Preflight 预检
# ---------------------------------------------------------------------------
$elevated = $false
$null = Invoke-Stage 'Stage 1/7 - Preflight 预检' {
    $script:elevated = Test-IsElevated
    if ($elevated) { Write-Step '提权状态' 'OK' '管理员 - 全部阶段可执行' }
    else { Write-Step '提权状态' 'SKIP' '普通用户 - HKLM 注册表与全机安装将受限' }
    Write-Step '工作目录' 'INFO' $PSScriptRoot
    return $true
}

# 单命令一键收敛（工单16 → 工单30 全程提权重构）：未提权完整模式下弹一次 UAC，
# 提权子回合一回合跑完全部七阶段（含 WSL——坑①已由调用纪律根除，见 scripts/lib/common.ps1）；
# 父回合只等待并转发退出码，不再补跑任何阶段。子回合日志经 Tee 落盘（工单19）。
if (-not $elevated -and -not $ValidateOnly -and -not $NoElevate -and -not $ElevatedPass) {
    Write-Phase '提权收敛（管理员子回合·全程七阶段）'
    $childLog = Join-Path $logDir ("elevated-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $childCmd = "& '$PSCommandPath' -ElevatedPass *>&1 | Tee-Object -FilePath '$childLog'; exit `$LASTEXITCODE"
    $relaunchArgs = @('-NoProfile', '-Command', $childCmd)
    $childSw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $child = Start-Process pwsh -Verb RunAs -ArgumentList $relaunchArgs -PassThru -Wait
        $childSw.Stop()
        $childOk = ($child.ExitCode -eq 0)
        Write-Step '提权子回合' ($childOk ? 'OK' : 'FAIL') "全程收敛退出码 $($child.ExitCode)（$([int]$childSw.Elapsed.TotalSeconds)s）"
        Write-Step '日志' 'INFO' $childLog
        Write-Step 'bootstrap' ($childOk ? 'OK' : 'FAIL') ($childOk ? '收敛完成（幂等：重跑应零变更）' : '未全绿——完整日志见上；尾部：wdc log')
        try { Stop-Transcript | Out-Null } catch { }
        exit $child.ExitCode
    } catch {
        Write-Step '提权' 'FAIL' 'UAC 被取消或不可用。重试，或用 -NoElevate 走非提权单回合（apply 与 WSL 启用受限）'
        try { Stop-Transcript | Out-Null } catch { }
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Stage 2/7 · Validate 无副作用校验
# ---------------------------------------------------------------------------
$null = Invoke-Stage 'Stage 2/7 - Validate 无副作用校验' {
    # 子进程 stdout 不入本阶段返回值（Invoke-Subscript 负责转发到 Host），返回值只留 bool
    $ok = Invoke-Subscript -Label 'validate.ps1' -Path (Join-Path $PSScriptRoot 'validate.ps1')
    if (-not $ok) { Write-Host '  校验未通过——后续阶段仍执行（幂等重跑可收敛），结果见 Summary' -ForegroundColor Red }
    return $ok
}

# ---------------------------------------------------------------------------
# Stage 3/7 · Apply 应用声明配置（winget configure，按依赖序：设置 -> 软件）
# ---------------------------------------------------------------------------
$null = Invoke-Stage 'Stage 3/7 - Apply 应用声明配置' {
    if ($ValidateOnly) { Write-Step '应用配置' 'SKIP' '-ValidateOnly 模式不执行'; return $true }
    if (-not $elevated) {
        Write-Step '应用配置' 'SKIP' '需要管理员；本阶段已跳过（其余用户级阶段继续）'
        return $true
    }
    # 域清单与顺序走 Get-WdcDomains 单一来源（内置与 configs/ 目录的一致性校验）；语言版本走编排层 install-languages.ps1 钉子，无 .winget 域
    $domainOrder = Get-WdcDomains
    $allOk = $true
    # 注：曾试验「先 configure test 漂移=0 再跳过 apply」（工单18），实测 test 与 apply 的耗时几乎相同
    # （瓶颈是 winget 每次调用的固定开销），漂移>0 时反而多付一次——已回退，维持直接应用。
    foreach ($domain in $domainOrder) {
        $file = Join-Path $PSScriptRoot "configs/$domain.winget"
        if (-not (Test-Path $file)) { Write-Step $domain 'SKIP' '尚未创建（后续工单）'; continue }
        $out = & winget configure --file $file --accept-configuration-agreements --disable-interactivity 2>&1
        $code = $LASTEXITCODE
        $out | ForEach-Object { Write-Host $_ }
        if (Test-WingetExitCode -ExitCode $code -Operation 'configure') { Write-Step $domain 'OK' }
        else { Write-Step $domain 'FAIL' "winget configure 退出码 $code"; $allOk = $false }
    }
    return $allOk
}

# ---------------------------------------------------------------------------
# Stage 4/7 · 用户级安装（vp + VSCode 扩展；无需提权）
# ---------------------------------------------------------------------------
$null = Invoke-Stage 'Stage 4/7 - 用户级安装（vp + VSCode 扩展）' {
    if ($ValidateOnly) { Write-Step '用户级安装' 'SKIP' '-ValidateOnly 模式不执行'; return $true }
    $allOk = $true
    foreach ($s in 'install-languages.ps1', 'install-vscode-extensions.ps1') {
        if (-not (Invoke-Subscript -Label $s -Path (Join-Path $PSScriptRoot "scripts/$s"))) { $allOk = $false }
    }
    return $allOk
}

# ---------------------------------------------------------------------------
# Stage 5/7 · 移除清单（先装后拆：languages 已就位后才清旧轨）
# ---------------------------------------------------------------------------
$null = Invoke-Stage 'Stage 5/7 - 移除清单（先装后拆）' {
    if ($ValidateOnly) { Write-Step '移除清单' 'SKIP' '-ValidateOnly 模式不执行'; return $true }
    return (Invoke-Subscript -Label 'remove-leftovers.ps1' -Path (Join-Path $PSScriptRoot 'scripts/remove-leftovers.ps1'))
}

# ---------------------------------------------------------------------------
# Stage 6/7 · WSL 侧（安装编排 + 发行版内环境）
# ---------------------------------------------------------------------------
$null = Invoke-Stage 'Stage 6/7 - WSL 侧（安装编排 + 发行版环境）' {
    if ($ValidateOnly) { Write-Step 'WSL' 'SKIP' '-ValidateOnly 模式不执行'; return $true }
    # 工单30：全程提权下 WSL 阶段在提权回合真实执行——坑①由调用纪律根除（安装类新控制台不捕获、
    # 查询/发行版内走有界文件捕获，见 scripts/lib/common.ps1）；未全绿时提示 -NoElevate 逃生通道
    $allOk = $true
    foreach ($s in 'install-wsl.ps1', 'install-wsl-env.ps1') {
        if (-not (Invoke-Subscript -Label $s -Path (Join-Path $PSScriptRoot "scripts/$s"))) { $allOk = $false }
    }
    if (-not $allOk) { Write-Step 'WSL' 'INFO' '可试 pwsh bootstrap.ps1 -NoElevate 在非提权上下文补跑（坑①逃生通道）' }
    return $allOk
}

# ---------------------------------------------------------------------------
# Stage 7/7 · Dotfiles 安装
# ---------------------------------------------------------------------------
$null = Invoke-Stage 'Stage 7/7 - Dotfiles 安装' {
    if ($ValidateOnly) { Write-Step 'dotfiles' 'SKIP' '-ValidateOnly 模式不执行'; return $true }
    $installer = Join-Path $PSScriptRoot 'scripts/install-dotfiles.ps1'
    if (-not (Test-Path $installer)) {
        Write-Step 'dotfiles' 'SKIP' 'install-dotfiles.ps1 尚未创建（工单 02）'
        return $true
    }
    if (-not (Invoke-Subscript -Label 'install-dotfiles.ps1' -Path $installer)) { return $false }
    # pre-commit 钩子接线（工单23）：collaboration 承诺的「钩子把关」此前靠手工接线、实测主机未接——
    # 每次 bootstrap 幂等确保（repo-local 配置，不动全局）
    & git -C $PSScriptRoot config core.hooksPath .githooks
    if ($LASTEXITCODE -eq 0) { Write-Step 'pre-commit 钩子' 'OK' 'core.hooksPath → .githooks（repo-local）' }
    else { Write-Step 'pre-commit 钩子' 'FAIL' "git config 退出码 $LASTEXITCODE"; return $false }
    return $true
}

# ---------------------------------------------------------------------------
# Summary 汇总
# ---------------------------------------------------------------------------
Write-Phase 'Summary 汇总'
$failed = @($script:Stages | Where-Object { -not $_.Ok })
foreach ($s in $script:Stages) {
    $secs = if ($null -ne $s.Secs) { "（{0:n1}s）" -f $s.Secs } else { '' }
    Write-Step $s.Name ($s.Ok ? 'OK' : 'FAIL') $secs.Trim()
}
# 首跑手工步骤提醒（工单29）：身份占位未填不算收敛失败——不入 Stages、不改退出码；
# 但 Summary 必须可见，否则要到第一次 git commit 被「防错护栏」拒了才发现
if (-not $ValidateOnly -and -not (Test-GitIdentityEffective)) {
    Write-Step '身份文件' 'CHANGED' '占位未填写——编辑 ~/.gitidentity，否则 git 拒绝提交'
}
Write-Step '耗时' 'INFO' "$([int]$sw.Elapsed.TotalSeconds)s"
if ($failed.Count -eq 0) {
    Write-Step 'bootstrap' 'OK' '收敛完成（幂等：重跑应零变更）'
    try { Stop-Transcript | Out-Null } catch { }
    exit 0
} else {
    Write-Step 'bootstrap' 'FAIL' "$($failed.Count) 个阶段未通过"
    Write-Step '日志' 'INFO' $logFile
    try { Stop-Transcript | Out-Null } catch { }
    exit 1
}

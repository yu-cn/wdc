# common.ps1 — bootstrap 各阶段共用的报告与工具函数
Set-StrictMode -Version Latest

function Test-IsElevated {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = [Security.Principal.WindowsPrincipal] $id
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-Phase {
    param([Parameter(Mandatory)][string]$Name)
    Write-Host ''
    Write-Host "=== $Name ===" -ForegroundColor Cyan
}

function Write-Step {
    param(
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][ValidateSet('OK', 'SKIP', 'FAIL', 'CHANGED', 'INFO')][string]$State,
        [string]$Detail = ''
    )
    $color = switch ($State) {
        'OK'      { 'Green' }
        'SKIP'    { 'DarkGray' }
        'FAIL'    { 'Red' }
        'CHANGED' { 'Yellow' }
        default   { 'White' }
    }
    $line = "[$State] $Label"
    if ($Detail) { $line += " - $Detail" }
    Write-Host $line -ForegroundColor $color
}



function Invoke-Subscript {
    # 跑一个仓库内 pwsh 子脚本并按 Write-Step 口径报告：转发输出 · 判退出码 · 打 OK/FAIL，返回 $true/$false。
    # bootstrap 各阶段共用的机械（此前 8 处调用点各写一遍四步样板，细节微妙不一）
    param(
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][string]$Path,
        [string[]]$ArgumentList = @()
    )
    $out = & pwsh -NoProfile -File $Path @ArgumentList 2>&1
    $code = $LASTEXITCODE
    $out | ForEach-Object { Write-Host $_ }
    if ($code -eq 0) { Write-Step $Label 'OK'; return $true }
    Write-Step $Label 'FAIL' "退出码 $code"
    return $false
}

function Get-WdcDomains {
    # winget 域的单一事实源：应用顺序在此声明，并与 configs/*.winget 目录做一致性校验——
    # 目录里的域不在此清单即抛错（防「校验✓ 应用✗」的静默半接入）。顺序承载依赖：
    # base-windows 的字体/注册表须先于 editors 的软件（工单04）
    $ordered = @('base-windows', 'cli-tools', 'editors')
    $configDir = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'configs'
    $onDisk = @(Get-ChildItem $configDir -Filter '*.winget' -ErrorAction SilentlyContinue | ForEach-Object { $_.BaseName })
    $missing = @($ordered | Where-Object { $onDisk -notcontains $_ })
    $extra = @($onDisk | Where-Object { $ordered -notcontains $_ })
    if ($missing.Count -gt 0 -or $extra.Count -gt 0) {
        throw "configs/*.winget 与域清单不一致：缺失 $($missing -join ', ')；未入清单 $($extra -join ', ')——新域须加入 Get-WdcDomains 的顺序清单（或删除游离文件）"
    }
    return $ordered
}

function Test-WdcDomainNeedsElevation {
    # 域的提权需求单一来源（工单01 方案A）：verify 漂移段在未提权会话对含 HKLM/机器级单元的域评估不可靠
    # （评估失败被记为「未处于」，整域假警报）——相关域须降级 SKIP，故按域显式声明：
    # base-windows 含 7 个 HKLM 键（混合域）；cli-tools 包单元均机器级安装（winget 默认 machine scope）；
    # editors 纯用户级单包（VSCode user setup），未提权可正常评估。新域或单元 scope 变更须同步此表。
    param([Parameter(Mandatory)][ValidateSet('base-windows', 'cli-tools', 'editors')][string]$Domain)
    return @{ 'base-windows' = $true; 'cli-tools' = $true; 'editors' = $false }[$Domain]
}

function Test-WingetExitCode {
    # winget 退出码语义一处定义（坑④；官方码表：winget-cli returnCodes.md）：
    # 0=通过；负 HRESULT=真错。validate 另认 1=仅警告（私有配置单元/未指定模块两类，本仓库设计固有，实测 winget 1.29）；
    # configure 只认 0——回 1 未实证（官方配置错误均为 0x8A15C00x HRESULT，日志亦无实例），宁严勿松，实测良性再放宽（工单06）
    param(
        [Parameter(Mandatory)][int]$ExitCode,
        [ValidateSet('validate', 'configure', 'upgrade')][string]$Operation = 'validate'
    )
    if ($ExitCode -eq 0) { return $true }
    if ($Operation -eq 'validate' -and $ExitCode -eq 1) { return $true }
    return $false
}

function Test-GitIdentityEffective {
    # git 身份是否经 include 链生效（效果级，与 verify 断言同口径）：bootstrap Summary 与 wdc status 共用。
    # --global + --includes：全栈 include 展开（坑⑤）且不受 cwd 所在仓库 local config 污染；
    # 只判非空、不取值——红线：身份内容不得出现在任何产出物/日志
    [bool](git config --global --includes --get user.name) -and
    [bool](git config --global --includes --get user.email)
}

function Wait-WdcProcess {
    # 有界等待外部进程：500ms 轮询、每 60s 心跳、超时杀进程并抛 TimeoutException。
    # 吸收自上游 Invoke-DevConfigProcess 配方（工单30）：可能挂住的原生命令必须过这道护栏，挂死变有界失败
    param(
        [Parameter(Mandatory)][System.Diagnostics.Process]$Process,
        [Parameter(Mandatory)][ValidateRange(1, 86400)][int]$TimeoutSeconds,
        [string]$Label = '进程'
    )
    $start = Get-Date
    $deadline = $start.AddSeconds($TimeoutSeconds)
    $nextBeat = $start.AddSeconds(60)
    while (-not $Process.HasExited) {
        $now = Get-Date
        if ($now -ge $deadline) {
            try { $Process.Kill() } catch { }
            throw [System.TimeoutException]::new("$Label 超过 $([int]($TimeoutSeconds / 60)) 分钟未结束，已终止")
        }
        if ($now -ge $nextBeat) {
            Write-Step $Label 'INFO' ("仍在运行（{0:n0} 分钟）" -f ($now - $start).TotalMinutes)
            $nextBeat = $now.AddSeconds(60)
        }
        Start-Sleep -Milliseconds 500
    }
    return $Process.ExitCode
}

function Invoke-WslBounded {
    # 有界、临时文件捕获的 wsl.exe 调用（坑①纪律，工单30；上游 Get-DevConfigWslExitCode 同配方）：
    # - 输出重定向到文件句柄而非 PS 管道——提权上下文安全的前提（坑①实录是 PS 管道捕获姿势）
    # - stdin 指到空临时文件 = 关闭：防未装运行时的 wsl 停在安装提示等输入（上游注释实录）
    # - WSL_UTF8=1 请求 UTF-8 输出；旧版不认时 NUL 剥除兜底（ASCII 段 UTF-16 可经 NUL 剥还原）
    # - 只看退出码，输出文本随系统语言变（上游注释实录）
    # 未装 wsl.exe / 超时：返回 Exit=$null（或 $null 本体）——调用方按失败处理
    param(
        [Parameter(Mandatory)][string[]]$ArgumentList,
        [int]$TimeoutSeconds = 120
    )
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) { return $null }
    $stdout = [System.IO.Path]::GetTempFileName()
    $stderr = [System.IO.Path]::GetTempFileName()
    $stdin = [System.IO.Path]::GetTempFileName()
    $prevUtf8 = $env:WSL_UTF8
    try {
        $env:WSL_UTF8 = '1'
        $p = Start-Process wsl.exe -ArgumentList $ArgumentList -PassThru -NoNewWindow `
            -RedirectStandardOutput $stdout -RedirectStandardError $stderr -RedirectStandardInput $stdin
        try { $code = Wait-WdcProcess -Process $p -TimeoutSeconds $TimeoutSeconds -Label ("wsl " + ($ArgumentList -join ' ')) }
        catch [System.TimeoutException] { return [pscustomobject]@{ Lines = @(); Exit = $null } }
        $lines = @(Get-Content -LiteralPath $stdout, $stderr -ErrorAction SilentlyContinue |
            ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ })
        return [pscustomobject]@{ Lines = $lines; Exit = $code }
    } finally {
        $env:WSL_UTF8 = $prevUtf8
        Remove-Item -LiteralPath $stdout, $stderr, $stdin -Force -ErrorAction SilentlyContinue
    }
}

function Test-WslEnabled {
    # WSL 功能是否可用（wsl --status 退出码；未装 wsl.exe/超时一并 $false）——有界姿势下提权上下文同样安全
    $r = Invoke-WslBounded -ArgumentList @('--status') -TimeoutSeconds 60
    return ($null -ne $r -and $r.Exit -eq 0)
}

function Get-WslDistros {
    # wsl -l -q 的干净输出（有界文件捕获，坑①纪律；wsl.exe 未就位/超时/无发行版时空数组）
    $r = Invoke-WslBounded -ArgumentList @('-l', '-q') -TimeoutSeconds 60
    if ($null -eq $r -or $r.Exit -ne 0) { return @() }
    return @($r.Lines)
}

function Get-WslDefaultUser {
    # 发行版默认用户探测（whoami；硬编码用户名会误伤默认用户不同的机器，工单12族）；探不到返回 $null
    param([string]$Distro = 'Ubuntu')
    $r = Invoke-WslBounded -ArgumentList @('-d', $Distro, '-e', 'bash', '-c', 'whoami') -TimeoutSeconds 60
    if ($null -eq $r -or $r.Exit -ne 0) { return $null }
    return @($r.Lines) | Select-Object -First 1
}

function Invoke-WslScript {
    # 在发行版内以 bash 跑一个脚本（可带参数）：返回 Lines / Exit / Ok（契约不变：install-wsl-env 与 verify 共用）。
    # 有界文件捕获（坑①纪律）：默认 15 分钟上限——发行版内 apt/Docker 安装可达分钟级；超时杀进程按失败处理
    param(
        [Parameter(Mandatory)][string]$Distro,
        [string]$User,
        [Parameter(Mandatory)][string]$Script,
        [string[]]$ScriptArgs = @()
    )
    $a = @('-d', $Distro)
    if ($User) { $a += @('-u', $User) }
    $a += @('-e', 'bash', $Script) + $ScriptArgs
    $r = Invoke-WslBounded -ArgumentList $a -TimeoutSeconds 900
    if ($null -eq $r) { return [pscustomobject]@{ Lines = @(); Exit = $null; Ok = $false } }
    return [pscustomobject]@{ Lines = @($r.Lines); Exit = $r.Exit; Ok = ($r.Exit -eq 0) }
}

function ConvertTo-WslPath {
    # Windows 绝对路径 → WSL 视角（D:\x\y → /mnt/d/x/y；仅盘符路径形态，本仓库使用面内够用）
    param([Parameter(Mandatory)][string]$Path)
    $p = $Path.Replace('/', '\')
    "/mnt/$($p.Substring(0, 1).ToLower())/$($p.Substring(3).Replace('\', '/'))"
}

# ---------------------------------------------------------------------------
# 运行锁（GLOSSARY「运行锁」）：全局命名互斥体，防两个收敛会话并发踩 winget
# ---------------------------------------------------------------------------
function Enter-WdcRunLock {
    # 抢占式获取全局运行锁（上游 Global\WindowsDevConfigSetup 同思想）：WaitOne(0) 非阻塞。
    # 前持锁进程崩溃时内核自动废弃并转交所有权（AbandonedMutexException 即所有权已到手）——
    # 无「陈旧锁」清理问题。成功返回互斥体句柄（调用方负责 Exit-WdcRunLock）；被占用返回 $null。
    $m = [System.Threading.Mutex]::new($false, 'Global\WdcBootstrap')
    try { $acquired = $m.WaitOne(0) }
    catch [System.Threading.AbandonedMutexException] { $acquired = $true }
    if (-not $acquired) { $m.Dispose(); return $null }
    return $m
}

function Exit-WdcRunLock {
    param([Parameter(Mandatory)][System.Threading.Mutex]$Mutex)
    try { $Mutex.ReleaseMutex() } catch { }
    $Mutex.Dispose()
}

# ---------------------------------------------------------------------------
# 续跑任务（GLOSSARY「续跑任务」）：WSL 功能启用需重启时登记的一次性登录任务
# ---------------------------------------------------------------------------
$script:WdcResumeTaskName = 'WdcBootstrapResume'

function Register-WdcResumeTask {
    # 登记一次性续跑：下次登录自动重跑 bootstrap.ps1（RunLevel Highest 免 UAC），幂等（-Force 覆盖）。
    # 无循环保证：任务在任意一次 bootstrap 真实收敛启动时即被清除（bootstrap-main 的 Remove-WdcResumeTask），
    # 且续跑时 WSL 已启用、不会再触发登记分支。
    param([Parameter(Mandatory)][string]$BootstrapPath)
    $pwshExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    $action = New-ScheduledTaskAction -Execute $pwshExe `
        -Argument ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $BootstrapPath)
    # 触发器收窄到发起 bootstrap 的用户登录（不带 -User 是「任意用户登录」，注册也要提权；
    # scoped 后语义正确：只在该用户的下次登录续跑）
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
        -ExecutionTimeLimit ([TimeSpan]::FromHours(2))
    try {
        Register-ScheduledTask -TaskName $script:WdcResumeTaskName -Action $action -Trigger $trigger `
            -Settings $settings -RunLevel Highest -Force -ErrorAction Stop | Out-Null
        Write-Step '续跑任务' 'CHANGED' '已登记：重启登录后自动重跑 bootstrap 收尾（无需人工）；任意一次 bootstrap 启动即清除'
    } catch {
        Write-Step '续跑任务' 'INFO' "自动登记未成（$($_.Exception.Message)）——重启后手工重跑 bootstrap.ps1（原路径不变）"
    }
}

function Test-WdcResumeTaskExists {
    [bool](Get-ScheduledTask -TaskName $script:WdcResumeTaskName -ErrorAction SilentlyContinue)
}

function Remove-WdcResumeTask {
    # 存在即删（幂等 BestEffort）：要么本次正是续跑、要么人工已接管——残留任务不跨收敛存续
    if (-not (Test-WdcResumeTaskExists)) { return }
    try {
        Unregister-ScheduledTask -TaskName $script:WdcResumeTaskName -Confirm:$false -ErrorAction Stop
        Write-Step '续跑任务' 'CHANGED' '已清除待续跑任务（本次收敛接管）'
    } catch {
        Write-Step '续跑任务' 'INFO' "自动清除未成（$($_.Exception.Message)）——手工：schtasks /Delete /TN $script:WdcResumeTaskName /F"
    }
}

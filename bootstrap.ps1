#Requires -Version 7
# bootstrap.ps1 - WDC 开发环境唯一入口（GLOSSARY: bootstrap）
# 用法:
#   pwsh bootstrap.ps1                # 完整收敛（需要管理员，未提权时自动请求）
#   pwsh bootstrap.ps1 -ValidateOnly  # 只做无副作用校验
#   pwsh bootstrap.ps1 -NoElevate     # 不请求提权，只跑用户级阶段
[CmdletBinding()]
param(
    [switch]$ValidateOnly,
    [switch]$NoElevate
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
$logFile = Join-Path $logDir ("bootstrap-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
try { Start-Transcript -Path $logFile -ErrorAction SilentlyContinue | Out-Null } catch { }

function Invoke-Stage {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$Body
    )
    Write-Phase $Name
    $ok = $true
    try { $ok = & $Body } catch {
        Write-Step $Name 'FAIL' $_.Exception.Message
        $ok = $false
    }
    $script:Stages.Add([pscustomobject]@{ Name = $Name; Ok = $ok })
    return $ok
}

# ---------------------------------------------------------------------------
# Stage 0/4 · Preflight 预检
# ---------------------------------------------------------------------------
$elevated = $false
$null = Invoke-Stage 'Stage 0/5 - Preflight 预检' {
    $script:elevated = Test-IsElevated
    if ($elevated) { Write-Step '提权状态' 'OK' '管理员 - 全部阶段可执行' }
    else { Write-Step '提权状态' 'SKIP' '普通用户 - HKLM 注册表与全机安装将受限' }
    Write-Step '工作目录' 'INFO' $PSScriptRoot
    return $true
}

# 未提权且需要完整收敛时：自动请求提权重启（交互场景一次 UAC）
if (-not $elevated -and -not $ValidateOnly -and -not $NoElevate) {
    Write-Phase '提权'
    $relaunchArgs = @('-NoExit', '-File', "`"$PSCommandPath`"")
    if ($ValidateOnly) { $relaunchArgs += '-ValidateOnly' }
    try {
        Start-Process pwsh -Verb RunAs -ArgumentList $relaunchArgs
        Write-Step '提权重启' 'OK' '已在新的管理员窗口继续，本窗口可关闭'
        exit 0
    } catch {
        Write-Step '提权重启' 'FAIL' '被取消或不可用。可重试，或用 -NoElevate 只跑用户级阶段'
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Stage 1/5 · Validate 无副作用校验
# ---------------------------------------------------------------------------
$null = Invoke-Stage 'Stage 1/5 - Validate 无副作用校验' {
    # 子进程 stdout 不入本阶段返回值：显式转发到 Host，返回值只留 bool
    $out = & pwsh -NoProfile -File (Join-Path $PSScriptRoot 'validate.ps1') 2>&1
    $out | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -eq 0) { return $true }
    Write-Step '校验' 'FAIL' 'validate.ps1 未通过，中止后续阶段'
    return $false
}

# ---------------------------------------------------------------------------
# Stage 2/5 · Apply 应用声明配置（winget configure，按依赖序：设置 -> 软件）
# ---------------------------------------------------------------------------
$null = Invoke-Stage 'Stage 2/5 - Apply 应用声明配置' {
    if ($ValidateOnly) { Write-Step '应用配置' 'SKIP' '-ValidateOnly 模式不执行'; return $true }
    if (-not $elevated) {
        Write-Step '应用配置' 'SKIP' '需要管理员；本阶段已跳过（其余用户级阶段继续）'
        return $true
    }
    $domainOrder = 'base-windows', 'cli-tools', 'editors', 'languages'
    $allOk = $true
    foreach ($domain in $domainOrder) {
        $file = Join-Path $PSScriptRoot "configs/$domain.winget"
        if (-not (Test-Path $file)) { Write-Step $domain 'SKIP' '尚未创建（后续工单）'; continue }
        $out = & winget configure --file $file --accept-configuration-agreements --disable-interactivity 2>&1
        $code = $LASTEXITCODE
        $out | ForEach-Object { Write-Host $_ }
        if ($code -eq 0) { Write-Step $domain 'OK' }
        else { Write-Step $domain 'FAIL' "winget configure 退出码 $code"; $allOk = $false }
    }
    return $allOk
}

# ---------------------------------------------------------------------------
# Stage 3/5 · 用户级安装（vp + VSCode 扩展；无需提权）
# ---------------------------------------------------------------------------
$null = Invoke-Stage 'Stage 3/5 - 用户级安装（vp + VSCode 扩展）' {
    if ($ValidateOnly) { Write-Step '用户级安装' 'SKIP' '-ValidateOnly 模式不执行'; return $true }
    $allOk = $true
    foreach ($s in 'install-languages.ps1', 'install-vscode-extensions.ps1') {
        $out = & pwsh -NoProfile -File (Join-Path $PSScriptRoot "scripts/$s") 2>&1
        $code = $LASTEXITCODE
        $out | ForEach-Object { Write-Host $_ }
        if ($code -eq 0) { Write-Step $s 'OK' } else { Write-Step $s 'FAIL' "退出码 $code"; $allOk = $false }
    }
    return $allOk
}

# ---------------------------------------------------------------------------
# Stage 4/5 · 移除清单（先装后拆：languages 已就位后才清旧轨）
# ---------------------------------------------------------------------------
$null = Invoke-Stage 'Stage 4/5 - 移除清单（先装后拆）' {
    if ($ValidateOnly) { Write-Step '移除清单' 'SKIP' '-ValidateOnly 模式不执行'; return $true }
    $out = & pwsh -NoProfile -File (Join-Path $PSScriptRoot 'scripts/remove-leftovers.ps1') 2>&1
    $code = $LASTEXITCODE
    $out | ForEach-Object { Write-Host $_ }
    if ($code -eq 0) { Write-Step '移除清单' 'OK'; return $true }
    Write-Step '移除清单' 'FAIL' "退出码 $code"; return $false
}

# ---------------------------------------------------------------------------
# Stage 5/6 · WSL 侧（安装编排 + 发行版内环境）
# ---------------------------------------------------------------------------
$null = Invoke-Stage 'Stage 5/6 - WSL 侧（安装编排 + 发行版环境）' {
    if ($ValidateOnly) { Write-Step 'WSL' 'SKIP' '-ValidateOnly 模式不执行'; return $true }
    # wsl.exe 在提权上下文里经管道捕获输出会挂起（已知问题），而 WSL 阶段本身无需提权：
    # 提权跑时跳过，收尾后用 `pwsh bootstrap.ps1 -NoElevate` 补齐
    if ($elevated) {
        Write-Step 'WSL' 'SKIP' '提权上下文跳过（wsl.exe 已知挂起问题；此阶段无需提权）——请稍后运行 pwsh bootstrap.ps1 -NoElevate 补齐'
        return $true
    }
    $allOk = $true
    foreach ($s in 'install-wsl.ps1', 'install-wsl-env.ps1') {
        $out = & pwsh -NoProfile -File (Join-Path $PSScriptRoot "scripts/$s") 2>&1
        $code = $LASTEXITCODE
        $out | ForEach-Object { Write-Host $_ }
        if ($code -eq 0) { Write-Step $s 'OK' } else { Write-Step $s 'FAIL' "退出码 $code"; $allOk = $false }
    }
    return $allOk
}

# ---------------------------------------------------------------------------
# Stage 6/6 · Dotfiles 安装
# ---------------------------------------------------------------------------
$null = Invoke-Stage 'Stage 6/6 - Dotfiles 安装' {
    $installer = Join-Path $PSScriptRoot 'scripts/install-dotfiles.ps1'
    if (-not (Test-Path $installer)) {
        Write-Step 'dotfiles' 'SKIP' 'install-dotfiles.ps1 尚未创建（工单 02）'
        return $true
    }
    $out = & pwsh -NoProfile -File $installer 2>&1
    $code = $LASTEXITCODE
    $out | ForEach-Object { Write-Host $_ }
    if ($code -eq 0) { Write-Step 'dotfiles' 'OK'; return $true }
    Write-Step 'dotfiles' 'FAIL' "退出码 $code"; return $false
}

# ---------------------------------------------------------------------------
# Stage 4/4 · Summary 汇总
# ---------------------------------------------------------------------------
Write-Phase 'Summary 汇总'
$failed = @($script:Stages | Where-Object { -not $_.Ok })
foreach ($s in $script:Stages) {
    Write-Step $s.Name ($s.Ok ? 'OK' : 'FAIL')
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

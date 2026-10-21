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

function Get-VpPin {
    # vp 版本钉子的唯一来源（configs/vp-version）：Windows 侧 install-languages、WSL 侧 setup-ubuntu.sh、
    # verify-machine 断言三方共读，升级 vp 只改这一个文件（吸收账本记一笔）
    $p = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'configs/vp-version'
    return (Get-Content $p -Raw).Trim()
}

function Get-VpWinExe {
    # Windows 侧 vp 的绝对路径探测：新装会话 PATH 可能未含 vite-plus\bin，不能依赖 Get-Command。
    # 两种官方布局都认（工单12）：单体 ~/.vite-plus（安装器默认/复用现有安装）与 LOCALAPPDATA\vite-plus（选根模式）；未找到返回 $null
    @(
        (Join-Path $env:USERPROFILE '.vite-plus\bin\vp.exe')
        (Join-Path $env:LOCALAPPDATA 'vite-plus\bin\vp.exe')
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
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

function Get-WslDistros {
    # wsl -l -q 的干净输出（剥 UTF-16 NUL；wsl.exe 未就位/无发行版时为空数组）
    @((& wsl.exe -l -q) 2>$null | ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ })
}

function Get-WslDefaultUser {
    # 发行版默认用户探测（whoami；硬编码用户名会误伤默认用户不同的机器，工单12族）；探不到返回 $null
    param([string]$Distro = 'Ubuntu')
    $u = ((& wsl.exe -d $Distro -e bash -c 'whoami') 2>$null) -replace "`0", ''
    @($u | ForEach-Object { $_.Trim() } | Where-Object { $_ }) | Select-Object -First 1
}

function Invoke-WslScript {
    # 在发行版内以 bash 跑一个脚本（可带参数）：返回 Lines（剥 NUL 的干净输出）/ Exit / Ok。
    # 已知坑①：提权上下文经管道捕获 wsl.exe 输出会挂死——提权回合勿调（bootstrap Stage 6 已守卫跳过 WSL）
    param(
        [Parameter(Mandatory)][string]$Distro,
        [string]$User,
        [Parameter(Mandatory)][string]$Script,
        [string[]]$ScriptArgs = @()
    )
    $a = @('-d', $Distro)
    if ($User) { $a += @('-u', $User) }
    $a += @('-e', 'bash', $Script) + $ScriptArgs
    $lines = ((& wsl.exe @a) 2>&1) | ForEach-Object { $_ -replace "`0", '' }
    [pscustomobject]@{ Lines = @($lines); Exit = $LASTEXITCODE; Ok = ($LASTEXITCODE -eq 0) }
}

function ConvertTo-WslPath {
    # Windows 绝对路径 → WSL 视角（D:\x\y → /mnt/d/x/y；仅盘符路径形态，本仓库使用面内够用）
    param([Parameter(Mandatory)][string]$Path)
    $p = $Path.Replace('/', '\')
    "/mnt/$($p.Substring(0, 1).ToLower())/$($p.Substring(3).Replace('\', '/'))"
}

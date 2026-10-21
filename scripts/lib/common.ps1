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

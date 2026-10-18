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

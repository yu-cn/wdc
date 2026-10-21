# bootstrap.ps1 - WDC 开发环境唯一入口（GLOSSARY: bootstrap）——Windows PowerShell 5.1 兼容引导层
# 裸 Windows 只有 5.1：本层负责定位 PowerShell 7（缺失则 winget 用户级自动安装，无需管理员），
# 随后原样带参转发给 bootstrap-main.ps1。已有 PS7 的机器行为不变。
# 用法（cmd / PowerShell / Git Bash 均可）：
#   powershell -ExecutionPolicy Bypass -File bootstrap.ps1   # 裸机推荐，缺 PS7 时自动装
#   pwsh bootstrap.ps1 / -ValidateOnly / -NoElevate          # 已有 PS7 时照旧
# 约束：本文件必须保持 5.1 可解析——禁用三元/??/&& 等 PS7 语法；含中文字符串，需 UTF-8 BOM
[CmdletBinding()]
param(
    [switch]$ValidateOnly,
    [switch]$NoElevate,
    [switch]$ElevatedPass   # 内部参数：与 main 保持一致，原样转发
)
$ErrorActionPreference = 'Stop'
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch { }
$mainScript = Join-Path $PSScriptRoot 'bootstrap-main.ps1'

function Get-PwshExe {
    $cmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidates = @()
    if ($env:ProgramFiles) { $candidates += (Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe') }
    if ($env:LOCALAPPDATA) { $candidates += (Join-Path $env:LOCALAPPDATA 'Microsoft\PowerShell\7\pwsh.exe') }
    foreach ($p in $candidates) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host '[bootstrap] 当前为 Windows PowerShell 5.1 —— 确认 PowerShell 7 运行时…'
    $pwshExe = Get-PwshExe
    if (-not $pwshExe) {
        if ($ValidateOnly) {
            Write-Host '[bootstrap] -ValidateOnly 是无副作用模式，不自动安装 PowerShell 7。先跑一次完整 bootstrap，或手动：winget install Microsoft.PowerShell' -ForegroundColor Yellow
            exit 1
        }
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Host '[bootstrap] 未找到 pwsh 与 winget（App Installer）——请先从微软商店安装「应用安装程序」后重试' -ForegroundColor Yellow
            exit 1
        }
        Write-Host '[bootstrap] 未检测到 PowerShell 7 —— winget 用户级安装（无需管理员，约 1-2 分钟）…'
        & winget install -e --id Microsoft.PowerShell --source winget --scope user --accept-package-agreements --accept-source-agreements --disable-interactivity
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[bootstrap] PowerShell 7 安装失败（winget 退出码 $LASTEXITCODE）——可手动安装后重试" -ForegroundColor Yellow
            exit 1
        }
        $pwshExe = Get-PwshExe
        if (-not $pwshExe) {
            Write-Host '[bootstrap] 安装完成但仍未定位到 pwsh.exe —— 请重开终端后再跑一次' -ForegroundColor Yellow
            exit 1
        }
    }
    # winget 安装不会刷新本进程 PATH：注入后，main 及其提权/校验子进程都能解析到 pwsh
    $env:Path = (Split-Path $pwshExe) + ';' + $env:Path
    Write-Host "[bootstrap] PowerShell 7 就位（$pwshExe），切换运行时继续"
}

# 参数原样转发（switch 还原为字符串，-File 调用下由 main 重新绑定）
$fwd = @()
if ($ValidateOnly) { $fwd += '-ValidateOnly' }
if ($NoElevate)    { $fwd += '-NoElevate' }
if ($ElevatedPass) { $fwd += '-ElevatedPass' }
& pwsh -NoProfile -ExecutionPolicy Bypass -File $mainScript @fwd
exit $LASTEXITCODE

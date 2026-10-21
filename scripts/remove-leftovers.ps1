#Requires -Version 7
# remove-leftovers.ps1 — 移除清单执行器（GLOSSARY: 移除清单 / 机器自留地）
# 原则：只动清单内的东西，清单外一概不碰；幂等；需提权的项未提权时报 SKIP 而非失败。
# 前置约定：由 bootstrap 在「新轨已就位」（languages 已装）之后调用——先装后拆。
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/common.ps1')

$elevated = Test-IsElevated
$pendingElevation = 0

function Test-WingetInstalled {
    # 按精确 ID 探测失败时按名称兜底（部分包的已装记录与官方 ID 关联不上）
    param([Parameter(Mandatory)][string]$Id, [string]$NamePattern)
    $null = winget list --id $Id -e --accept-source-agreements --disable-interactivity 2>$null
    if ($LASTEXITCODE -eq 0) { return $true }
    if ($NamePattern) {
        $lines = winget list --name $NamePattern --accept-source-agreements --disable-interactivity 2>$null
        return ($LASTEXITCODE -eq 0)
    }
    return $false
}

function Remove-WingetPackage {
    param([Parameter(Mandatory)][string]$Id, [string]$NamePattern, [switch]$NeedsElevation)
    $label = if ($NamePattern) { "$Id ($NamePattern)" } else { $Id }
    if (-not (Test-WingetInstalled -Id $Id -NamePattern $NamePattern)) {
        Write-Step $label 'OK' '不存在（无需处理）'
        return
    }
    if ($NeedsElevation -and -not $elevated) {
        Write-Step $label 'SKIP' '需要管理员——提权重跑 bootstrap 时执行'
        $script:pendingElevation++
        return
    }
    # 多版本并存时 --id -e/--name 匹配歧义（本机 .NET SDK 双版本 → 0x8A150014）：逐版本显式卸载
    $installed = @(winget list --id $Id -e --accept-source-agreements 2>$null |
        Where-Object { $_ -match [regex]::Escape($Id) })
    $allOk = $installed.Count -gt 0
    foreach ($line in $installed) {
        if ($line -notmatch '(\d+(\.\d+)+)') { continue }
        $ver = $Matches[1]
        winget uninstall --id $Id -e --version $ver --silent --accept-source-agreements 2>$null
        if ($LASTEXITCODE -eq 0) { Write-Step $label 'CHANGED' "已卸载 $ver" }
        else { Write-Step $label 'SKIP' "$ver 卸载退出码 $LASTEXITCODE（提权重跑时自动完成）"; $allOk = $false }
    }
    if (-not $allOk) { $script:pendingElevation++ }
}

# ---------------------------------------------------------------------------
# 1/5 · Windows Terminal fragments（上游 wsl-comfort / dev-config 的注入物，用户级）
# ---------------------------------------------------------------------------
Write-Phase '移除清单 1/5 - WT fragments'
$fragRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments'
foreach ($frag in 'ComfortShell', 'DevConfig') {
    $p = Join-Path $fragRoot $frag
    if (Test-Path $p) {
        Remove-Item -Path $p -Recurse -Force
        Write-Step "fragment $frag" 'CHANGED' '已删除（配色/profile 已由仓库 terminal-settings 接管）'
    } else {
        Write-Step "fragment $frag" 'OK' '不存在'
    }
}
# 本仓已退役的 WSL profile 片段渲染机制残留（ADR-0006）：官方路径与旧包内路径两处，幂等清理
$wtLocal = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'
foreach ($p in @(
    (Join-Path $fragRoot 'WDC'),
    (Join-Path $wtLocal 'fragments\wdc-wsl.json')
)) {
    if (Test-Path $p) {
        Remove-Item -Path $p -Recurse -Force
        Write-Step "退役片段 $p" 'CHANGED' '已删除（ADR-0006：WSL profile 改模板静态声明）'
    }
}

# ---------------------------------------------------------------------------
# 2/5 · VSCode 商店 MSIX 版（收敛为 winget 用户版单份；当前用户卸载，无需提权）
# ---------------------------------------------------------------------------
Write-Phase '移除清单 2/5 - VSCode 商店版'
$msix = Get-AppxPackage -Name 'Microsoft.VisualStudioCode' -ErrorAction SilentlyContinue
if ($msix) {
    $msix | Remove-AppxPackage
    Write-Step 'VSCode MSIX' 'CHANGED' '商店版已卸载（用户数据与 winget 版独立，互不影响）'
} else {
    Write-Step 'VSCode MSIX' 'OK' '不存在'
}

# ---------------------------------------------------------------------------
# 3/5 · 提示符旧引擎：Oh My Posh（Starship 已接管三 shell）
# ---------------------------------------------------------------------------
Write-Phase '移除清单 3/5 - Oh My Posh'
Remove-WingetPackage -Id 'JanDeDobbeleer.OhMyPosh' -NeedsElevation

# ---------------------------------------------------------------------------
# 4/5 · Node/Python 旧轨（新轨：vp / uv 均已就位）
# ---------------------------------------------------------------------------
Write-Phase '移除清单 4/5 - Node/Python 旧轨'
Remove-WingetPackage -Id 'OpenJS.NodeJS' -NamePattern 'Node.js' -NeedsElevation
Remove-WingetPackage -Id 'Python.Python.3.13' -NamePattern 'Python 3.13' -NeedsElevation

# nvm-windows：卸载器 + NVM_HOME 目录 + symlink + 用户环境变量
$nvmHome = [Environment]::GetEnvironmentVariable('NVM_HOME', 'User')
$nvmSymlink = [Environment]::GetEnvironmentVariable('NVM_SYMLINK', 'User')
if ($nvmHome -and (Test-Path $nvmHome)) {
    $uninstaller = Get-ChildItem $nvmHome -Filter 'unins*.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($uninstaller) {
        if ($elevated) {
            Start-Process -FilePath $uninstaller.FullName -ArgumentList '/SILENT' -Wait
            Write-Step 'nvm-windows' 'CHANGED' '已运行静默卸载'
        } else {
            Write-Step 'nvm-windows' 'SKIP' '卸载器需要提权——提权重跑时执行'
            $pendingElevation++
        }
    } else {
        Write-Step 'nvm-windows' 'SKIP' "找到 NVM_HOME=$nvmHome 但无卸载器，请手动处理"
    }
} else {
    Write-Step 'nvm-windows' 'OK' '未安装（无 NVM_HOME）'
}
# 环境变量与残留 symlink 的清理（用户级，随时可做）
foreach ($v in 'NVM_HOME', 'NVM_SYMLINK') {
    if ([Environment]::GetEnvironmentVariable($v, 'User')) {
        [Environment]::SetEnvironmentVariable($v, $null, 'User')
        Write-Step "环境变量 $v" 'CHANGED' '已从用户环境移除'
    }
}
if (Test-Path 'C:\nvm4w') {
    if ($elevated) {
        Remove-Item 'C:\nvm4w' -Force -Recurse -ErrorAction SilentlyContinue
        Write-Step 'C:\nvm4w' 'CHANGED' '残留 symlink 已删除'
    } else {
        Write-Step 'C:\nvm4w' 'SKIP' '根目录 symlink 删除需要提权'
        $pendingElevation++
    }
}
# nvm 主目录（用户级；若被仍在运行的旧 node 进程占用则提示重启后重跑）
$nvmAppDir = Join-Path $env:LOCALAPPDATA 'nvm'
if (Test-Path $nvmAppDir) {
    Remove-Item $nvmAppDir -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path $nvmAppDir) {
        Write-Step 'nvm 目录' 'SKIP' '删除失败（多半被运行中的旧 node 占用）——重启后重跑 bootstrap 即清'
    } else {
        Write-Step 'nvm 目录' 'CHANGED' '已删除'
    }
} else {
    Write-Step 'nvm 目录' 'OK' '不存在'
}

# ---------------------------------------------------------------------------
# 5/5 · .NET 旧轨（用户完全不用 .NET 开发；Desktop 运行时明确保留——PowerToys 等依赖）
# ---------------------------------------------------------------------------
Write-Phase '移除清单 5/5 - .NET SDK 与 ASP.NET 运行时'
Remove-WingetPackage -Id 'Microsoft.DotNet.SDK.10' -NamePattern '.NET SDK' -NeedsElevation
Remove-WingetPackage -Id 'Microsoft.DotNet.AspNetCore.10' -NeedsElevation
Write-Step '.NET Desktop 运行时' 'OK' '明确保留（应用依赖）'

Write-Phase '移除清单汇总'
if ($pendingElevation -eq 0) { Write-Step '移除清单' 'OK' '全部完成'; exit 0 }
else {
    Write-Step '移除清单' 'CHANGED' "$pendingElevation 项待提权执行（提权重跑 bootstrap 自动完成）"
    exit 0
}

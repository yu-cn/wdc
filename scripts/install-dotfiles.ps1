#Requires -Version 7
# install-dotfiles.ps1 — dotfiles 层安装器（GLOSSARY: dotfiles / 身份文件）
# 职责：身份文件（迁移或占位）+ Windows 侧符号链接。WSL 侧由 WSL 阶段负责。
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/common.ps1')
. (Join-Path $PSScriptRoot 'lib/dotfiles-map.ps1')

$repoRoot = Split-Path $PSScriptRoot -Parent
$dotfilesRoot = Join-Path $repoRoot 'dotfiles'

function Get-BackupPath {
    param([Parameter(Mandatory)][string]$Path)
    $bak = "$Path.bak"
    if (-not (Test-Path $bak)) { return $bak }
    $i = 1
    while (Test-Path "$Path.bak.$i") { $i++ }
    return "$Path.bak.$i"
}

function Install-Dotfile {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Target
    )
    $leaf = Split-Path $Target -Leaf
    if (-not (Test-Path $Source)) { Write-Step $leaf 'SKIP' "仓库内源文件缺失：$Source"; return }
    $targetDir = Split-Path $Target -Parent
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Write-Step $leaf 'CHANGED' "创建目录 $targetDir"
    }
    if (Test-Path $Target) {
        $item = Get-Item $Target
        if ($item.LinkType -eq 'SymbolicLink' -and $item.Target -eq $Source) {
            Write-Step $leaf 'OK' '已是本仓库符号链接'
            return
        }
        $bak = Get-BackupPath $Target
        Move-Item -Path $Target -Destination $bak
        Write-Step $leaf 'CHANGED' "旧文件备份为 $(Split-Path $bak -Leaf)"
    }
    New-Item -ItemType SymbolicLink -Path $Target -Value $Source | Out-Null
    Write-Step $leaf 'CHANGED' "已链接 -> $Source"
}

# ---------------------------------------------------------------------------
# 1/3 · 身份文件（~/.gitidentity）
# ---------------------------------------------------------------------------
Write-Phase 'Dotfiles 1/3 - 身份文件（~/.gitidentity）'
$identityPath = Join-Path $HOME '.gitidentity'
if (Test-Path $identityPath) {
    Write-Step '.gitidentity' 'OK' '已存在'
} else {
    $existingGitconfig = Join-Path $HOME '.gitconfig'
    $name = $null; $email = $null
    if (Test-Path $existingGitconfig) {
        $name  = git config --file $existingGitconfig --get user.name
        $email = git config --file $existingGitconfig --get user.email
    }
    if ($name -and $email) {
        Set-Content -Path $identityPath -Encoding utf8 -Value "[user]`n    name = $name`n    email = $email`n"
        Write-Step '.gitidentity' 'CHANGED' "已从现有 .gitconfig 迁移身份（$name）"
    } else {
        Set-Content -Path $identityPath -Encoding utf8 -Value @(
            '# 身份文件——每台机器填写一次本机 git 身份（此文件不入仓库）'
            '# 未填写时 git 会拒绝提交（防错护栏：防止用错身份）'
            '[user]'
            '    name = '
            '    email = '
        )
        Write-Step '.gitidentity' 'CHANGED' '已生成占位；请编辑填写 name/email'
    }
}

# ---------------------------------------------------------------------------
# 2/3 · Windows 侧符号链接
# ---------------------------------------------------------------------------
Write-Phase 'Dotfiles 2/3 - Windows 侧符号链接'
# 落点清单来自 Get-DotfilesMap 单一来源（verify 断言与 inventory 盘点同读一份，防三面漂移）
foreach ($m in (Get-DotfilesMap)) {
    Install-Dotfile -Source (Join-Path $dotfilesRoot $m.Source) -Target $m.Target
}

# Ubuntu 图标资产（ADR-0006）：仓库持有，装到每机相同的固定位置；模板经 %LOCALAPPDATA% 展开引用，
# 图标路径不含任何机器派生值（发行版 GUID 派生的 wsl 官方路径不可入模板）
$iconDir = Join-Path $env:LOCALAPPDATA 'wdc'
$iconDst = Join-Path $iconDir 'ubuntu.ico'
$iconSrc = Join-Path $dotfilesRoot 'windows\ubuntu.ico'
if (Test-Path $iconDst) { Write-Step 'ubuntu.ico' 'OK' '已在位' }
else {
    New-Item -ItemType Directory -Path $iconDir -Force | Out-Null
    Copy-Item $iconSrc $iconDst
    Write-Step 'ubuntu.ico' 'CHANGED' "已安装 -> $iconDst"
}

# ~/.wdc：机器本地仓库路径指针（wdc 一键同步命令用；路径因机而异不入库，ADR-0004 模式）
$wdcPtr = Join-Path $HOME '.wdc'
if (-not (Test-Path $wdcPtr) -or ((Get-Content $wdcPtr -Raw -ErrorAction SilentlyContinue).Trim() -ne $repoRoot)) {
    Set-Content -Path $wdcPtr -Encoding ascii -Value $repoRoot
    Write-Step '.wdc' 'CHANGED' "仓库路径指针已写入（wdc 命令用）"
} else { Write-Step '.wdc' 'OK' '已是本仓库路径' }

# ---------------------------------------------------------------------------
# 3/3 · WSL 侧（占位说明）
# ---------------------------------------------------------------------------
Write-Phase 'Dotfiles 3/3 - WSL 侧'
Write-Step 'WSL dotfiles' 'SKIP' '由 WSL 阶段负责（bashrc / gitconfig / starship 链接进 Ubuntu）'
exit 0

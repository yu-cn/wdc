#Requires -Version 7
# install-dotfiles.ps1 — dotfiles 层安装器（GLOSSARY: dotfiles / 身份文件）
# 职责：身份文件（迁移或占位）+ Windows 侧符号链接。WSL 侧由 WSL 阶段负责。
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/common.ps1')

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
$docs = [Environment]::GetFolderPath('MyDocuments')
$wtSettings = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
$map = @(
    @{ Source = 'windows/gitconfig';               Target = (Join-Path $HOME '.gitconfig') },
    @{ Source = 'windows/bashrc';                  Target = (Join-Path $HOME '.bashrc') },
    @{ Source = 'windows/pwsh-profile.ps1';        Target = (Join-Path $docs 'PowerShell\Microsoft.PowerShell_profile.ps1') },
    @{ Source = 'windows/vscode-settings.json';    Target = (Join-Path $env:APPDATA 'Code\User\settings.json') },
    @{ Source = 'windows/vscode-keybindings.json'; Target = (Join-Path $env:APPDATA 'Code\User\keybindings.json') },
    @{ Source = 'windows/terminal-settings.json';  Target = $wtSettings },
    @{ Source = 'shared/starship.toml';            Target = (Join-Path $HOME '.config\starship.toml') }
)
foreach ($m in $map) {
    Install-Dotfile -Source (Join-Path $dotfilesRoot $m.Source) -Target $m.Target
}

# ---------------------------------------------------------------------------
# 3/3 · WSL 侧（占位说明）
# ---------------------------------------------------------------------------
Write-Phase 'Dotfiles 3/3 - WSL 侧'
Write-Step 'WSL dotfiles' 'SKIP' '由 WSL 阶段负责（bashrc / gitconfig / starship 链接进 Ubuntu）'
exit 0

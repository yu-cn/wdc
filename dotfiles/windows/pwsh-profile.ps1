# Microsoft.PowerShell_profile.ps1 — WDC 统一 pwsh 配置（仓库 dotfiles 管理）
# 原则：所有初始化均带存在性守卫——未完成 bootstrap 的机器上打开终端不报错

# --- vp 的 Node 环境（vp 由 languages 域安装；env.ps1 由 vp 安装器生成）---
if (Test-Path "$env:APPDATA\vite-plus\env.ps1") { . "$env:APPDATA\vite-plus\env.ps1" }

# --- PSReadLine：历史去重 + 预测式补全（输出重定向等场景下静默跳过）---
try {
    Set-PSReadLineOption -HistoryNoDuplicates -PredictionSource History -EditMode Windows -ErrorAction SilentlyContinue
} catch { }

# --- zoxide：z 智能跳目录（与 bash 侧同款）---
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# --- fzf：Ctrl-R 搜历史 / Ctrl-T 选文件 / Alt-C 跳目录（与 bash 侧同款）---
# 老版本 fzf 不支持 --powershell：输出为空则跳过，不报错（机器无关的防御）
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    $__fzfInit = (& fzf --powershell 2>$null) -join "`n"
    if ($__fzfInit) { Invoke-Expression $__fzfInit }
}

# --- starship 提示符（最后初始化；三 shell 共用 ~/.config/starship.toml）---
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# --- git 快捷方式（与 bash 侧 gs/gl/gd/gco 同义）---
function gs { git status -sb }
function gl { git log --oneline --graph --decorate -20 }
function gd { git diff }
function gco { param([string]$Branch) git checkout $Branch }

# --- wdc：一键同步（pull → bootstrap → verify；仓库路径由 ~/.wdc 提供，bootstrap 自动写入）---
function wdc {
    $repo = (Get-Content "$HOME\.wdc" -ErrorAction SilentlyContinue | Select-Object -First 1)
    if (-not $repo -or -not (Test-Path (Join-Path $repo 'bootstrap.ps1'))) {
        Write-Host 'wdc: 未配置仓库路径——先在仓库跑一次 bootstrap（会自动写 ~/.wdc）' -ForegroundColor Yellow
        return
    }
    git -C $repo pull
    if ($LASTEXITCODE -ne 0) { Write-Host 'wdc: git pull 失败，中止' -ForegroundColor Red; return }
    pwsh -NoProfile -File (Join-Path $repo 'bootstrap.ps1')
    if ($LASTEXITCODE -ne 0) { Write-Host 'wdc: bootstrap 未全绿，跳过 verify（先排障，日志在 logs/）' -ForegroundColor Red; return }
    pwsh -NoProfile -File (Join-Path $repo 'scripts/verify-machine.ps1')
}

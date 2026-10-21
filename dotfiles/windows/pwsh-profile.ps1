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

# --- wdc：一键工具（薄包装；全部逻辑在仓库 scripts/wdc.ps1，工单 20——单一来源防漂移）---
function wdc {
    $repo = (Get-Content "$HOME\.wdc" -ErrorAction SilentlyContinue | Select-Object -First 1)
    if (-not $repo -or -not (Test-Path (Join-Path $repo 'scripts\wdc.ps1'))) {
        Write-Host 'wdc: 未配置仓库路径——先在仓库跑一次 bootstrap（会自动写 ~/.wdc）' -ForegroundColor Yellow
        return
    }
    & pwsh -NoProfile -File (Join-Path $repo 'scripts\wdc.ps1') @args
}

# --- dotfiles 漂移即时提示（工单24）：写穿/未提交模板开新终端即见——红线「提交前核对无漂移」的自动守卫 ---
# --no-optional-locks：不与并行运行的 lazygit/starship 抢 index 锁（只读探测的标准姿势）
$__wdcRepo = Get-Content "$HOME\.wdc" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($__wdcRepo -and (Test-Path (Join-Path $__wdcRepo 'dotfiles'))) {
    $__drift = @(git --no-optional-locks -C "$__wdcRepo" status --porcelain -- dotfiles/).Count
    if ($__drift -gt 0) { Write-Host "wdc: dotfiles 漂移 ${__drift} 处——commit 吸收或 wdc triage 处置" -ForegroundColor Yellow }
}
Remove-Variable __wdcRepo, __drift -ErrorAction SilentlyContinue

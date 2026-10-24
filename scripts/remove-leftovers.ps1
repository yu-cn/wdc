#Requires -Version 7
# remove-leftovers.ps1 — 移除清单执行器（GLOSSARY: 移除清单 / 机器自留地）
# 语义（ADR-0007）：清单只含两类——自清理（本仓自己的注入物）与迁移冲突（与声明安装真冲突的项）。
# 主人机史项（Oh My Posh / 语言栈 / nvm / .NET / WSL Go）已全部退出：对公众机器无卸载面，
# 主人机上亦已收敛完毕。原则：只动清单内的东西，清单外一概不碰；幂等；全用户级，无需提权。
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/common.ps1')

# ---------------------------------------------------------------------------
# 1/2 · WT fragments（上游 wsl-comfort / dev-config 的注入物 + 本仓退役机制残留，用户级）
# ---------------------------------------------------------------------------
Write-Phase '移除清单 1/2 - WT fragments'
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
# 2/2 · VSCode 商店 MSIX 版（迁移冲突：不卸则双 VSCode 并存；用户级卸载，无需提权）
# ---------------------------------------------------------------------------
Write-Phase '移除清单 2/2 - VSCode 商店版'
# 只拦 Store 签名的商店版；VSCode 自更新注册的 Developer 签名 identity 包不碰（坑13：卸了随自更新回归）
$msix = Get-AppxPackage -Name 'Microsoft.VisualStudioCode' -ErrorAction SilentlyContinue |
    Where-Object SignatureKind -eq 'Store'
if ($msix) {
    $msix | Remove-AppxPackage
    Write-Step 'VSCode MSIX' 'CHANGED' '商店版已卸载（用户数据与 winget 版独立，互不影响）'
} else {
    Write-Step 'VSCode MSIX' 'OK' '不存在（VSCode 自身 identity 包非商店版，不处理）'
}

Write-Phase '移除清单汇总'
Write-Step '移除清单' 'OK' '全部完成'
exit 0

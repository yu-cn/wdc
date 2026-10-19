#Requires -Version 7
# install-languages.ps1 — 编排层：语言版本管理器（vp）安装与 Node 默认版本设定
# 用户级操作，无需提权。uv 本体由 cli-tools 域声明安装（winget），此脚本只管 vp 与其默认值。
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/common.ps1')

# vp 版本钉子：升级 vp 时改这一行（吸收账本记一笔）
$vpVersion = '1.3.0'

Write-Phase 'Languages - vp 安装（钉版本）'
# 用绝对路径探测与调用：新装的会话 PATH 可能尚未包含 vite-plus\bin，不能依赖 Get-Command。
# 两种官方布局都认：单体 ~/.vite-plus（安装器默认/复用现有安装）与 LOCALAPPDATA\vite-plus（选根模式）
$vpCandidates = @(
    (Join-Path $env:USERPROFILE '.vite-plus\bin\vp.exe')
    (Join-Path $env:LOCALAPPDATA 'vite-plus\bin\vp.exe')
)
$vpExe = $vpCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($vpExe) {
    $installed = (& $vpExe --version) 2>$null
    if ($installed -match [regex]::Escape($vpVersion)) {
        Write-Step 'vp' 'OK' "已安装 $installed（与钉子一致）"
    } else {
        Write-Step 'vp' 'CHANGED' "已装 $installed，钉子为 $vpVersion —— 重跑官方安装器升级到钉子版本"
        $env:VP_VERSION = $vpVersion
        Invoke-RestMethod https://vite.plus/ps1 | Invoke-Expression
    }
} else {
    $env:VP_VERSION = $vpVersion
    # 官方安装方式（用户指定）：irm 管道。安装器未签名，全新机器首次可能遇 SmartScreen 需放行。
    Invoke-RestMethod https://vite.plus/ps1 | Invoke-Expression
    $vpExe = $vpCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($vpExe) {
        Write-Step 'vp' 'CHANGED' "已安装 $((& $vpExe --version) 2>$null)（VP_VERSION=$vpVersion）"
    } else {
        Write-Step 'vp' 'FAIL' "安装脚本执行后仍找不到 $vpExe"
        exit 1
    }
}

Write-Phase 'Languages - Node 默认版本（vp env default）'
# 默认跟随 LTS：零维护。需要按项目钉版时用 .node-version / .nvmrc / vp env pin，两侧通吃。
& $vpExe env default lts
if ($LASTEXITCODE -ne 0) {
    Write-Step 'vp env default lts' 'FAIL' "退出码 $LASTEXITCODE"
    exit 1
}

# 安装解析出的环境（显式 lts：裸 `vp env install` 在无项目钉版的目录会拒绝）
& $vpExe env install lts
if ($LASTEXITCODE -ne 0) {
    Write-Step 'vp env install' 'FAIL' "退出码 $LASTEXITCODE"
    exit 1
}
Write-Step 'vp env install' 'CHANGED' '已安装解析环境（LTS Node 进 vp 商店）'

# 启用托管模式（node/npm/pnpm 等经 vp shims 解析；system node 由移除清单清掉）
& $vpExe env on
if ($LASTEXITCODE -eq 0) {
    $cur = (& $vpExe env current) 2>$null
    Write-Step 'vp env on' 'OK' "托管模式已启用；当前解析：$((($cur | Select-String 'Version|Mode') -join ' '))"
} else {
    Write-Step 'vp env on' 'FAIL' "退出码 $LASTEXITCODE"
    exit 1
}
exit 0

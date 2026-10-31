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
# 1/3 · WT fragments（上游 wsl-comfort / dev-config 的注入物 + 本仓退役机制残留，用户级）
# ---------------------------------------------------------------------------
Write-Phase '移除清单 1/3 - WT fragments'
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
# 2/3 · vp 退役迁移（迁移冲突：vp→mise 换轨，LDC ADR-0016；用户级，无需提权）
# ---------------------------------------------------------------------------
Write-Phase '移除清单 2/3 - vp 退役迁移'
# 官方未提供卸载命令（安装器无 uninstall 面、CLI 无 self 子命令）——按安装器写入面反向清除：
# 三种布局目录 + 用户 PATH 注入项；pwsh profile 的 env.ps1 source 行随模板重渲染自然消失
foreach ($d in @(
    (Join-Path $env:USERPROFILE '.vite-plus'),
    (Join-Path $env:LOCALAPPDATA 'vite-plus'),
    (Join-Path $env:APPDATA 'vite-plus')
)) {
    if (Test-Path $d) {
        try {
            Remove-Item -Path $d -Recurse -Force -ErrorAction Stop
            Write-Step "vp 目录 $d" 'CHANGED' '已删除（→ mise 迁移，LDC ADR-0016）'
        } catch {
            # 占用不炸阶段（迁移常见形态：应用经 vp node shim 运行——如 ZCode 上下文插件实录）；
            # 重启相关应用/登出重登后重跑 bootstrap 收尾，幂等。PATH 清理不受影响照常执行
            Write-Step "vp 目录 $d" 'FAIL' "占用未删（重启经 vp 运行的应用后重跑 bootstrap 收尾）：$($_.Exception.Message)"
        }
    } else {
        Write-Step "vp 目录 $d" 'OK' '不存在'
    }
}
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$parts = @($userPath -split ';' | Where-Object { $_ -ne '' })
$kept = @($parts | Where-Object { $_ -notlike '*vite-plus*' })
if ($kept.Count -ne $parts.Count) {
    [Environment]::SetEnvironmentVariable('Path', ($kept -join ';'), 'User')
    Write-Step '用户 PATH vite-plus 注入' 'CHANGED' "已清除 $($parts.Count - $kept.Count) 条"
} else {
    Write-Step '用户 PATH vite-plus 注入' 'OK' '无'
}

# ---------------------------------------------------------------------------
# 3/3 · VSCode 商店 MSIX 版（迁移冲突：不卸则双 VSCode 并存；用户级卸载，无需提权）
# ---------------------------------------------------------------------------
Write-Phase '移除清单 3/3 - VSCode 商店版'
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

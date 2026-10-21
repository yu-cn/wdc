#Requires -Version 7
# install-wsl-env.ps1 — WSL 侧发行版内环境编排（工单 07）
# 以 root 跑 apt/Docker/chsh（并移除退出通用核心的 Go，工单21/22），以默认用户跑 uv/vp/dotfiles/身份；全部幂等。
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/common.ps1')

# WSL/Ubuntu 未就位则跳过（install-wsl.ps1 会先处理）
$distros = @((& wsl.exe -l -q) 2>$null | ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ })
if ($distros -notcontains 'Ubuntu') {
    Write-Step 'WSL 环境' 'SKIP' 'Ubuntu 未就位（install-wsl.ps1 先行）'
    exit 0
}

# 仓库路径 -> WSL 视角（D:\x\y -> /mnt/d/x/y）
$repoWin = Split-Path $PSScriptRoot -Parent
$drive = $repoWin.Substring(0, 1).ToLower()
$rest = $repoWin.Substring(3).Replace('\', '/')
$repoWsl = "/mnt/$drive/$rest"

# WSL 默认用户
$wslUser = ((& wsl.exe -d Ubuntu -e bash -c 'whoami') 2>$null) -replace "`0", ''
$wslUser = $wslUser.Trim()
if (-not $wslUser) {
    Write-Step 'WSL 用户' 'FAIL' '无法探测 Ubuntu 默认用户（发行版可能未完成初始化）'
    exit 1
}
$setupSh = "$repoWsl/scripts/wsl/setup-ubuntu.sh"
$winIdentity = "/mnt/c/Users/$env:USERNAME/.gitidentity"

Write-Phase "WSL root 阶段（用户 $wslUser）"
$rootOut = (& wsl.exe -d Ubuntu -u root -e bash $setupSh root $wslUser $repoWsl) 2>&1
$rootOut | ForEach-Object { Write-Host ($_ -replace "`0", '') }
if ($LASTEXITCODE -ne 0) { Write-Step 'root 阶段' 'FAIL' "退出码 $LASTEXITCODE"; exit 1 }
Write-Step 'root 阶段' 'OK' 'apt/gh/Docker/默认shell 完成'

Write-Phase 'WSL user 阶段'
$userOut = (& wsl.exe -d Ubuntu -u $wslUser -e bash $setupSh user $wslUser $repoWsl $winIdentity) 2>&1
$userOut | ForEach-Object { Write-Host ($_ -replace "`0", '') }
if ($LASTEXITCODE -ne 0) { Write-Step 'user 阶段' 'FAIL' "退出码 $LASTEXITCODE"; exit 1 }
Write-Step 'user 阶段' 'OK' 'uv/vp/starship/dotfiles/身份 完成'

# 验证（显式路径探测：非交互 shell 里 bashrc 会提前 return，不能依赖其 PATH；
# vp 两种官方布局都认：单体 ~/.vite-plus（默认）与 ~/.local/share/vite-plus，工单12）
$probeCmd = 'echo "docker:$(/usr/bin/docker --version 2>/dev/null | cut -d" " -f3 || echo MISSING) uv:$(~/.local/bin/uv --version 2>/dev/null | cut -d" " -f2 || echo MISSING) vp:$(if [ -x ~/.vite-plus/bin/vp ] || [ -x ~/.local/share/vite-plus/bin/vp ]; then echo OK; else echo MISSING; fi) node:$(if [ -x ~/.vite-plus/bin/node ]; then ~/.vite-plus/bin/node -v; elif [ -x ~/.local/share/vite-plus/bin/node ]; then ~/.local/share/vite-plus/bin/node -v; else echo MISSING; fi) shell:$(getent passwd $(whoami) | cut -d: -f7)"'
$probe = (& wsl.exe -d Ubuntu -u $wslUser -e bash -c $probeCmd) 2>&1
Write-Step '三件套探测' 'INFO' (($probe -replace "`0", '') -join ' ')
exit 0

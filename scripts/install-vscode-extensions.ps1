#Requires -Version 7
# install-vscode-extensions.ps1 — 编排层：VSCode 扩展安装（幂等；用户级无需提权）
# 为什么不用 DSC 的 VSCodeExtension：实测 validate 阶段即死锁于模块拉取（ADR-0002 的分层原则）
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/common.ps1')

$code = Get-Command code -ErrorAction SilentlyContinue
if (-not $code) {
    Write-Step 'code CLI' 'SKIP' '未找到 VSCode 命令行（editors 域应用后可用）'
    exit 0
}

$listFile = Join-Path (Split-Path $PSScriptRoot -Parent) 'configs\vscode-extensions.txt'
$wanted = @(Get-Content $listFile | Where-Object { $_ -and $_ -notmatch '^\s*#' })

$installed = @(& code --list-extensions 2>$null)

$added = 0
foreach ($ext in $wanted) {
    if ($installed -contains $ext) { continue }
    & code --install-extension $ext --force 2>&1 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -eq 0) { Write-Step $ext 'CHANGED' '已安装'; $added++ }
    else { Write-Step $ext 'FAIL' "code CLI 退出码 $LASTEXITCODE" }
}
Write-Step '扩展清单' 'OK' "目标 $($wanted.Count) 个，新装 $added 个，其余已在位（幂等）"
exit 0

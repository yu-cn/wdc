#Requires -Version 7
# install-wt-profiles.ps1 — WT WSL profile 机器适配渲染（ADR-0004：机器派生值不入库）
# 枚举本机 WSL 发行版（注册表 Lxss），生成 Windows Terminal fragment（机器本地，不入仓库）。
# 仓库模板 settings.json 只存通用内容、不含任何 WSL profile；本脚本每次 bootstrap 重渲染，发行版增减自动跟随。
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/common.ps1')

$wtLocal = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'
if (-not (Test-Path (Join-Path $wtLocal 'settings.json'))) {
    Write-Step 'WT WSL profiles' 'SKIP' 'Windows Terminal 未安装（editors 域应用后可用）'
    exit 0
}

# 发行版清单：HKCU Lxss（id ↔ DistributionName ↔ BasePath），跳过无 DistributionName 的键（docker-desktop 系统发行版/残键）
$distros = @(
    Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' -ErrorAction SilentlyContinue |
        ForEach-Object {
            $p = Get-ItemProperty $_.PSPath
            if ($null -eq $p -or $null -eq $p.PSObject.Properties['DistributionName']) { return }
            [pscustomobject]@{ Id = $_.PSChildName; Name = [string]$p.DistributionName; BasePath = [string]$p.BasePath }
        } |
        Where-Object { $_.Name -and $_.Name -notlike 'docker-desktop*' }
)
if (-not $distros) {
    Write-Step 'WT WSL profiles' 'SKIP' '无 WSL 发行版（install-wsl.ps1 先行）'
    exit 0
}

# 确定性 GUID（v3 风格，名字哈希）：跨机跨次运行稳定，bootstrap 重渲染不换 GUID
function Get-StableGuid {
    param([string]$Seed)
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $b = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Seed))
    $b[7] = ($b[7] -band 0x0F) -bor 0x30
    $b[8] = ($b[8] -band 0x3F) -bor 0x80
    return ([System.Guid]::new($b)).ToString()
}

$profiles = foreach ($d in $distros) {
    # 图标按本机环境派生：新 WSL 的 shortcut.ico 在 %LOCALAPPDATA%\wsl\{id}\，旧版可能挂在 BasePath 下
    $icon = @(
        (Join-Path $env:LOCALAPPDATA "wsl\$($d.Id)\shortcut.ico"),
        (Join-Path $d.BasePath 'shortcut.ico')
    ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
    [ordered]@{
        name              = $d.Name
        guid              = "{0}{1}{2}" -f '{', (Get-StableGuid "wdc-wsl:$($d.Name)"), '}'
        commandline       = "wsl.exe -d $($d.Name)"
        startingDirectory = '~'
        hidden            = $false
        icon              = if ($icon) { $icon } else { $null }
    }
}

$fragDir = Join-Path $wtLocal 'fragments'
if (-not (Test-Path $fragDir)) { New-Item -ItemType Directory -Path $fragDir -Force | Out-Null }
$fragPath = Join-Path $fragDir 'wdc-wsl.json'
$frag = [ordered]@{ profiles = @($profiles | ForEach-Object {
    $p = [ordered]@{}
    foreach ($k in $_.Keys) { if ($null -ne $_[$k]) { $p[$k] = $_[$k] } }   # 去掉 null（如图标缺失）
    $p
}) }
$frag | ConvertTo-Json -Depth 5 | Set-Content -Path $fragPath -Encoding utf8
Write-Step 'WT WSL profiles' 'OK' ("fragment 已渲染：{0}（发行版：{1}）" -f $fragPath, ($distros.Name -join ', '))
exit 0

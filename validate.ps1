#Requires -Version 7
# validate.ps1 - 无副作用校验入口：配置文件 schema 校验 + PowerShell 脚本静态检查
# 独立可用（不需要管理员）：pwsh validate.ps1
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts/lib/common.ps1')

$failCount = 0

# --- 1. winget configuration 逐份校验 ---
Write-Phase 'Validate 1/2 - winget 配置校验'
$configDir = Join-Path $PSScriptRoot 'configs'
$configFiles = @(Get-ChildItem $configDir -Filter '*.winget' -ErrorAction SilentlyContinue)
if ($configFiles.Count -eq 0) {
    Write-Step '配置目录' 'FAIL' "configs/ 下没有 .winget 文件"
    $failCount++
}
foreach ($f in $configFiles) {
    # 退出码语义（实测 winget 1.29）：0=干净通过；1=仅警告（私有配置单元/未指定模块，两类均为本仓库
    # 设计固有，良性）；负 HRESULT=解析或结构错误。故仅 0 与 1 视为通过。
    # --ignore-warnings 抑制警告文本输出，不改变退出码。
    & winget configure validate --file $f.FullName --ignore-warnings 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 1) {
        Write-Step $f.Name 'OK'
    } else {
        Write-Step $f.Name 'FAIL' "winget configure validate 退出码 $LASTEXITCODE"
        $failCount++
    }
}

# --- 2. PowerShell 脚本静态检查 ---
Write-Phase 'Validate 2/2 - 脚本静态检查'
$scriptFiles = @()
$scriptFiles += (Get-ChildItem (Join-Path $PSScriptRoot 'scripts') -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue)
$bootstrap = Join-Path $PSScriptRoot 'bootstrap.ps1'
if (Test-Path $bootstrap) { $scriptFiles += Get-Item $bootstrap }
$self = Get-Item $PSCommandPath
$scriptFiles = @($scriptFiles | Where-Object { $_.FullName -ne $self.FullName })

if (-not (Get-Module -ListAvailable PSScriptAnalyzer)) {
    try {
        Install-Module PSScriptAnalyzer -Scope CurrentUser -Force -Confirm:$false -ErrorAction Stop | Out-Null
        Write-Step 'PSScriptAnalyzer' 'CHANGED' '已按用户范围安装（仅为校验工具，不污染系统）'
    } catch {
        Write-Step 'PSScriptAnalyzer' 'SKIP' "安装失败，退回语法解析检查：$($_.Exception.Message)"
    }
}

foreach ($f in $scriptFiles) {
    if (Get-Module -ListAvailable PSScriptAnalyzer) {
        $r = @(Invoke-ScriptAnalyzer -Path $f.FullName -Severity Error)
        if ($r.Count -eq 0) {
            Write-Step $f.Name 'OK'
        } else {
            $detail = ($r | ForEach-Object { "$($_.RuleName):$($_.Line)" }) -join '; '
            Write-Step $f.Name 'FAIL' $detail
            $failCount++
        }
    } else {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$errors) | Out-Null
        $errors = @($errors)
        if ($errors.Count -eq 0) { Write-Step $f.Name 'OK' '（语法级）' }
        else {
            $detail = ($errors | Select-Object -First 3 | ForEach-Object { $_.Message }) -join '; '
            Write-Step $f.Name 'FAIL' $detail
            $failCount++
        }
    }
}

Write-Phase 'Validate 汇总'
if ($failCount -eq 0) { Write-Step '无副作用校验' 'OK' '全部通过'; exit 0 }
else { Write-Step '无副作用校验' 'FAIL' "$failCount 项未通过"; exit 1 }

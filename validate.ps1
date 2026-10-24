#Requires -Version 7
# validate.ps1 - 无副作用校验入口：配置文件 schema 校验 + PowerShell 脚本静态检查
# 独立可用（不需要管理员）：pwsh validate.ps1
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
# 控制台统一 UTF-8：修正中文在 GBK 代码页窗口里的乱码
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch { }
. (Join-Path $PSScriptRoot 'scripts/lib/common.ps1')

$failCount = 0

# --- 1. winget configuration 逐份校验 ---
Write-Phase 'Validate 1/3 - winget 配置校验'
$configDir = Join-Path $PSScriptRoot 'configs'
$configFiles = @(Get-ChildItem $configDir -Filter '*.winget' -ErrorAction SilentlyContinue)
if ($configFiles.Count -eq 0) {
    Write-Step '配置目录' 'FAIL' "configs/ 下没有 .winget 文件"
    $failCount++
}
foreach ($f in $configFiles) {
    # 退出码语义一处定义于 common.ps1 的 Test-WingetExitCode（含 1=仅警告的良性判定与出处注释）；
    # --ignore-warnings 抑制警告文本输出，不改变退出码
    & winget configure validate --file $f.FullName --ignore-warnings 2>&1 | Out-Null
    $code = $LASTEXITCODE
    if (-not (Test-WingetExitCode -ExitCode $code -Operation 'validate')) {
        # 抖动吸收（两段式，皆只在失败路径付成本）：热源抖动 5s 后原样重试；
        # 冷源（全新机器首个 winget 调用）源索引坏态更久——source update 修复后再试最后一回。
        # 实录：push-CI 三红皆 base-windows 首调（0x80070002/E_FAIL，随后即绿）；
        # fresh-machine 冷源曾连败两次（2026-10-21 run 39635213895）。确定性 schema 错误三试仍红，不掩盖真问题
        Start-Sleep -Seconds 5
        & winget configure validate --file $f.FullName --ignore-warnings 2>&1 | Out-Null
        $code = $LASTEXITCODE
        if (-not (Test-WingetExitCode -ExitCode $code -Operation 'validate')) {
            & winget source update --disable-interactivity 2>&1 | Out-Null
            & winget configure validate --file $f.FullName --ignore-warnings 2>&1 | Out-Null
            $code = $LASTEXITCODE
        }
    }
    if (Test-WingetExitCode -ExitCode $code -Operation 'validate') {
        Write-Step $f.Name 'OK'
    } else {
        Write-Step $f.Name 'FAIL' "winget configure validate 退出码 $code"
        $failCount++
    }
}

# --- 2. PowerShell 脚本静态检查 ---
Write-Phase 'Validate 2/3 - 脚本静态检查'
$scriptFiles = @()
$scriptFiles += (Get-ChildItem (Join-Path $PSScriptRoot 'scripts') -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue)
foreach ($rootScript in 'bootstrap.ps1', 'bootstrap-main.ps1') {
    $p = Join-Path $PSScriptRoot $rootScript
    if (Test-Path $p) { $scriptFiles += Get-Item $p }
}
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

# --- 3. bash 脚本静态检查（WSL shellcheck，工单34）---
# bash -n 只保语法，shellcheck 才抓语义坑（工单32 实录：rev-list 输出 TAB 分隔被按空格切分，bash -n 全绿放行）。
# 关卡设在 WSL 侧（shellcheck 由 LDC cli-tools.pkg 装进发行版）：无 WSL/Ubuntu（CI runner）或
# shellcheck 未就位（LDC 接管前的旧机）→ SKIP 不拦；调用走 Invoke-WslBounded（坑①纪律）
Write-Phase 'Validate 3/3 - bash 脚本静态检查（WSL shellcheck）'
$bashFiles = @(Get-ChildItem (Join-Path $PSScriptRoot 'scripts\wsl') -Filter '*.sh' -ErrorAction SilentlyContinue)
if ((Get-WslDistros) -notcontains 'Ubuntu') {
    Write-Step 'WSL shellcheck' 'SKIP' 'Ubuntu 未就位（发行版内 bash 脚本的把关在 WSL 侧）'
} elseif ($bashFiles.Count -eq 0) {
    Write-Step 'WSL shellcheck' 'SKIP' 'scripts/wsl/ 下无 .sh 文件'
} else {
    $repoWsl = ConvertTo-WslPath $PSScriptRoot
    # 直通姿势：`wsl -e shellcheck <files...>` 逐文件独立 argv——不走 bash -c 串（pwsh 拼命令行
    # 时空格参数引号不保，实测 bash 只拿到 shellcheck 一个词，报 No files specified）
    $r = Invoke-WslBounded -ArgumentList (@('-d', 'Ubuntu', '-e', 'shellcheck') + @($bashFiles | ForEach-Object { "$repoWsl/scripts/wsl/$($_.Name)" })) -TimeoutSeconds 120
    $code = if ($null -ne $r) { $r.Exit } else { $null }
    if ($code -eq 0) {
        Write-Step 'WSL shellcheck' 'OK' "$($bashFiles.Count) 个脚本"
    } elseif ($code -eq 127) {
        Write-Step 'WSL shellcheck' 'SKIP' 'shellcheck 未装（LDC cli-tools.pkg 接管后自动就位）'
    } elseif ($null -eq $code) {
        Write-Step 'WSL shellcheck' 'SKIP' 'wsl.exe 超时/不可用'
    } else {
        $detail = (@($r.Lines) | Select-Object -First 8) -join ' | '
        Write-Step 'WSL shellcheck' 'FAIL' $detail
        $failCount++
    }
}

Write-Phase 'Validate 汇总'
if ($failCount -eq 0) { Write-Step '无副作用校验' 'OK' '全部通过'; exit 0 }
else { Write-Step '无副作用校验' 'FAIL' "$failCount 项未通过"; exit 1 }

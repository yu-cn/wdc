# WDC Git for Windows 升级任务（坑14 剧本）——由计划任务提权运行，脱离 agent 会话进程树
# 流程：等 bash/sh 清零（3×5s 连续静默，20 分钟上限）→ winget 升级 Git.Git → 校验/还原 etc\gitconfig（坑14 ③）→ 落版本与收尾标记
# 用法：经 scripts/adhoc/git-upgrade-task-creator.ps1 登记一次性计划任务（HIGHEST 提权）后自动运行。
# 日志：本文件同目录 git-upgrade-schtasks.log（.gitignore 的 *.log 全局规则兜底，不入库）
$ErrorActionPreference = 'Continue'
$log = Join-Path $PSScriptRoot 'git-upgrade-schtasks.log'
function Log([string]$msg) {
    $line = ('[{0}] {1}' -f (Get-Date -Format 'HH:mm:ss'), $msg)
    Add-Content -Path $log -Value $line -Encoding UTF8
}

Log '=== task start ==='
$gitExe = 'C:\Program Files\Git\cmd\git.exe'
if (Test-Path $gitExe) { Log ('pre-version: ' + (& $gitExe --version 2>&1)) } else { Log 'pre-version: git.exe not found' }

# --- ① 等静默：bash/sh 清零且连续 3 个 5 秒采样无复发 ---
$deadline = (Get-Date).AddMinutes(20)
$quietStreak = 0
while ($true) {
    $b = @(Get-Process bash, sh -ErrorAction SilentlyContinue)
    if ($b.Count -eq 0) {
        $quietStreak++
        if ($quietStreak -ge 3) { Log 'quiet: 3x5s silence reached'; break }
    } else {
        $quietStreak = 0
        $names = ($b | ForEach-Object { $_.Id } ) -join ','
        Log ("blocked-by: bash/sh alive ($names)")
    }
    if ((Get-Date) -gt $deadline) { Log 'ABORT: quiet window not reached in 20min'; exit 2 }
    Start-Sleep -Seconds 5
}

# --- 升级（winget 自带静默；附注：安装器仍可能弹交互向导/报错框，用户点 OK 放行） ---
Log 'launching: winget upgrade Git.Git'
$out = & winget upgrade --id Git.Git --silent --disable-interactivity --accept-package-agreements --accept-source-agreements 2>&1
$code = $LASTEXITCODE
$out | ForEach-Object { Log ("winget| " + $_) }
Log ("winget exit code: $code")

# --- ③ etc\gitconfig 校验/还原（提权安装器读 ~/.gitconfig 符号链接报 Invalid argument 可能清空系统配置） ---
$cfg = 'C:\Program Files\Git\etc\gitconfig'
$cfgOk = (Test-Path $cfg) -and ((Get-Item $cfg).Length -gt 0)
if (-not $cfgOk) {
    Log 'gitconfig missing/empty -> restoring snapshot (schannel variant, no mingw64 paths)'
    $content = @'
[diff "astextplain"]
	textconv = astextplain
[filter "lfs"]
	clean = git-lfs clean -- %f
	smudge = git-lfs smudge -- %f
	process = git-lfs filter-process
	required = true
[http]
	sslBackend = schannel
[core]
	autocrlf = true
	fscache = true
	symlinks = true
[pull]
	rebase = false
[credential]
	helper = manager
[credential "https://dev.azure.com"]
	useHttpPath = true
[init]
	defaultBranch = main
'@
    Set-Content -Path $cfg -Value $content -Encoding Ascii
    Log 'gitconfig restored'
} else {
    Log ('gitconfig intact (' + (Get-Item $cfg).Length + ' bytes)')
}

# --- 收尾 ---
if (Test-Path $gitExe) { Log ('post-version: ' + (& $gitExe --version 2>&1)) } else { Log 'post-version: git.exe not found' }
Log '=== task done ==='

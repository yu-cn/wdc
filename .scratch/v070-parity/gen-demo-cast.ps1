# 一次性合成脚本（不入仓，与 LDC 同做法）：真实命令输出脱敏 → asciinema v2 cast
$ErrorActionPreference = 'Stop'
$st = Get-Content (Join-Path $env:TEMP 'wdc-status-real.txt') -Encoding utf8 | Where-Object { $_.Trim() -ne '' -and $_ -notmatch '^$' -and $_ -notmatch 'wdc: dotfiles' }
$vf = Get-Content (Join-Path $env:TEMP 'wdc-verify-real.txt') -Encoding utf8 | Where-Object { $_.Trim() -ne '' -and $_ -notmatch '^\s*$' }

function Sanitize([string]$s) {
    $s = $s -replace [regex]::Escape('D:\Devs\Repos\wdc'), '~\wdc'
    $s = $s -replace [regex]::Escape('C:\Users\User'), 'C:\Users\demo'
    $s = $s -replace 'bootstrap-\d{8}-\d{6}', 'bootstrap-YYYYMMDD-HHMMSS'
    return $s
}
$st = @($st | ForEach-Object { Sanitize $_ })
$vf = @($vf | ForEach-Object { Sanitize $_ })

$frames = [System.Collections.Generic.List[object]]::new()
$t = 0.0
function Emit([string]$text, [double]$pauseAfter = 0.0) {
    $script:t = [Math]::Round($script:t + 0.02, 2)
    $script:frames.Add(@($script:t, 'o', $text))
    if ($pauseAfter -gt 0) { $script:t = [Math]::Round($script:t + $pauseAfter, 2) }
}

function TypeText([string]$text, [double]$charDelay = 0.03) {
    # 打字机逐字上屏（提示符命令行观感）
    foreach ($ch in $text.ToCharArray()) {
        $script:t = [Math]::Round($script:t + $charDelay, 2)
        $script:frames.Add(@($script:t, 'o', [string]$ch))
    }
}

Emit "`r`n" 0.2
Emit "WDC — 声明式 Windows 开发环境（winget + dotfiles + WSL Ubuntu）· 速览`r`n" 0.35
Emit "`r`n" 0.3

TypeText 'wdc' 0.05
Emit "`r`n" 0.25
foreach ($l in $st) { Emit ("$l`r`n") 0.16 }
Emit "`r`n" 0.3

TypeText 'wdc verify' 0.05
Emit "`r`n" 0.25
# verify 输出滚动上屏：标题段稍慢、正文快滚
$i = 0
foreach ($l in $vf) {
    $d = if ($i -lt 3 -or $l -match '^===') { 0.14 } else { 0.05 }
    Emit ("$l`r`n") $d
    $i++
}
Emit "`r`n" 0.3
Emit "（循环播放 · 源文件 docs/demo.cast · 真实命令输出脱敏生成）"

$header = [ordered]@{
    version   = 2
    width     = 104
    height    = 34
    timestamp = 1792948886
    env       = [ordered]@{ SHELL = 'pwsh'; TERM = 'xterm-256color' }
}
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add(($header | ConvertTo-Json -Compress))
foreach ($f in $frames) { $lines.Add((ConvertTo-Json @($f[0], $f[1], $f[2]) -Compress )) }
Set-Content -Path (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'docs\demo.cast') -Value $lines -Encoding utf8
"cast frames: $($frames.Count), duration: $t s"

#Requires -Version 7
# exit-wdc.ps1 — WDC 退出执行体（exit-mechanism 工单03 / ADR-0010；wdc exit 的执行体）
# 两档：T2 完整退出（默认）= 声明面全退、数据面不动；T1 状态退出（-KeepTools）= 只删 WDC 机器状态。
# 还原基准：pre-install 快照优先（逐值还原，绝不 reg delete 整键——共享键上会连坐非 WDC 值）；
#           无快照（存量机）降级 docs/undo-table.md 的 Windows 默认值并在输出明示。
# 安全：默认交互确认（打印全计划后问）；-Yes 免确认（CI/脚本）；stdin 重定向（非交互）且无 -Yes
#       = 只打印计划零变更（预演）。T2 需提权（HKLM/机器级包）——确认后自重启提权子回合（bootstrap 同款）。
# 红线：机器自留地不碰（ADR-0003）；语言数据面不动（mise/uv 的 runtime/venvs/cache——工单03 定夺 A；
#       mise/uv 本体是声明包、随声明面卸载）；除名≠卸载（Chrome 等已除名软件不在退出面）；
#       `~/.gitidentity` 不删（机器数据）；仓库 clone 本身不删（自行处置）。
[CmdletBinding()]
param(
    [switch]$KeepTools,   # T1：只退状态不动声明面
    [switch]$Yes,         # 免确认（CI/脚本）
    [switch]$WithWsl,     # T3a：WSL 平台层还原（.wslconfig 自动；wsl.conf/LDC 侧打印指引不代跑）
    [switch]$ElevatedPass # 提权子回合自重启标记（内部）
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\common.ps1')
. (Join-Path $PSScriptRoot 'lib\dotfiles-map.ps1')

$repo = Split-Path $PSScriptRoot -Parent

# ---------------------------------------------------------------------------
# 声明面解析（单一来源：configs/）
# ---------------------------------------------------------------------------
function Get-ExitPackageIds {
    @('cli-tools', 'editors') | ForEach-Object {
        Select-String -Path (Join-Path $repo "configs/$_.winget") -Pattern '^\s*id:\s*(\S+)' |
            ForEach-Object { $_.Matches[0].Groups[1].Value }
    }
}

function Get-ExitRegistryUnits {
    # base-windows.winget 的 (name, keyPath, valueName) 三元组逐单元提取——
    # 单元起点是 '- type:' 行，name/keyPath/valueName 均为缩进行（缩进深度不一，用 \s+ 匹配）
    $units = @(); $cur = $null
    foreach ($line in Get-Content (Join-Path $repo 'configs\base-windows.winget')) {
        if ($line -match '^\s*- type:') { if ($cur -and $cur.KeyPath) { $units += $cur }; $cur = @{} }
        elseif ($cur -is [hashtable] -and $line -match '^\s+name:\s*(.+)$' -and -not $cur.ContainsKey('Name')) { $cur.Name = $Matches[1].Trim() }
        elseif ($cur -is [hashtable] -and $line -match '^\s+keyPath:\s*(.+)$') { $cur.KeyPath = $Matches[1].Trim() }
        elseif ($cur -is [hashtable] -and $line -match '^\s+valueName:\s*(.+)$') { $cur.ValueName = $Matches[1].Trim() }
    }
    if ($cur -and $cur.KeyPath) { $units += $cur }
    return $units
}

# 无快照降级表（docs/undo-table.md 的机器可执行版；两处同源维护，改表须同步）
# del = 删值（Windows 缺省即目标态）；set = 置 Windows 默认在位值
$undoFallback = @{
    'Sudo'                     = @{ Action = 'del' }
    'DeveloperMode'            = @{ Action = 'del' }
    'LongPaths'                = @{ Action = 'set'; Type = 'REG_DWORD'; Data = '0' }
    'RemoteDesktopOff'         = @{ Action = 'set'; Type = 'REG_DWORD'; Data = '1' }
    'NotificationsOn'          = @{ Action = 'del' }
    'DarkThemeApps'            = @{ Action = 'set'; Type = 'REG_DWORD'; Data = '1' }
    'DarkThemeSystem'          = @{ Action = 'set'; Type = 'REG_DWORD'; Data = '1' }
    'ShowFileExtensions'       = @{ Action = 'set'; Type = 'REG_DWORD'; Data = '1' }
    'ShowHiddenFiles'          = @{ Action = 'set'; Type = 'REG_DWORD'; Data = '2' }
    'FullPathTitlebar'         = @{ Action = 'del' }
    'OpenThisPC'               = @{ Action = 'del' }
    'FrequentFolders'          = @{ Action = 'del' }
    'FrequentFiles'            = @{ Action = 'del' }
    'RecommendedFiles'         = @{ Action = 'del' }
    'GitCodeFolders'           = @{ Action = 'del' }
    'TipsOff'                  = @{ Action = 'set'; Type = 'REG_DWORD'; Data = '1' }
    'AccountInsights'          = @{ Action = 'del' }
    'TaskbarHideWidgets'       = @{ Action = 'del' }
    'BluetoothOff'             = @{ Action = 'del' }
    'EndTask'                  = @{ Action = 'del' }
    'WebSearchOff'             = @{ Action = 'del' }
    'StartRecommendations'     = @{ Action = 'del' }
    'ClickToDo'                = @{ Action = 'del' }
    'RecallOff'                = @{ Action = 'del' }
    'WidgetServiceOff'         = @{ Action = 'del' }
    'EdgeNewTab'               = @{ Action = 'del' }
    'EdgeOOBE'                 = @{ Action = 'del' }
}

# ---------------------------------------------------------------------------
# pre-install 快照读取（工单01 产物）
# ---------------------------------------------------------------------------
function Get-ExitSnapshot {
    $dir = Join-Path $env:LOCALAPPDATA 'wdc\pre-install'
    $manifest = Join-Path $dir 'manifest.json'
    if (-not (Test-Path -LiteralPath $manifest)) { return $null }
    try { return Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json } catch { return $null }
}

function Get-SnapshotValue {
    # 从 .reg 导出文件解析单值（"Name"=dword:00000001 / "Name"="str" / hex(类型):...）；无值返回 $null
    param([string]$RegFile, [string]$ValueName)
    if (-not (Test-Path -LiteralPath $RegFile)) { return $null }
    foreach ($line in (Get-Content -LiteralPath $RegFile -Encoding Unicode)) {
        if ($line -match ('^"' + [regex]::Escape($ValueName) + '"=(.+)$')) {
            $raw = $Matches[1]
            if ($raw -match '^dword:([0-9A-Fa-f]+)$') { return @{ Type = 'REG_DWORD'; Data = [string][Convert]::ToInt64($Matches[1], 16) } }
            if ($raw -match '^"(.*)"$') { return @{ Type = 'REG_SZ'; Data = [regex]::Unescape($Matches[1]) } }
            return @{ Type = 'UNSUPPORTED'; Data = $raw }   # hex( 二进制类——报告不瞎还原
        }
    }
    return $null
}

# ---------------------------------------------------------------------------
# 计划构建（只读，两回合共用）
# ---------------------------------------------------------------------------
$pkgs = @(Get-ExitPackageIds)
$regs = @(Get-ExitRegistryUnits)
$map = Get-DotfilesMap
$dotfilesPlan = @($map | ForEach-Object {
    @{ Name = $_.Name; Target = $_.Target; HasBak = (Test-Path -LiteralPath "$($_.Target).bak") }
})
$snap = Get-ExitSnapshot
$snapMode = if ($snap -and $snap.status -eq 'ok') { 'snapshot' }
    elseif ($snap) { 'skipped-already-converged（快照缺席——注册表按 undo 表恢复 Windows 默认值，非你的原始值）' }
    else { 'manifest 缺失——注册表按 undo 表恢复 Windows 默认值，非你的原始值' }

function Show-ExitPlan {
    Write-Phase 'wdc exit · 退出计划（预演只读）'
    Write-Step '档位' 'INFO' ($(if ($KeepTools) { 'T1 状态退出（-KeepTools）——只删 WDC 机器状态，环境原样' } else { 'T2 完整退出（默认）——声明面全退、数据面不动' }))
    if (-not $KeepTools) {
        Write-Step '声明包卸载' 'INFO' "$($pkgs.Count) 个（cli-tools + editors 域逐 Id；同 ID 多版本逐版本显式——坑7）"
        Write-Step '注册表还原' 'INFO' "$($regs.Count) 项；基准 = $snapMode"
        Write-Step 'dotfiles 落点处置' 'INFO' (($dotfilesPlan | ForEach-Object { "$($_.Name)=$(if ($_.HasBak) { '还原 .bak 原文件' } else { '删除（WDC 创建）' })" }) -join '；')
        Write-Step '残留清扫' 'INFO' 'clean-legacy -Fix（WT fragments / vp / 死计划任务）'
        if ($WithWsl) {
            Write-Step 'WSL 平台层（-WithWsl）' 'INFO' '.wslconfig 自动还原（.bak 原文件/无则删）；wsl.conf 声明键与 LDC 侧打印指引不代跑（发行版卸载永不代跑——数据自担）'
        }
    }
    Write-Step '机器状态删除' 'INFO' '%LOCALAPPDATA%\wdc（账本/渲染账本/缓存/pre-install 快照）+ ~/.wdc 指针 + 死计划任务'
    Write-Step '不碰' 'INFO' '机器自留地（ADR-0003）· 语言数据面（runtime/venvs/cache）· 已除名软件（Chrome）· ~/.gitidentity · 仓库 clone 本身（自行处置）'
    Write-Step '数据面注记' 'INFO' 'T2 卸载 mise/uv 本体（声明包），其管理的 runtime/venvs 留在原位——`~/.local/share/mise`、uv cache 等不删'
}

# ---------------------------------------------------------------------------
# 交互关卡：确认 / 预演 / 提权重启
# ---------------------------------------------------------------------------
$confirmed = $false
if ($ElevatedPass) {
    $confirmed = $true   # 确认发生在父回合，子回合直接执行
} else {
    Show-ExitPlan
    if ($Yes) { $confirmed = $true }
    elseif ([Console]::IsInputRedirected) {
        Write-Step '预演' 'OK' '非交互且未 -Yes——以上为计划预演，未做任何变更（CI/脚本执行加 -Yes）'
        exit 0
    } else {
        $ans = Read-Host '确认退出？输入 yes 执行（其他任意键取消）'
        $confirmed = ($ans -eq 'yes')
        if (-not $confirmed) { Write-Step '退出' 'OK' '已取消——未做任何变更'; exit 0 }
    }
    # T2 需要提权（HKLM 注册表 + 机器级包卸载）；T1 全用户级无需提权
    if (-not $KeepTools -and -not (Test-IsElevated)) {
        Write-Phase '提权子回合（HKLM 注册表还原 + 机器级包卸载）'
        $kt = if ($KeepTools) { ' -KeepTools' } else { '' }
        $ww = if ($WithWsl) { ' -WithWsl' } else { '' }
        $childCmd = "& '$PSCommandPath'$kt$ww -Yes -ElevatedPass *>&1 | Tee-Object -FilePath '$env:TEMP\wdc-exit.log'; exit `$LASTEXITCODE"
        try {
            $child = Start-Process pwsh -Verb RunAs -ArgumentList @('-NoProfile', '-Command', $childCmd) -PassThru -Wait
            Write-Step '提权子回合' (($child.ExitCode -eq 0) ? 'OK' : 'FAIL') "退出执行退出码 $($child.ExitCode)"
            exit $child.ExitCode
        } catch {
            Write-Step '提权' 'FAIL' 'UAC 被取消或不可用——退出未执行'
            exit 1
        }
    }
}

# ---------------------------------------------------------------------------
# 执行（T1 从这里起只走状态删除；T2 全量）
# ---------------------------------------------------------------------------
$failCount = 0
function Exit-Step {
    param([string]$Name, [bool]$Ok, [string]$Note)
    if ($Ok) { Write-Step $Name 'OK' $Note } else { Write-Step $Name 'FAIL' $Note; $script:failCount++ }
}

if (-not $KeepTools) {
    # 1/4 声明包卸载（坑7：同 ID 多版本 0x8A150016 → 逐版本显式）
    # 基础设施共享资源不卸（工单03 CI 死因定性 2026-11-22，三轮恒死于字体包卸载 run 44917510844/
    # 44923793172/44926977603——卸载瞬间的字体变更广播掀翻无头控制台/进程树，强证据）：
    #   VCRedist=公共运行库（Chrome 等无数无关应用共用）；NF 字体=系统级共享（卸之其他终端渲染豆腐块）
    # 两者退出后照常服务其他软件——留驻即「不弄坏用户环境」红线的延伸
    Write-Phase '退出 1/4 - 声明包卸载'
    foreach ($id in $pkgs) {
        if ($id -like 'Microsoft.VCRedist*' -or $id -like 'DEVCOM.*') {
            Write-Step "包 $id" 'OK' '基础设施共享资源不卸（公共运行库/NF 字体——退出后照常服务他软件）'
            continue
        }
        $null = & winget uninstall --id $id --silent --disable-interactivity 2>$null
        $code = $LASTEXITCODE -band 0xFFFFFFFF
        if ($code -eq 0) { Exit-Step "包 $id" $true '已卸载' }
        elseif ($code -eq 0x8A150014) { Exit-Step "包 $id" $true '未装（无操作）' }
        elseif ($code -eq 0x8A150016) {
            # 多版本并存：枚举后逐版本卸载
            $versions = @(& winget list --id $id --disable-interactivity 2>$null | Select-Object -Skip 2 |
                ForEach-Object { ($_ -split '\s{2,}')[1] } | Where-Object { $_ -and $_ -match '^\d' })
            $allOk = $true
            foreach ($v in $versions) {
                $null = & winget uninstall --id $id --version $v --silent --disable-interactivity 2>$null
                if (($LASTEXITCODE -band 0xFFFFFFFF) -ne 0 -and ($LASTEXITCODE -band 0xFFFFFFFF) -ne 0x8A150014) { $allOk = $false }
            }
            Exit-Step "包 $id（多版本）" $allOk "$($versions.Count) 个版本逐一卸载"
        }
        else { Exit-Step "包 $id" $false "winget 退出码 $code" }
    }

    # 2/4 注册表还原（快照优先逐值还原；无快照走 undo 表；绝不整键删除——共享键连坐非 WDC 值）
    Write-Phase '退出 2/4 - 注册表还原'
    $snapDir = Join-Path $env:LOCALAPPDATA 'wdc\pre-install'
    foreach ($u in $regs) {
        $action = $null; $via = 'undo 表'
        if ($snap -and $snap.status -eq 'ok') {
            $slug = $u.KeyPath -replace '[\\/:]', '_'
            $keyEntry = $snap.keys.$slug
            $regFile = Join-Path $snapDir "$slug.reg"
            if ($keyEntry -and $keyEntry.present -and (Test-Path -LiteralPath $regFile)) {
                $sv = Get-SnapshotValue -RegFile $regFile -ValueName $u.ValueName
                if ($null -ne $sv) {
                    $via = '快照'
                    if ($sv.Type -eq 'UNSUPPORTED') { Exit-Step "注册表 $($u.Name)" $false "快照值类型不可自动还原（$($sv.Data)）——按 undo 表处置"; $action = $undoFallback[$u.Name] }
                    else { $action = @{ Action = 'set'; Type = $sv.Type; Data = $sv.Data } }
                } else { $via = '快照'; $action = @{ Action = 'del' } }
            } else { $action = $undoFallback[$u.Name] }   # 快照里该键缺席（WDC 前不存在）→ 删值
        } else { $action = $undoFallback[$u.Name] }
        if (-not $action) { Exit-Step "注册表 $($u.Name)" $false '无还原动作（表缺项？）'; continue }
        if ($action.Action -eq 'del') {
            $null = & reg.exe delete $u.KeyPath /v $u.ValueName /f 2>$null
            Exit-Step "注册表 $($u.Name)" ($LASTEXITCODE -eq 0) "删值（$via）"
        } else {
            $null = & reg.exe add $u.KeyPath /v $u.ValueName /t $action.Type /d $action.Data /f 2>$null
            Exit-Step "注册表 $($u.Name)" ($LASTEXITCODE -eq 0) "置 $($action.Data)（$via）"
        }
    }

    # 3/4 dotfiles 落点处置（.bak 本体=首次渲染前原文件且永不清理——还原它；无 .bak=WDC 创建——删除）
    Write-Phase '退出 3/4 - dotfiles 落点处置'
    foreach ($d in $dotfilesPlan) {
        if (Test-Path -LiteralPath $d.Target) {
            if ($d.HasBak) {
                Copy-Item -LiteralPath "$($d.Target).bak" -Destination $d.Target -Force
                Remove-Item -LiteralPath "$($d.Target).bak*" -Force -ErrorAction SilentlyContinue
                Exit-Step "落点 $($d.Name)" $true '已还原 .bak 原文件（备份链清）'
            } else {
                Remove-Item -LiteralPath $d.Target -Force
                Exit-Step "落点 $($d.Name)" $true '已删除（WDC 创建）'
            }
        } else { Exit-Step "落点 $($d.Name)" $true '本就不在' }
    }

    # 4/4 残留清扫（fragments / vp / 死计划任务）
    Write-Phase '退出 4/4 - 残留清扫（clean-legacy -Fix）'
    & (Join-Path $PSScriptRoot 'clean-legacy.ps1') -Fix
}

# WSL 平台层还原（-WithWsl，T3a）：.wslconfig 自动（与 dotfiles 同款 .bak 语义——首次渲染前原文件
# 还原、无 .bak 即 WDC 创建则删）；wsl.conf 声明键与 LDC 侧只打印指引（发行版内 root 编辑的失败
# 模式与 LDC 领地边界，摘键归未来的 ldc exit；`wsl --unregister` 永不代跑——发行版内有用户数据）
if ($WithWsl -and -not $KeepTools) {
    Write-Phase '退出（可选）- WSL 平台层还原（-WithWsl / T3a）'
    $wslcfg = Join-Path $env:USERPROFILE '.wslconfig'
    if (Test-Path -LiteralPath $wslcfg) {
        if (Test-Path -LiteralPath "$wslcfg.bak") {
            Copy-Item -LiteralPath "$wslcfg.bak" -Destination $wslcfg -Force
            Remove-Item -LiteralPath "$wslcfg.bak*" -Force -ErrorAction SilentlyContinue
            Exit-Step '.wslconfig' $true '已还原 .bak 原文件（备份链清）；下次 wsl --shutdown 后生效'
        } else {
            Remove-Item -LiteralPath $wslcfg -Force
            Exit-Step '.wslconfig' $true '已删除（WDC 创建；WSL 回全默认形态），wsl --shutdown 后生效'
        }
    } else { Exit-Step '.wslconfig' $true '本就不在' }
    Write-Step 'wsl.conf 声明键' 'INFO' '不代跑——指引：发行版内 root 编辑 /etc/wsl.conf 摘 [boot] systemd 与 [user] default 两键（或留给 ldc exit，落地后自动）'
    Write-Step 'LDC 侧（发行版内环境）' 'INFO' "不代跑——指引：发行版内 ~/dev/ldc 跑 ldc exit（落地后）或按其 configs 清单自卸；仓库目录可删；完整移除发行版：wsl --unregister Ubuntu（**数据全失，自担**）"
}

# 机器状态删除（T1/T2 共有）
Write-Phase '机器状态删除'
$stateDir = Join-Path $env:LOCALAPPDATA 'wdc'
if (Test-Path $stateDir) { Remove-Item -Path $stateDir -Recurse -Force; Exit-Step '%LOCALAPPDATA%\wdc' $true '已删除（账本/渲染账本/缓存/pre-install 快照）' }
else { Exit-Step '%LOCALAPPDATA%\wdc' $true '本就不在' }
$ptr = Join-Path $HOME '.wdc'
if (Test-Path $ptr) { Remove-Item -Path $ptr -Force; Exit-Step '~/.wdc 指针' $true '已删除' }
else { Exit-Step '~/.wdc 指针' $true '本就不在' }
# T1 不经 clean-legacy——死计划任务就地清
if ($KeepTools) {
    $tasks = @((& schtasks.exe /Query /FO CSV 2>$null | ConvertFrom-Csv) |
        ForEach-Object { ($_.PSObject.Properties | Select-Object -First 1).Value } |
        Where-Object { $_ -match '^\\?(WdcBootstrapResume|WDC-GitUpgrade-)' })
    foreach ($t in $tasks) {
        $null = & schtasks.exe /Delete /TN $t /F 2>$null
        Exit-Step "计划任务 $t" ($LASTEXITCODE -eq 0) '已删除'
    }
}

# ---------------------------------------------------------------------------
# 退出断言（verify-exit：断效果——坑11）
# ---------------------------------------------------------------------------
Write-Phase '退出断言（verify-exit）'
$va = $true
if (Test-Path (Join-Path $env:LOCALAPPDATA 'wdc')) { $va = $false; Write-Step '状态目录已清' 'FAIL' '%LOCALAPPDATA%\wdc 仍在' }
else { Write-Step '状态目录已清' 'OK' '' }
if (Test-Path (Join-Path $HOME '.wdc')) { $va = $false; Write-Step '指针已清' 'FAIL' '~/.wdc 仍在' }
else { Write-Step '指针已清' 'OK' '' }
if (-not $KeepTools) {
    foreach ($d in $dotfilesPlan) {
        if (Test-Path -LiteralPath "$($d.Target).bak") { $va = $false; Write-Step "备份链已清 $($d.Name)" 'FAIL' '.bak 仍在' }
    }
    Write-Step 'dotfiles 备份链' ($(if ($va) { 'OK' } else { 'FAIL' })) ''
}

Write-Phase '退出汇总'
if ($failCount -eq 0 -and $va) {
    Write-Step 'wdc exit' 'OK' "$(if ($KeepTools) { 'T1 状态退出完成' } else { 'T2 完整退出完成' })——机器状态已清，声明面已退；仓库 clone 自行处置；WSL 侧（T3）另议"
    exit 0
} else {
    Write-Step 'wdc exit' 'FAIL' "有 $failCount 项失败——重跑幂等收尾；日志见上"
    exit 1
}

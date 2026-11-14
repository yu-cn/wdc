# wslconfig.ps1 — .wslconfig 声明与渲染的单一来源（ADR-0008；install-wsl / install-dotfiles / verify / inventory 四方共读）
# .wslconfig 是 WSL 平台配置的 Windows 侧半边（VM 形态：核/内存配额、网络模式、内存回收）。
# 含机器派生值（processors/memory），不入 dotfiles-map 静态纯拷贝模型——走安装期公式渲染
# （ADR-0004 模式，~/.wdc 指针同款先例）。发行版侧半边 /etc/wsl.conf 由 setup-ubuntu.sh root
# 阶段保护合并（同 ADR-0008）。依赖 common.ps1 的 Write-Step（调用方均已 dot-source）。

function Get-WslConfigPaths {
    # 模板与落点：模板相对仓库根 dotfiles\windows\wslconfig；落点 %USERPROFILE%\.wslconfig（wslservice 读取位）
    param([Parameter(Mandatory)][string]$RepoRoot)
    [pscustomobject]@{
        Template = Join-Path $RepoRoot 'dotfiles\windows\wslconfig'
        Target   = Join-Path $HOME '.wslconfig'
    }
}

function Get-WslConfigFacts {
    # 渲染公式（ADR-0008，锚定主人 2026-11-13 手调值：22 逻辑核/31GB 机 → 16 核/16GB）：
    #   processors = 逻辑核 − 6（给 Windows 留 6 核，避免 WSL 内编译时前台卡顿；下限 4）
    #   memory     = 物理内存半数向上取整，夹在 8–16GB（重负载够用，同时保宿主响应）
    $cs = Get-CimInstance Win32_ComputerSystem
    $cores = [int]$cs.NumberOfLogicalProcessors
    $physGb = [math]::Ceiling($cs.TotalPhysicalMemory / 1GB)
    [pscustomobject]@{
        Processors = [math]::Max(4, $cores - 6)
        MemoryGb   = [math]::Min(16, [math]::Max(8, [math]::Ceiling($physGb / 2)))
        Cores      = $cores
        PhysicalGb = $physGb
    }
}

function Get-WslConfigRendered {
    # 渲染产物（字符串）：模板占位符代入机器事实；行尾 CRLF——Windows 侧文件习惯，与本机既有手调件一致
    # （模板仓内 LF 由 .gitattributes 钉）；utf8 无 BOM 由落盘方保证
    param([Parameter(Mandatory)][string]$RepoRoot)
    $p = Get-WslConfigPaths -RepoRoot $RepoRoot
    $facts = Get-WslConfigFacts
    $lines = @(Get-Content -LiteralPath $p.Template) | ForEach-Object {
        $_.Replace('{{WDC_WSL_PROCESSORS}}', [string]$facts.Processors).Replace('{{WDC_WSL_MEMORY_GB}}', [string]$facts.MemoryGb)
    }
    ($lines -join "`r`n") + "`r`n"
}

function Install-WslConfig {
    # 渲染落位（幂等）：内容一致 OK 跳过；不一致备份 .bak 一次后重写；CHANGED 附 wsl --shutdown 生效提示
    # （VM 形态改动自下次 VM 启动生效——正被占用的运行中发行版不受影响，shutdown 由主人择机）
    param([Parameter(Mandatory)][string]$RepoRoot)
    $p = Get-WslConfigPaths -RepoRoot $RepoRoot
    if (-not (Test-Path -LiteralPath $p.Template)) { Write-Step '.wslconfig' 'SKIP' "模板缺失：$($p.Template)"; return }
    $rendered = Get-WslConfigRendered -RepoRoot $RepoRoot
    $current = if (Test-Path -LiteralPath $p.Target) { Get-Content -LiteralPath $p.Target -Raw } else { $null }
    if ($null -ne $current -and $current -eq $rendered) {
        Write-Step '.wslconfig' 'OK' '已与声明渲染一致（幂等跳过）'
        return
    }
    if ($null -ne $current) {
        Copy-Item -LiteralPath $p.Target -Destination "$($p.Target).bak"
        Write-Step '.wslconfig' 'INFO' "旧内容已备份 $($p.Target).bak（手调值如需保留：改模板或公式吸收，ADR-0008）"
    }
    Set-Content -LiteralPath $p.Target -Value $rendered -NoNewline -Encoding utf8
    Write-Step '.wslconfig' 'CHANGED' '已渲染落位——VM 形态改动需 wsl --shutdown 后下次进入生效'
}

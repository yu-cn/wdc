# Microsoft.PowerShell_profile.ps1 — WDC 统一 pwsh 配置（仓库 dotfiles 管理）
# 原则：所有初始化均带存在性守卫——未完成 bootstrap 的机器上打开终端不报错

# --- mise 的语言环境（mise 由 cli-tools 域 winget 安装；activate 供按目录切换，全局 node 经 shims 解析）---
$miseCmd = Get-Command mise -ErrorAction SilentlyContinue
if ($miseCmd) { (& $miseCmd.Source activate pwsh) | Out-String | Invoke-Expression }

# --- init 产物缓存命中（pwsh-startup 工单01）---
# starship/gh/zoxide 的 init 产物是静态脚本——bootstrap 渲染时已生成到 %LOCALAPPDATA%\wdc\cache\
# （scripts/lib/pwsh-init-cache.ps1；starship 缓存的是 --print-full-init 全量产物，绕旧写法的双层 spawn）。
# 命中即 dot-source（零 spawn），缺失回退原样 spawn——守卫原则不变。工具升级后缓存滞后一版，
# 重跑 bootstrap 收口（profile 内刻意不做版本校验——校验即 spawn，抵消收益）。
# 路径与 lib 侧 Get-WdcInitCacheDir 各自声明（模板自足原则：开终端不得依赖仓库在位，工单15 族教训）
function __wdcInitCachePath {
    param([Parameter(Mandatory)][string]$Name)
    $p = Join-Path (Join-Path $env:LOCALAPPDATA 'wdc\cache') $Name
    if (Test-Path $p) { $p } else { $null }
}

# --- PSReadLine：历史去重 + 预测式补全 + ListView 可视预测（输出重定向等场景下静默跳过）---
try {
    Set-PSReadLineOption -HistoryNoDuplicates -PredictionSource History -PredictionViewStyle ListView -EditMode Windows -ErrorAction SilentlyContinue
} catch { }

# --- zoxide：z 智能跳目录（与 bash 侧同款）---
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    $__init = __wdcInitCachePath 'zoxide-init.ps1'
    if ($__init) { . $__init } else { Invoke-Expression (& { (zoxide init powershell | Out-String) }) }
}

# --- fzf：Ctrl-R 搜历史 / Ctrl-T 选文件 / Alt-C 跳目录（与 bash 侧同款语义）---
# fzf 官方集成只有 --bash/--zsh/--fish/--nushell（2026-11-01 实测 0.74.5 无 --powershell）——
# 旧实现靠「输出为空则静默跳过」的守卫，键位实际从未生效过。PS 侧无官方集成，
# 改用 PSReadLine 处理器手工接线，零新依赖；fd/bat 缺席时对应键位不绑定（存在性守卫）
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    try {
        # Ctrl-T：fd 搜索源（自动忽略 .git/node_modules），bat 右侧实时预览；空格多选、回车插入光标处
        if (Get-Command fd -ErrorAction SilentlyContinue) {
            Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock {
                param($key, $arg)
                $previewArgs = @()
                if (Get-Command bat -ErrorAction SilentlyContinue) {
                    $previewArgs = @('--preview', 'bat --color=always {}', '--preview-window', 'right:60%')
                }
                $picked = @(& fd --type f --hidden --follow --exclude .git --exclude node_modules 2>$null |
                    & fzf --multi --height 40% --layout=reverse --border @previewArgs 2>$null)
                if ($LASTEXITCODE -eq 0 -and $picked) {
                    $quoted = ($picked | ForEach-Object { "'" + $_.Replace("'", "''") + "'" }) -join ' '
                    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quoted)
                }
            }
        }
        # Ctrl-R：交互式搜历史（当前缓冲区作预填 query；选中整行替换缓冲区）
        Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock {
            param($key, $arg)
            $line = $null; $cursor = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
            $picked = Get-History | ForEach-Object CommandLine | Select-Object -Unique -Last 500 |
                & fzf --query "$line" --height 40% --layout=reverse --border 2>$null
            if ($LASTEXITCODE -eq 0 -and $picked) {
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $picked)
            }
        }
        # Alt-C：fd 搜目录即跳（选中即 cd，命令入历史）
        if (Get-Command fd -ErrorAction SilentlyContinue) {
            Set-PSReadLineKeyHandler -Chord 'Alt+c' -ScriptBlock {
                param($key, $arg)
                $dir = & fd --type d --hidden --follow --exclude .git --exclude node_modules 2>$null |
                    & fzf --height 40% --layout=reverse --border 2>$null
                if ($LASTEXITCODE -eq 0 -and $dir) {
                    Set-Location $dir
                    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
                    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("cd '$($dir.Replace("'", "''"))'")
                    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
                }
            }
        }
    } catch { }   # 非交互宿主（脚本/agent 会话）无 PSReadLine 控制台——静默跳过
}

# --- 原生参数补全（gh/uv 各自发行生成器；存在性守卫 + try/catch 静默降级）---
# pwsh 无 git 原生补全生态（补全脚本是 bash 系）——PSReadLine 预测已覆盖大头，刻意不补；
# docker 不在 Windows（家在 WSL，bash-completion 侧已齐）——刻意不补（GLOSSARY「双边最优化」）
if (Get-Command gh -ErrorAction SilentlyContinue) {
    try {
        $__init = __wdcInitCachePath 'gh-completion.ps1'
        if ($__init) { . $__init } else { Invoke-Expression (& gh completion -s powershell | Out-String) }
    } catch { }
}
# uv 补全惰性加载（pwsh-startup 工单02）：产物 766KB、spawn+求值 ~670ms（ASUS 真机）而多数会话不用 uv——
# 薄壳 completer 首次 `uv <Tab>` 才生成求值（同一轮原生 completer 即已注册参与出候选）；置位后恒返回空
# 让路后注册的原生 completer——同命令多 completer 叠加执行，不置位会双份候选
if (Get-Command uv -ErrorAction SilentlyContinue) {
    $global:__uvCompletionLoaded = $false
    Register-ArgumentCompleter -CommandName uv -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        if (-not $global:__uvCompletionLoaded) {
            $global:__uvCompletionLoaded = $true
            try { Invoke-Expression (& uv generate-shell-completion powershell | Out-String) } catch { return @() }
        }
        return @()
    }
}

# --- starship 提示符（最后初始化；三 shell 共用 ~/.config/starship.toml）---
if (Get-Command starship -ErrorAction SilentlyContinue) {
    $__init = __wdcInitCachePath 'starship-init.ps1'
    if ($__init) { . $__init } else { Invoke-Expression (&starship init powershell) }
}
# init 机件收尾：__wdcInitCachePath 与 $__init 仅 init 期使用（点注产物落 profile 作用域随会话保留）——用完即清不落会话
Remove-Item function:__wdcInitCachePath -ErrorAction SilentlyContinue
Remove-Variable __init -ErrorAction SilentlyContinue

# --- git 快捷方式（与 bash 侧 gs/gl/gd/gco 同义）---
function gs { git status -sb }
function gl { git log --oneline --graph --decorate -20 }
function gd { git diff }
function gco { param([string]$Branch) git checkout $Branch }

# --- wdc：一键工具（薄包装；全部逻辑在仓库 scripts/wdc.ps1，工单 20——单一来源防漂移）---
function wdc {
    $repo = (Get-Content "$HOME\.wdc" -ErrorAction SilentlyContinue | Select-Object -First 1)
    if (-not $repo -or -not (Test-Path (Join-Path $repo 'scripts\wdc.ps1'))) {
        Write-Host 'wdc: 未配置仓库路径——先在仓库跑一次 bootstrap（会自动写 ~/.wdc）' -ForegroundColor Yellow
        return
    }
    # --json 归一为 -Json（cli-ux 工单02）：pwsh 绑定器把 --json 当未知参数拒绝；UX 与 ldc --json 对齐
    $fwdArgs = @($args | ForEach-Object { if ($_ -eq '--json') { '-Json' } else { $_ } })
    & pwsh -NoProfile -File (Join-Path $repo 'scripts\wdc.ps1') @fwdArgs
}

# --- wdc Tab 补全（cli-ux 工单05）：词表解析自 wdc.ps1 的 $wdcCommands 行单一来源，不抄列表 ---
# 纯文本解析零子进程——每次 Tab 不付 pwsh 启动成本；解析失败静默返回空，不干扰补全框架
Register-ArgumentCompleter -CommandName wdc -ScriptBlock {
    param($wordToComplete)
    $repo = Get-Content "$HOME\.wdc" -ErrorAction SilentlyContinue | Select-Object -First 1
    $wdcScript = if ($repo) { Join-Path $repo 'scripts\wdc.ps1' } else { $null }
    if (-not $wdcScript -or -not (Test-Path $wdcScript)) { return @() }
    $m = [regex]::Match((Get-Content $wdcScript -Raw), '(?m)^\s*\$wdcCommands\s*=\s*(.+?)\s*$')
    if (-not $m.Success) { return @() }
    [regex]::Matches($m.Groups[1].Value, "'([^']+)'") | ForEach-Object { $_.Groups[1].Value } |
        Where-Object { $_ -like "$wordToComplete*" }
}

# --- dotfiles 漂移即时提示（工单24，ADR-0015 口径）：开新终端即见，零漂移静默 ---
# 信号一「落点漂移」：落点内容 ≠ 模板（机器侧直改渲染物或模板更新未重渲染）——经 ~/.wdc 指针
#   dot-source 落点映射后逐项 hash 比对（7 个小文件毫秒级；子作用域加载，映射函数不落会话）
# 信号二「未提交模板编辑」：git porcelain——「改完记得 commit」红线提醒，非误报（工单24 Comments 定性）
# --no-optional-locks：不与并行运行的 lazygit/starship 抢 index 锁（只读探测的标准姿势）
$__wdcRepo = Get-Content "$HOME\.wdc" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($__wdcRepo -and (Test-Path (Join-Path $__wdcRepo 'scripts\lib\dotfiles-map.ps1'))) {
    $__driftNames = & {
        . (Join-Path $__wdcRepo 'scripts\lib\dotfiles-map.ps1')
        $names = @()
        foreach ($m in (Get-DotfilesMap)) {
            $src = Join-Path (Join-Path $__wdcRepo 'dotfiles') $m.Source
            if ((Test-DotfileInSync -Source $src -Target $m.Target) -ne 'ok') { $names += $m.Name }
        }
        $names -join '、'
    }
    if ($__driftNames) {
        Write-Host "wdc: dotfiles 落点漂移（$__driftNames）——重跑 bootstrap 渲染，或 wdc triage 分流" -ForegroundColor Yellow
    }
    $__uncommitted = @(git --no-optional-locks -C "$__wdcRepo" status --porcelain -- dotfiles/).Count
    if ($__uncommitted -gt 0) { Write-Host "wdc: dotfiles 模板有 $__uncommitted 处未提交编辑——commit 收口" -ForegroundColor Yellow }
}
Remove-Variable __wdcRepo, __driftNames, __uncommitted -ErrorAction SilentlyContinue

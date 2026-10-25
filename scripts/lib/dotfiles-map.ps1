# dotfiles-map.ps1 — dotfiles 落点映射与状态判定的单一事实源（install / verify / triage / status / inventory / profile 六方共读）
# 「仓库模板 → 机器落点」只在此声明一次：新增 dotfile 改这里，安装面与验收断言面自动同步（防清单漂移——
# 曾有 install 7 项 / verify 6 项的实际分叉，keybindings 漏验即其产物）。
# 纯数据与纯函数，不依赖 common.ps1，可被任何脚本单独 dot-source（profile/bashrc 的漂移提示同走此面）。

function Get-WtLocalStateDir {
    # Windows Terminal 机器本地状态目录（settings.json 所在；包 SID 路径唯一来源）
    Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'
}

function Get-DotfilesMap {
    # 每项：Name（展示名）/ Source（仓库内相对 dotfiles/ 的路径）/ Target（机器侧绝对落点）
    # WT 的 WSL profile 不在此列——它是模板里的静态声明（ADR-0006），随 settings.json 渲染一起落地，无机器侧动作
    $docs = [Environment]::GetFolderPath('MyDocuments')
    @(
        @{ Name = 'gitconfig';          Source = 'windows/gitconfig';               Target = (Join-Path $HOME '.gitconfig') }
        @{ Name = 'bashrc';             Source = 'windows/bashrc';                  Target = (Join-Path $HOME '.bashrc') }
        @{ Name = 'pwsh profile';       Source = 'windows/pwsh-profile.ps1';        Target = (Join-Path $docs 'PowerShell\Microsoft.PowerShell_profile.ps1') }
        @{ Name = 'VSCode settings';    Source = 'windows/vscode-settings.json';    Target = (Join-Path $env:APPDATA 'Code\User\settings.json') }
        @{ Name = 'VSCode keybindings'; Source = 'windows/vscode-keybindings.json'; Target = (Join-Path $env:APPDATA 'Code\User\keybindings.json') }
        @{ Name = 'WT settings';        Source = 'windows/terminal-settings.json';  Target = (Join-Path (Get-WtLocalStateDir) 'settings.json') }
        @{ Name = 'starship';           Source = 'shared/starship.toml';            Target = (Join-Path $HOME '.config\starship.toml') }
    )
}

function Test-DotfileInSync {
    # 落点状态三态（ADR-0015 渲染拷贝模型的单一判定，install/verify/triage/status/profile 六方共读）：
    #   ok     = 实体文件且内容与模板一致（Get-FileHash 比对）
    #   absent = 落点不存在（未安装——重跑 bootstrap 渲染即收敛）
    #   drift  = 内容不符；落点是符号链接/其它链接（旧安装形态或外来链接——迁移信号，残形可再造不备份）
    # 纯函数：不依赖 common.ps1；缺失文件走分支兜住（Get-FileHash 对缺失路径抛错，断言面不可炸异常栈）
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Target
    )
    if (-not (Test-Path -LiteralPath $Source)) { return 'drift' }
    $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if (-not $item) { return 'absent' }
    if ($item.LinkType -or $item.PSIsContainer) { return 'drift' }
    if ((Get-FileHash -LiteralPath $Target).Hash -eq (Get-FileHash -LiteralPath $Source).Hash) { return 'ok' }
    return 'drift'
}

function Get-WdcRenderStateFile {
    # 渲染账本（对齐 LDC ADR-0015 补注：漂移方向判定）——格式与 sha256sum 兼容「<hash>␣␣<落点绝对路径>」，
    # 记录上次渲染时各落点的内容指纹。账本可丢：缺失/损坏时方向判定退化为 unknown（等同 ADR-0015
    # 首版行为），下次渲染自愈重建。机器本地状态，不入仓库（ADR-0004 模式）。
    Join-Path $env:LOCALAPPDATA 'wdc\rendered.sha256'
}

function Get-RenderedState {
    # 上次渲染时的落点内容 hash；无记录返回 $null
    param([Parameter(Mandatory)][string]$Target)
    $f = Get-WdcRenderStateFile
    if (-not (Test-Path -LiteralPath $f)) { return $null }
    # 路径自第 67 字符起（64 位 hash + 2 空格）——精确匹配避免前缀串扰
    foreach ($l in (Get-Content -LiteralPath $f)) {
        if ($l.Length -gt 66 -and $l.Substring(66) -eq $Target) { return $l.Substring(0, 64) }
    }
    return $null
}

function Set-RenderedState {
    # 单行更新（有则覆写无则追加；tmp+mv 原子落盘）
    param(
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][string]$Hash
    )
    $f = Get-WdcRenderStateFile
    $dir = Split-Path $f -Parent
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $tmp = "$f.tmp"
    $keep = @()
    if (Test-Path -LiteralPath $f) {
        $keep = @(Get-Content -LiteralPath $f | Where-Object { $_.Length -le 66 -or $_.Substring(66) -ne $Target })
    }
    $keep += ('{0}  {1}' -f $Hash, $Target)
    Set-Content -LiteralPath $tmp -Value $keep -Encoding utf8
    Move-Item -LiteralPath $tmp -Destination $f -Force
}

function Get-DriftDirection {
    # 漂移方向（对齐 LDC ADR-0015 补注）——仅在 drift 状态下调用（落点须存在，Get-FileHash 不容缺失）：
    #   template-update 模板更新（落点自上次渲染未动——纯模板更新，重渲染无机器侧内容可失）
    #   machine         机器侧改动（模板自上次渲染未动）
    #   both            双向漂移（吸收会盖掉模板更新——需人工判读 diff 再定）
    #   unknown         无账本记录（账本丢失 / 首版升级机器）
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Target
    )
    $rec = Get-RenderedState -Target $Target
    if (-not $rec) { return 'unknown' }
    if ((Get-FileHash -LiteralPath $Target).Hash -eq $rec) { return 'template-update' }
    if ((Get-FileHash -LiteralPath $Source).Hash -eq $rec) { return 'machine' }
    return 'both'
}

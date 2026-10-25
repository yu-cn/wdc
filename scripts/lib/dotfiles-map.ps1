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

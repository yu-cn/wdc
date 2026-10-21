# dotfiles-map.ps1 — dotfiles 落点映射的单一事实源（install / verify / inventory 三方共读）
# 「仓库模板 → 机器落点」只在此声明一次：新增 dotfile 改这里，安装面与验收断言面自动同步（防清单漂移——
# 曾有 install 7 项 / verify 6 项的实际分叉，keybindings 漏验即其产物）。
# 纯数据与纯函数，不依赖 common.ps1，可被任何脚本单独 dot-source。

function Get-WtLocalStateDir {
    # Windows Terminal 机器本地状态目录（settings.json / fragments 所在；包 SID 路径唯一来源）
    Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'
}

function Get-DotfilesMap {
    # 每项：Name（展示名）/ Source（仓库内相对 dotfiles/ 的路径）/ Target（机器侧绝对落点）
    # WT 的 WSL profile 不在此列——那是机器派生值，由 install-wt-profiles.ps1 渲染（ADR-0004）
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

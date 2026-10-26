# 35: dotfiles 符号链接 reparse 缓冲双写路径（提权读失败根因候选）

**What to build:** 查明 dotfiles 符号链接的 reparse 缓冲区为何被双写目标路径，并定夺是否重建链接 + 是否修 `install-dotfiles.ps1` 建链方式。ASUS 实证（2026-10-24，`fsutil reparsepoint query C:\Users\User\.gitconfig` 提权采样）：substitute name 为 `D:\Devs\Repos\WDC\dotfiles\windows\gitconfig` 后紧跟 `\??\D:\Devs\Repos\WDC\dotfiles\windows\gitconfig`（两份路径拼接，Reparse Data Length 0xc4，远超单路径长度）。已证实影响：Git for Windows 升级器提权跑 `git config --system` 时 MSYS 解析该缓冲失败（Invalid argument），安装器 system config 写入步骤逐条弹错、旧 `etc/gitconfig` 被清——已提权直写恢复默认 11 项（见 collaboration.md 坑14③）；普通上下文全链路读写正常、verify 六组全绿，故平时无感。疑点：PowerShell `New-Item -ItemType SymbolicLink` 的双写缺陷形态；波及面待审计（gitconfig/bashrc/pwsh profile/VSCode settings+keybindings/WT settings/starship 各链接是否同款，fsutil 采样需提权逐个查）。

**Blocked by:** None

**Status:** done

## Comments

- 2026-10-24（ASUS 会话，Git 升级收口时发现）：候选方向供定夺——a) 提权审计全部 dotfiles 链接 reparse 缓冲，同款统一重建（删链重建单路径形态；建链权限姿势需确认：提权会话或 Developer Mode）；b) `install-dotfiles.ps1` 建链后自检 reparse 缓冲（断言单份路径），防新机器复发；c) 若判定双写无实害（普通读写全通、仅提权 git 受累），记「已知形态、不处置」——但每次升级 Git 安装器都会再弹一轮报错。
- 2026-10-26（LETH 会话，工单38 批次重分诊）：关单归档——研究对象（dotfiles 符号链接 reparse 缓冲双写）随 ADR-0015 渲染拷贝模型（v0.6.0）整体退役：两机 dotfiles 落点已是实体文件、`Test-DotfileInSync` 内容断言全绿（LETH 本日 `wdc status` 实测），符号链接不复存在，坑14③ 的提权读失败面随之消失，原列三方向（审计重建/建链自检/记不处置）全部失去对象。坑14 历史注记保留于 collaboration.md；不做残余链接审计（无残余）。若未来 Git 升级再报 system config 弹错，按坑14 的直写恢复配方处置，与本单无关。

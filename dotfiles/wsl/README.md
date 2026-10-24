# dotfiles/wsl — 已冻结（工单32 / ADR-0007）

Linux 侧模板（bashrc / gitconfig）的主作者位归姊妹仓库 **LDC**（[dotfiles/linux](https://github.com/yu-cn/ldc)）：
WSL 阶段委托 LDC 后，机器落点 `~/.bashrc` / `~/.gitconfig` 由 LDC bootstrap 重新链接到其仓库模板
（接管本目录产生的旧符号链接；机器私有段迁入 `.bashrc.local` / `.gitconfig.local`）。

- **勿再修改本目录内容**——改动不会到达任何机器，只会制造两份漂移源
- 一个过渡版本后本目录删除（bashrc / gitconfig 随删，README 先行）

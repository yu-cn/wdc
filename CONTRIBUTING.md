# 贡献指南

这是作者的个人开发环境仓库（dotfiles 性质），开源是为了参考与 fork——**最欢迎的用法是 fork 一份改成你自己的环境**，路径见 README「朋友怎么用」。

## 给本仓库提改进

- **判据**：只收「通用核心」——任何一台开发机都需要的改进（[ADR-0003](docs/adr/0003-universal-core-only.md)）。机器个性化的内容（某个 IDE 专属配置之类）请留在你自己的 fork。
- **方式**：直接开 GitHub Issue / Pull Request。`.scratch/` 本地工单流是仓库主人自己的内部流程，外部朋友不必使用。
- **CI**：PR 自动跑无副作用校验（`validate.ps1`：配置 schema + 脚本静态检查），本地可先 `pwsh validate.ps1` 自查。
- **语言**：散文用中文；标识符、命令、既定格式保持英文。

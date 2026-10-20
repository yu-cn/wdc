# 02: dotfiles 机制与身份文件

**What to build:** 环境主人运行 bootstrap 后，四份现有配置（gitconfig、bashrc、VSCode settings/keybindings、WT settings）以 symlink 就位，机器上同名旧文件被备份为 *.bak 而非覆盖；gitconfig 模板不含 [user] 段、include 每机本地的 ~/.gitidentity，bootstrap 发现缺失时生成占位并提示填写——未填写时 git 提交被拒绝（防错护栏演示）。新建 pwsh profile 初版就位（starship/zoxide/fzf 初始化，后续工单再补 vp source 行）。

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] 四份 dotfiles 入库并由 bootstrap 以 symlink 安装
- [ ] 目标位置已存在旧文件时生成 *.bak 备份，内容不丢失
- [ ] gitconfig 无 [user] 段，include ~/.gitidentity
- [ ] 身份文件缺失时 bootstrap 生成占位并给出填写指引
- [ ] 身份未填写时 git commit 失败（护栏生效）
- [ ] pwsh profile 存在且 starship 提示符在 pwsh 中生效

## Comments

- 2026-10-19（自主执行会话）：已完成并通过验收标准，实现落在对应 commit（git log 按工单号检索）。

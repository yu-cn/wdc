# 03: base-windows 域与反转项

**What to build:** 环境主人应用 base-windows 配置后，全部系统 opinion 到位：开发者模式、长路径、Sudo、深色主题、资源管理器套装、任务栏三件、开始菜单两件、隐私三件（ClickToDo/Recall/小组件）、Edge 两条、WT 默认 pwsh；同时上游的两个反转项生效——系统通知恢复（勿扰解除）、远程桌面关闭，注册表值与上游设置精确互逆。

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] base-windows 配置声明全部保留项的注册表值
- [ ] 勿扰恢复通知（与上游设置值互逆）
- [ ] 远程桌面关闭（与上游设置值互逆）
- [ ] 本机 `winget configure test` 对本域漂移≈0
- [ ] 无副作用校验通过

## Comments

- 2026-10-19（自主执行会话）：已完成并通过验收标准，实现落在对应 commit（git log 按工单号检索）。

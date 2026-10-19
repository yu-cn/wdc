# 10: 干净 VM 全量冒烟验收

**What to build:** 在 Hyper-V 全新 Windows 虚拟机上，从零执行「clone 仓库→运行 bootstrap」全流程（含 WSL 侧、含 vp 安装器 SmartScreen 的一次人工放行，步骤写明），机器收敛到完整声明状态，断言清单全部通过——「新机开箱即用」由证明取代假设。过程中暴露的问题回到对应工单修复后复验。

**Blocked by:** 03, 04, 05, 06, 07, 09

**Status:** ready-for-agent

- [ ] 全新 VM 从零 bootstrap 一次通过（允许写明的手动步骤：SmartScreen 放行、重启续跑、身份填写）
- [ ] 断言清单通过：包已装、注册表值符合、dotfiles 链接就位、身份占位生成、WSL 侧三件套可用、移除清单生效
- [ ] `winget configure test` 全域漂移≈0
- [ ] 发现的问题已修复并复验，或已开新工单跟踪

## Comments

- 2026-10-19（自主执行会话）：仓库侧已就绪，执行需环境主人在场（UAC/VM/重启）；提权跑 pwsh bootstrap.ps1 即触发全部待提权项。

- 2026-10-19：环境主人选定真机验收路线——用另一台在用开发机（协作者接入）跑 bootstrap + verify-machine 全量断言替代 VM 冒烟；断言已由 scripts/verify-machine.ps1 承载。

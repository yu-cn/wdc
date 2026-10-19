# 10: 干净 VM 全量冒烟验收

**What to build:** 在 Hyper-V 全新 Windows 虚拟机上，从零执行「clone 仓库→运行 bootstrap」全流程（含 WSL 侧、含 vp 安装器 SmartScreen 的一次人工放行，步骤写明），机器收敛到完整声明状态，断言清单全部通过——「新机开箱即用」由证明取代假设。过程中暴露的问题回到对应工单修复后复验。

**Blocked by:** 03, 04, 05, 06, 07, 09

**Status:** ready-for-human

- [x] 全新机器从零 bootstrap 一次通过（真机路线：第二台开发机 ASUS，协作者接入；手动步骤=UAC×2 + 身份自动迁移，无需 SmartScreen 放行与重启）
- [x] 断言清单通过：verify-machine.ps1 全绿（dotfiles 链接/注册表/移除清单核销/语言栈/WSL 侧，2026-10-19 23:36）
- [x] `winget configure test` 全域漂移=0（base-windows / cli-tools / editors）
- [x] 发现的问题已修复并复验，或已开新工单跟踪（工单 11-14；12 已修复复验，11/13/14 留主机会话定夺）

## Comments

- 2026-10-19（自主执行会话）：仓库侧已就绪，执行需环境主人在场（UAC/VM/重启）；提权跑 pwsh bootstrap.ps1 即触发全部待提权项。

- 2026-10-19：环境主人选定真机验收路线——用另一台在用开发机（协作者接入）跑 bootstrap + verify-machine 全量断言替代 VM 冒烟；断言已由 scripts/verify-machine.ps1 承载。

- 2026-10-19（第二台机会话）：真机验收完成，全绿。过程暴露并当场修复三类脚本缺陷（vp 双布局探测、同 ID 多版本卸载歧义、dotfiles eol 防护），另发现 -ValidateOnly 越权执行 dotfiles（工单11）与 WSL vp env 编排缺口（工单13）留定夺。详见工单 11-14 与对应 commit（eb72dd9…）。反向吸收素材已产出：`.scratch/inventory-ASUS-20261019.md`。

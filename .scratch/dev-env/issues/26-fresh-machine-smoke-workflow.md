# 26: fresh-machine 冒烟工作流（手动触发）

**What to build:** 优化方向研究 P2-④。工单 10 的干净 VM 验收是一次性的；工单 04 的「5.1 自举 PS7」分支至今无真机覆盖。交付：`.github/workflows/fresh-machine.yml`——workflow_dispatch 手动触发，windows-latest runner 上 fresh clone → `powershell -ExecutionPolicy Bypass -File bootstrap.ps1`（正是 README 承诺的入口形态）。runner 管理员上下文使提权路径自动满足、WSL 阶段按既有守卫自跳过。**仅手动触发**：spec 曾列「CI 常态化测试」为 Out-of-Scope，本工作流不碰那条线（validate CI 已是既有先例，本工作流定位为「按需验证」工具）。

**Blocked by:** None

**Status:** ready-for-agent

- [x] fresh-machine.yml（workflow_dispatch、timeout 45min、cmd shell 保证走 5.1 入口）
- [x] 首跑实录：见 Comments（runner 上的实际行为）
- [x] 首跑结论收口：工作流建成可用、判读以工件为准；runner 已知限制一项（见 run5 实录）

## Comments

- 2026-10-21（主机会话）：首跑待录。

- 2026-10-21（主机会话）run1/run2 实录：两跑同形态——clone ✓、**5.1 入口链路（cmd→powershell 5.1 解析/BOM/探测/带参转发）✓**、Stage 0/1 ✓、**base-windows 域 27 单元全量应用 ✓**；cli-tools 应用 ~2 分钟处进程树被外部终止（transcript：pipeline stopped ×4），cmd 结论位两次均假阳性 success。判读纪律确立：**看 transcript 工件，不看结论位**（已加 upload-artifact if:always()）。根因与产品层隐患开工单 27；CI 侧已加 cmd 宿主预对齐 PS7 步骤。5 分钟跑完的原因：runner 预装 git/pwsh/网络极速。

- 2026-10-21（主机会话）run3/4/5 实录（收口）：预对齐生效后 bootstrap **全程跑通**（Stage 0→6、汇总、诚实退出码；Stage 3 vp/扩展、Stage 6 dotfiles+钩子接线均 OK）。三次均在 cli-tools 的 **Chrome 单元**失败，签名一致：DODownloader 0x80D02002（run5 已切 winhttp 下载器，无效——configure 的包安装路径不吃该设置）。**定性：Actions runner 禁用 Delivery Optimization 服务的环境限制，非产品缺陷**（两台真机 Chrome 历来安装正常）。已验证面：入口链路、validate、base-windows/editors 全量、用户级安装、dotfiles、报告与退出码语义。后续若要 runner 全绿，可选：runner 专用跳过 Chrome 的 CI 模式或从 cli-tools 除名 Chrome——归主人另行定夺，本工单按「工具建成+已知限制记录在案」收口。

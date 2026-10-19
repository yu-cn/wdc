# Handoff：第二台开发机上的 ZCode 会话接手指南

> 写于 2026-10-19，由主开发机（已收敛）的会话交付。你（新会话）在**另一台开发机**上，
> 任务 = 工单 10 的真机验收 + 反向吸收素材采集。全部背景在仓库里，本文只做导航与预警。

## 背景（一段话）

WDC 是环境主人的个人 Windows 开发环境声明式仓库（基于 microsoft/WindowsDeveloperConfig 自建，不 fork）。
主开发机已完全收敛：三域配置全绿、22 项机器断言全绿。本机（你所在的机器）是第二台开发机，
刚被加为 GitHub 私有仓库 `yu-cn/WDC` 的协作者。词汇与决策见仓库根 `GLOSSARY.md` 与 `docs/adr/`（必读，
尤其 ADR-0003 通用核心判据：只有每台机都需要的才进核心，个性是机器自留地）。

## 你要驱动的任务（按序）

1. 确认 `gh auth login` 已用**本机的协作者账号**完成，clone 本仓库
2. `pwsh bootstrap.ps1` —— 环境主人需要配合的四件事见 README「快速开始」（UAC / SmartScreen 放行 vp /
   若本机未启用过 WSL 会要求重启续跑 / 填写**本机**的 `~/.gitidentity`）
3. `pwsh bootstrap.ps1 -NoElevate` —— 补齐 WSL 阶段（提权上下文跑不了，见下坑①）
4. `pwsh scripts/verify-machine.ps1`（全量约 3 分钟）—— **这就是工单 10 的验收**，
   全绿 = 达标；任何 FAIL 逐项排查（断言脚本只读、可反复跑，`-Quick` 秒级）
5. `pwsh scripts/inventory-machine.ps1 > .scratch/inventory-<本机名>-<日期>.md` ——
   反向吸收素材（严格只读盘点），**commit 并 push 回仓库**，主机会话将据此与环境主人逐项勾选吸收
6. 若 bootstrap/断言出问题：先看 `logs/bootstrap-*.log`（每次运行自动留痕）

## 已知坑（主开发机用半天踩出来的，全部已修在代码里，你只需知道行为）

1. **wsl.exe 在提权上下文 + 管道捕获输出会挂死**（可致 WSL 服务楔死，解法=重启电脑）——
   bootstrap 的 Stage 5 已加提权跳过守卫，所以必须跑两遍（提权 + `-NoElevate`），这不是 bug 是设计
2. **vp 安装器未代码签名**——首次 SmartScreen 弹窗需环境主人手动放行
3. **控制台乱码只是显示问题**（GBK 代码页）——bootstrap 已自设 UTF-8；若在其他窗口看到乱码不影响执行
4. **winget 退出码语义**：validate 的 1 = 仅警告（良性），负 HRESULT 才是错；`configure test`
   的漂移判定看「未处于」计数 + 退出码
5. 本机若已登过 VSCode 账号：**不要开设置同步**（README 第 5 步）——仓库是唯一主人，
   云同步会与 dotfiles 符号链接打架

## 与环境主人协作的方式

- **一次只问一个问题**，不要批量出题（明确偏好）
- 事实自己查（脚本/仓库），决策交给环境主人
- 吸收勾选参照主机会话处理上游的做法：沉默=自留地，点名=进核心

## 建议技能（本机已装全套 matt skills）

- 出故障排查：`diagnosing-bugs`（先建反馈回路再动手；logs/ 下的 bootstrap 日志就是现成的现场）
- 需要改仓库代码修复问题时：`implement`（小修直接 commit main，pre-commit 钩子会把关；大改先在 `.scratch/` 开工单）
- 发现的问题不一定要当场修：在 `.scratch/<feature>/issues/` 开一张工单（约定见仓库 AGENTS.md），
  两侧机器共用同一个本地 tracker，主机会话会接走
- 本机任务是脚本驱动为主，预计用不上 spec/tickets 类技能

## 红线

- 机器自留地（本机自装的 JetBrains/Typora 等）**一概不碰**（ADR-0003）
- `~/.gitidentity` 内容不得出现在任何产出物里
- 不引入新决策：有拿不准的，记入 `.scratch/` 留给主机会话

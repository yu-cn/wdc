# 01: get.ps1 远程一键引导 + README 快速开始改造

**What to build:** 新机器在零前置（不预装 Git、不手动 clone）下，粘贴一条命令即可走完
「装 Git（缺则）→ 定位/clone 仓库 → bootstrap 全流程」。

**Blocked by:** None (can start immediately)

**Status:** done

- [x] `scripts/get.ps1`：5.1 可解析 + UTF-8 BOM；winget 预检；缺 Git 自动 `winget install Git.Git`
      + 注册表重组 PATH 探测；`~/.wdc` 指针复用 / `~\wdc` 缺省 clone（已存在非仓库目录不代删）；
      转发 `bootstrap.ps1` 并透传退出码
- [x] README 快速开始：单条命令为入口 + 审阅链接 + 手动三行保留；「使用与改造」补 fork 例外句
- [x] validate.ps1 全绿（PSScriptAnalyzer Error 级通过 get.ps1）

## Comments

- 2026-10-25（自主执行会话）：已完成。决策背景与否决项见同目录 [spec.md](../spec.md)。
  未做真机端到端试跑（会触发完整 bootstrap 收敛 + UAC，超出无副作用边界）——
  覆盖面 = 5.1 解析 + PSScriptAnalyzer + 逻辑对齐 bootstrap.ps1 既有 winget 段；
  首位真实用户跑通前保留手动三行兜底。姊妹仓库 LDC 侧同日对等实施（get.sh）。

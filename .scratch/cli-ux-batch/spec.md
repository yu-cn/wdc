# cli-ux-batch：CLI 体验优化批（2026-11-07 主人定夺「尽可能都做，充分优化」）

## 背景

主人问「wdc/ldc 有没有命令补全」引出全面体检：两仓 CLI（wdc.ps1 / ldc bash 脚本）无 Tab 补全、
wdc fetch 无超时禁交互防护、status 无机器可读出口、wdc 缺 plan、子命令表多处手抄、`-h` 挂子命令
语义不对。主人定夺全量吸收。联动 LDC `.scratch/cli-ux-batch/` 同批同结构推进（双仓统筹按序：
LDC 先行 cli-parity 契约主作者位，WDC 拷贝）。

## 票目

| # | 主题 | 性质 |
|---|------|------|
| 01 | fetch 超时 + 禁交互防护（status/sync） | 健壮性（ldc 已有同款，wdc 补齐） |
| 02 | `wdc status -Json` 机器可读出口 + 退出码注册表进 help | 新能力 |
| 03 | `wdc plan` 干跑预演（sync 流投影 v1） | 新能力（ldc 已有，wdc 对齐） |
| 04 | 子命令表单一来源 + 子命令 `-h` 落单命令详解 | 一致性 |
| 05 | Tab 补全（pwsh ArgumentCompleter + Git Bash complete） | 新能力 |
| 06 | sync 完成 BEL 通知 | 体验 |
| 07 | cli-parity 契约挂 dev-standard-guard + validate 断言 | 防漂移（Blocked by LDC 侧契约先行） |

## 跨仓统筹

- `docs/cli-parity.md` 双仓同源拷贝，主作者位 LDC（先 LDC 提交、WDC 同批拷贝——工单07）
- 退出码语义不动（wdc 0/1/3、ldc 0/1/2），只做文档化与契约化，不重编
- 门面（README 命令表）随收口同步

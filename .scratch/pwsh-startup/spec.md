# pwsh 启动慢：诊断定案与优化批次

主诉（环境主人，2026-11-14）：Windows Terminal 里开 PowerShell 要等好久，加载配置有时约 10 秒。

## 真机诊断数据（ASUS，2026-11-14，pwsh 7.6.10，热态）

分步基准（复刻 profile 各步骤，含 Invoke-Expression 求值；两轮高度一致）：

| 步骤 | 热态耗时 | 说明 |
| --- | --- | --- |
| `mise activate pwsh` + 求值 | ~860ms | 外层 spawn 172ms + IEX 359ms（生成脚本内含 hook-env 调用面） |
| `starship init` + 求值 | ~700-820ms | **双层 spawn**：init 产物仅 117 字节，内容是再嵌套 `starship init powershell --print-full-init` |
| `uv generate-shell-completion` + 求值 | ~670ms | 产物 **766KB**，纯求值 444ms |
| PSReadLine 模块导入 | ~650ms | 宿主首提示符本就要导——非 profile 净增，不可省 |
| dotfiles 漂移检查 | ~250ms | 工单24 设计（含 git status ~80ms） |
| `zoxide init` + 求值 | ~110ms | |
| `gh completion` + 求值 | ~200ms | 求值仅 17ms——成本在 spawn |
| fzf 键位注册 | ~65ms | |

profile 小计 ~3.3s；开窗实际热态 4~5s（+ 宿主启动 + 首提示符 hook-env ~166ms + starship prompt 渲染）。

同操作全量耗时在本轮实测中 1.8s ↔ 6.7s 摆动（系统负载波动）；冷启动（开机首次，各二进制冷页调入 + JIT）放大至 ~10s——与主诉吻合。

## 根因

profile 对**每份静态产物**（工具输出不随会话变）每次开终端都重新 spawn 工具进程并求值生成脚本：starship 双层 spawn、uv 求值 766KB、gh 纯 spawn 成本。6 次 spawn + 4 次大脚本求值是结构性成本，负载波动与冷启动在其上放大。

## 已排除

- 杀软：Windows Defender 禁用（服务未运行，0x800106ba），SecurityCenter2 无第三方注册
- PATH：21 项全部存在、无 UNC 断连项
- OneDrive Documents 重定向：无
- profile 联网操作：无（全本地）
- CPU / 内存：Ultra 7 155H（22 逻辑核）负载 15%、32GB 正常

## 优化方向（拆两票）

1. [issues/01-init-artifact-cache.md](issues/01-init-artifact-cache.md)：starship / gh / zoxide 静态产物 bootstrap 缓存（预期热态省 ~0.8-1s）
2. [issues/02-uv-completion-lazy.md](issues/02-uv-completion-lazy.md)：uv 补全惰性加载（预期热态再省 ~650ms）

两票合计热态 4~5s → 2.5~3s；冷启动按比例缩至 ~5-6s。

## 明确不动（后续可另议）

- `mise activate`（~530-860ms）：按目录切环境的设计取舍（profile 头注释立意），shims 化是架构级改动
- 漂移检查延后（~250ms）：工单24「开新终端即见」立意，动它是产品决策
- PSReadLine 导入：宿主固有成本

## 测量方法（复现）

分步基准：`pwsh -NoProfile` 会话内 `[Diagnostics.Stopwatch]` 逐项计时，步骤须**含 Invoke-Expression 求值**（漏求值会低估——首轮基准曾因此把 starship 记成 99ms，实际 ~700ms）。spawn 与求值分离：产物先落盘，再分别测「仅 spawn」「仅 IEX 缓存脚本」。全量对照：`time pwsh -Command exit` 与 `pwsh -NoProfile -Command exit` 差值。

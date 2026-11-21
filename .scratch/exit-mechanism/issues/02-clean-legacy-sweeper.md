# 02 wdc clean-legacy 签名清扫（层1）

Status: ready-for-agent
Type: task

## 内容

`wdc clean-legacy`：按**签名**全量扫已知历史残留物（不按版本号——版本→残留映射不可靠，签名幂等、新机器零误除），逐项报告 + `-Fix` 清理 SafeToFix 项（默认纯报告恒 exit 0，对齐 audit 对账口径）。八节清单（坑档+ADR 考古，随机制退役持续补充）：符号链接落点 / WT fragments 四路径 / Cascadia per-user 字体 / vp 三布局+PATH / uv 双装遮蔽 / 死计划任务 / 状态目录陈旧物 / LDC 孤儿 backup。后五类永远只报告（处置各有正道：重跑自愈 / triage / 手删 / LDC 定夺）。fresh-machine CI 零发现断言腿另票。

## 验收

- [x] 清单全项扫描在 LETH 真机跑过一轮，报告与实际残留一致（2026-11-21：发现 2 项报告类——Cascadia per-user 2 文件、uv `.local/bin` 副本，处置归主人；其余六节干净；ASUS 待跑）
- [x] 幂等（报告模式重跑输出一致）；只报告不确认不删（uv 遮蔽类永远只报告——报告/-Fix 双态实现，报告模式零变更）
- [x] wdc 子命令表/帮助/Tab 补全/cli-parity 契约同步（命令面变更四件套；契约按「主作者位 LDC 先行」流程：LDC 1754183 已推，WDC 同步拷贝）
- [x] validate 全绿（pre-commit 实证）

## Comments

- 2026-11-21 实施实录：① schtasks CSV 表头随系统语言本地化（中文系统无 TaskName 属性——坑1「输出随语言变」同族），改按首列位置取值（列序稳定）；② `Invoke-WslBounded` 返回 `{Lines,Exit}`、参数为 `-ArgumentList/-TimeoutSeconds`（初版写错已修）；③ 分节 $found 基线防止跨节 OK 抑制。执行体 `scripts/clean-legacy.ps1`（自包含 dot-source common+dotfiles-map），wdc.ps1 增 `clean-legacy` 子命令与 `-Fix` 旗标透传。

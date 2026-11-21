# 02 wdc clean-legacy 签名清扫（层1）

Status: ready-for-agent
Type: task

## 内容

`wdc clean-legacy`：按**签名**全量扫已知历史残留物（不按版本号——版本→残留映射不可靠，签名幂等、新机器零误伤），逐项报告 + 确认后清理。清单（坑档+ADR 考古，随机制退役持续补充）：

- pre-ADR-0015 符号链接落点（fork 用户/老机器：dotfiles-map 落点若为 ReparsePoint/symlink 即报）
- WT fragments 四路径（ComfortShell/DevConfig/WDC 官方路径 + 包内旧路径——remove-leftovers 1/3 节已有，同源复用）
- Cascadia 字体（已从上游除名，`.scratch/cascadia-font-source/` 有案）
- vp 三布局目录 + 用户 PATH 注入（remove-leftovers 2/3 节已有，同源复用）
- uv 双装遮蔽（`.local/bin` vs winget——报告不自动删，主人 triage）
- 死计划任务（`WdcBootstrapResume`、`WDC-GitUpgrade-*`）
- `%LOCALAPPDATA%\wdc` 陈旧文件（渲染账本/cache 之外的不明物）
- LDC 孤儿 backup（`~/dev/ldc/backup/orphan-*`——WSL 侧，报告为主）

设计：与 remove-leftovers 关系=后者是收敛随航（bootstrap 每跑必过）、本命令是显式大扫除（手动触发）；签名检测逻辑单一来源共用。fresh-machine CI 可加一腿断言零发现（防新机制退役时忘登清单）。

## 验收

- [ ] 清单全项扫描在 LETH/ASUS 真机跑过一轮，报告与实际残留一致（两机预期接近零——随航清理常年生效）
- [ ] 幂等（重跑零 CHANGED）；只报告不确认不删（uv 遮蔽类永远只报告）
- [ ] wdc 子命令表/帮助/Tab 补全/cli-parity 契约同步（命令面变更四件套）
- [ ] validate 全绿

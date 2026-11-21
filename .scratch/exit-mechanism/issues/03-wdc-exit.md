# 03 wdc exit 三档退出命令（层2）

Status: needs-triage
Type: task
Blocked by: 01, 02

## 定夺点（待主人，2026-11-21 会话提出未答）

1. **T2 语言栈分界**：A 声明面全退数据面不动（推荐——卸 configs 三域全部含 mise/uv 本体；runtime/venvs/cache/node_modules 数据不碰，与 ADR-0007「不卸语言栈」精神兼容）/ B 连运行时数据一起退（mise/uv 自卸 runtime，删数据误伤面大）/ C 语言栈整体保留（mise/uv 是 WDC 声明的包却不卸，与「完整退出」语义不自洽）
2. **默认档位**：建议 T2（完整退出）为 `wdc exit` 默认，T1/T3 显式旗标（`-KeepTools` / `-WithWsl`）
3. **无快照降级语义**：存量机恢复注册表按 undo 表 Windows 默认值（不追补快照），exit 输出明示「已恢复默认值而非你的原始值」

## 内容

三档（详见 spec 层2）：T1 状态退出（%LOCALAPPDATA%\wdc、`~/.wdc`、schtasks、账本——环境原样）；T2 完整退出（+ configs 三域逐 Id 卸载【坑7 逐版本语义】+ 注册表还原【快照优先】+ VSCode 32 扩展卸载 + dotfiles 落点处置【有 .bak 还原、无 .bak 删除；.bak 本体=首次渲染前原文件且永不清】+ fragments 清扫）；T3 全清含 WSL（.wslconfig 还原 + wsl.conf 声明键摘除 + LDC 委托——`ldc` 在则调、不在打印指引；LDC 卸载器归 LDC 仓另议）。

收尾 `verify-exit` 断效果（包不在/键还原/落点处置完成）——对齐仓库断言传统（坑11：断效果不断实现）。红线：退出不碰机器自留地（ADR-0003 精神）。需 ADR-0010 承接（退出语义 + 三档口径 + 拒绝项）。

## 验收

- [ ] ADR-0010 立案（含上述定夺点的定夺记录）
- [ ] 三档实现 + verify-exit 断言；幂等（重跑零变更）
- [ ] fresh-machine CI 加 exit 腿（bootstrap → 重跑幂等 → exit → 断言干净）可选评估
- [ ] wdc 命令面四件套同步 + validate 全绿；CHANGELOG 记账

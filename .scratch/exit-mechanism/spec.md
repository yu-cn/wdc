# spec · 退出机制 + 版本残留清扫（ADR-0009 退出面）

## 问题

ADR-0009 定位改一次性配置后，退出路径成为产品缺口（对照 microsoft/WindowsDeveloperConfig：其有 uninstall.ps1 + 每项设置 undo 文档，但也明说 "previous settings are not restored"）。同时主人 2026-11-21 指出「之前 wdc 版本可能也要有清理机制，避免多个版本共存混乱」——同机多版本的真实形态不是多副本，而是**历史机制残留物**（每代机制退役时靠 remove-leftovers 随航清理，缺显式全量扫）。

## 定夺

主人 2026-11-21：退出机制很有必要，版本残留清理机制同样要（方向定夺；分界细节见工单03 定夺点，待主人裁）。

## 方案（三层，按序）

- **层0 地基**（工单01）：pre-install 注册表快照（bootstrap 首次 apply 前 `reg export` 27 个 keyPath 到 `%LOCALAPPDATA%\wdc\pre-install\`，marker 守卫一次性）+ 逐项 undo 表文档（docs/undo-table.md，微软同款透明度；exit 时快照优先、无快照降级 Windows 默认值——存量机无快照是事实，表格兜底）。
- **层1 清扫**（工单02）：`wdc clean-legacy`——**按签名识别历史残留物，不按版本号识别**（版本→残留映射不可靠；签名幂等、新机器零误伤）。已知清单：pre-ADR-0015 符号链接落点（fork 用户）、WT fragments 四路径、Cascadia 字体、vp 三布局+PATH、uv 双装遮蔽、死计划任务（WdcBootstrapResume/WDC-GitUpgrade-*）、`%LOCALAPPDATA%\wdc` 陈旧文件、LDC 孤儿 backup。服务升级除乱与 exit 前大扫除两场景；fresh-machine CI 可加零发现断言腿。
- **层2 退出命令**（工单03，`wdc exit`，ADR-0010 待立）：三档——T1 状态退出（只删 WDC 机器状态，环境原样）；T2 完整退出（建议默认：T1 + configs 三域逐 Id 卸载【坑7 逐版本语义】+ 注册表还原 + VSCode 扩展卸载 + dotfiles 落点处置【有 `.bak` 还原、无 `.bak` 删除——.bak 本体=首次渲染前原文件且永不清，现成恢复锚点】+ fragments 清扫 + verify-exit 断效果）；T3 全清含 WSL（.wslconfig 还原 + wsl.conf 声明键摘除 + LDC 委托——LDC 卸载器归 LDC 仓另议）。

## 边界

- 红线延伸：退出不碰机器自留地（ADR-0003 精神）
- 不做跨机版本一致（ADR-0009 已弃）；不做版本号驱动清理
- **工单03 定夺点（待主人）**：① T2 语言栈分界——推荐 A「声明面全退数据面不动」（卸 configs 全部含 mise/uv 本体；runtime/venvs/cache 数据不碰，与 ADR-0007 精神兼容）/ B 连运行时数据一起退 / C 语言栈整体保留；② T2 是否为默认档；③ 语言栈之外的存量机无 pre-install 快照，降级语义确认为「恢复 Windows 默认值」
- LDC 侧卸载器不在本 spec 范围（双边最优化，LDC 仓另议）

## 工单

- [ ] 01 pre-install 快照 + 逐项 undo 表（层0）
- [ ] 02 wdc clean-legacy 签名清扫（层1）
- [ ] 03 wdc exit 三档退出命令（层2，Blocked by 01,02；含定夺点）

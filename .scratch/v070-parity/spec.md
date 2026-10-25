# Spec：对齐 LDC v0.7.0（CHANGELOG 标准 / wdc audit / 漂移方向判定 / demo 嵌播）+ 验证瘦身专项

## 背景

LDC 已发布 **v0.7.0**（2026-10-26）：清单准入对账（`ldc audit`）、etckeeper 可选包组、漂移方向判定实装（ADR-0015 补注）、CHANGELOG 对齐 Keep a Changelog、README 首屏终端速览（cast → agg GIF 嵌播）。实现锚点：LDC commits `5983ea2`（四项）/ `d6d1856`（CHANGELOG+demo）/ `63b9162`（changelog 收节 + dev-standard §5 同步入册）。本仓渲染拷贝已落地（commit `020f74c`，Test-DotfileInSync 三态函数在位）——方向判定的依赖前提已就位。

主人 2026-10-26 指示「WDC 同步跟进」。双仓共用规范落 LDC（dev-standard §5 已补「CHANGELOG 同步」行），本票负责 WDC 侧拷贝对齐与实现。

## 范围（四项对齐 + 一项否决）

1. **CHANGELOG.md**：新建，Keep a Changelog 1.1.0——Unreleased 置顶、Added/Changed 分类、版本 compare 链接表，回填全部既有 release（`gh release list` 取清单）；头部声明配套 SemVer 与 Conventional Commits。dev-standard §5 的「CHANGELOG 同步」行随拷贝对齐（与 LDC 侧 diff 校验一致）。
2. **wdc audit 对账**：winget 清单（`configs/*.winget`）vs 实装。实现前先查 `winget list` 输出格式与噪声面（坑4 退出码语义、坑13 identity MSIX）；可分级落地——「已声明未装」方向（逐 Id 核销）先行，「自装未声明」方向噪声大、可降级为 INFO 计数或暂缓。落 `scripts/audit-machine.ps1` + `wdc.ps1 audit` 子命令（裸命令不带动作的体验约定不变）。
3. **漂移方向判定**：对等 LDC rendered 账本——状态文件 `%LOCALAPPDATA%\wdc\rendered.sha256`（Get-FileHash SHA256，格式自定义），`Test-DotfileInSync` 扩展方向判定（template-update / machine / both / unknown），`install-dotfiles.ps1` 渲染后记账 + 纯模板更新免 `.bak` 直渲染，triage 逐项标注方向（双向漂移警示吸收会盖掉模板更新）。
4. **demo 首屏嵌播**（主人 2026-10-26 指示必做）：真实命令输出生成 demo.cast（脱敏）→ [agg](https://github.com/asciinema/agg) 转 GIF → README 首屏；`.gitattributes` 补 `*.gif binary`（坑8 同款）。
5. **否决**：etckeeper 无 Windows 对等（`/etc` 专属；Windows 系统配置留痕不在本票范围，将来如有需求另开票）。
6. **验证瘦身专项**（主人 2026-10-26 指示并入 0.7.0 工作计划，工单 02）：冒烟 WSL 段交界面化（不委托 LDC bootstrap 安装全程，LDC 本体验证让位给 LDC 容器冒烟）+ `wdc sync` 收尾 verify 降 -Quick + winget 开销优化（pull 无更新跳 validate / 零漂移跳 apply，以实测定案）。背景拆解与基线数据见工单 02。

## 验收清单

- [x] CHANGELOG.md 入仓：Unreleased 置顶 + 既有 release 全回填 + compare 链接可用
- [x] dev-standard.md 与 LDC 侧 diff 一致（含 §5「CHANGELOG 同步」行）
- [x] wdc audit：两方向实跑（至少已声明未装方向落地）、幂等重跑结果稳定
- [x] 漂移方向判定真机验证：改模板 → template-update 免 .bak；改落点 → machine 走轮转备份；triage 方向标注
- [ ] 验证瘦身（工单 02）：冒烟 WSL 交界面化 + sync 收尾 -Quick + winget 优化，基线对照实测入档
- [ ] validate.ps1 全绿（windows-latest CI 锚 run id）
- [x] demo GIF 首屏嵌播（必做——主人 2026-10-26 补充指令）

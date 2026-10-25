# 01: v0.7.0 对齐——CHANGELOG 标准 / wdc audit / 漂移方向判定 / demo 嵌播

**What to build:** 按 `.scratch/v070-parity/spec.md` 对齐 LDC v0.7.0 的四项。开工前 `git pull` 到最新并确认 copy-render（`020f74c`）已收口、无其它会话在 WDC 上（并行规则）。LDC 侧参照实现：`scripts/audit-machine.sh`（对账逻辑）、`scripts/lib/common.sh` 的 `render_state_*` / `drift_direction`（账本与四方向）、ADR-0015 补注、CHANGELOG.md 成品样例。逐项施工面：

1. **CHANGELOG.md（先行项，零依赖）**——新建于仓根。头部三行声明：格式 Keep a Changelog 1.1.0（中文页）/ 版本 SemVer（v0.x 破坏性走 MINOR）/ 提交 Conventional Commits。`gh release list` 取全部既有 release 回填版本节（Added/Changed 分类归并，主题句入 Added；0.1.0 用 tag 链接而非 compare）。链接表：`[Unreleased]: …/compare/<最新tag>...HEAD` + 各版本 compare 对。注意 dev-standard §5 已由 LDC 侧补「CHANGELOG 同步」行——本项顺带把 docs/dev-standard.md 与 LDC 侧拷贝对齐（全文 diff 校验一致，主作者位 LDC）。
2. **漂移方向判定（依赖 copy-render 已落地）**——状态文件 `%LOCALAPPDATA%\wdc\rendered.sha256`（目录不存在则建；写坏可丢——缺失即 unknown，下次渲染自愈，与 LDC 语义同构）。`dotfiles-map.ps1` 的 Test-DotfileInSync 就地扩展：返回对象加 Direction 属性（template-update / machine / both / unknown），记账/读取为两个纯函数（不依赖 common.ps1 性质保持）。`install-dotfiles.ps1`：渲染成功后记账；落点指纹==上次记账（template-update）时跳过备份直渲染（LDC 实录：这消除每次改模板的 .bak 噪声）。`triage-dotfiles-drift.ps1`：漂移项标注方向，both 附警示。profile/bashrc 漂移提示若已改内容比对，直接复用状态函数。
3. **wdc audit（研究先行）**——先实查 `winget list` 输出与噪声（坑4：validate=1 良性；坑13：identity MSIX 按 SignatureKind 过滤）。落 `scripts/audit-machine.ps1`：方向①已声明未装（configs/*.winget 逐 Id 核销，标注所属清单）；方向②自装未声明（winget 全量 − 清单并集，噪声大——首版降级为 INFO 计数 + 头部 N 项即可，深挖暂缓）。`wdc.ps1` 加 audit 子命令（只读恒 exit 0；子命令校验在仓库定位之前的既有约定不破）。
4. **demo 首屏嵌播（必做——主人 2026-10-26 补充指令）**——真实命令输出（wdc status / plan 如有 / verify -Quick）生成 `docs/demo.cast`（脱敏：机器名/用户名/真实路径），[agg](https://github.com/asciinema/agg) 转 GIF（参考 LDC：3.8s cast → 545KB GIF；`--font-size 13 --speed 2`），README 徽章下方 `<p align="center">` 嵌入 + 源文件链接；`.gitattributes` 补 `*.gif binary`。

**Blocked by:** None（copy-render 已落地；按并行规则待当前会话收口后认领）

**Status:** ready-for-agent

- [ ] CHANGELOG.md（回填全部 release + 链接表）+ dev-standard §5 拷贝对齐
- [ ] 渲染账本 + Test-DotfileInSync 方向扩展 + install-dotfiles 免 .bak + triage 方向标注
- [ ] wdc audit 子命令 + audit-machine.ps1（至少已声明未装方向）
- [ ] 真机验证：WT 写落点 → machine；改模板 → template-update 免 .bak；audit 幂等
- [ ] validate.ps1 绿 + CI run id 入档（Comments）
- [ ] demo GIF 首屏嵌播（必做——主人 2026-10-26 补充指令）

## Comments

- 2026-10-26（LDC 侧会话代立）：依据 LDC v0.7.0 发布与主人「WDC 同步跟进」指示代立。语义争议以 LDC 对应实现与 ADR-0015 补注为准；CHANGELOG 格式标准以 keepachangelog.com 1.1.0 中文页为准。发布 vX.Y.0 由主人指令触发。

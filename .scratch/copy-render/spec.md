# Spec：dotfiles 渲染拷贝对等实施（Windows 侧，对齐 LDC ADR-0015）

## 背景

LDC 已于 2026-10-25 完成 dotfiles 渲染拷贝反转并发布 **v0.6.0**（决策全文：LDC 仓库 `docs/adr/0015-copy-render-not-symlink.md`；实现 commits `30d7454`/`dcf442e`；工单实录：LDC `.scratch/copy-render/spec.md`）。双仓共用决策落 LDC 编号、WDC 侧引用不复制（dev-standard §3）——本 spec 不复制 ADR，只给实施摘要；语义争议以 ADR-0015 原文为准。

反转动机（Windows 侧自己的实录）：WT/VSCode/gh 写穿符号链接污染仓库是唯一复发事故类（坑6/坑14，工单14/17/24）；symlink reparse 双路径痛（工单35）；仓库缺席=死链失联（坑15 记录的 LDC 侧事故同构）。

## 决策摘要（引自 ADR-0015，权威以原文为准）

1. 落点 = 安装期渲染拷贝（Copy-Item），模板仍是唯一声明源；落点映射 `dotfiles-map.ps1` 单一来源地位不变
2. 覆盖前轮转备份 `.bak` / `.bak.N`（既有 `Get-BackupPath` 语义即 ADR 所要的，保留）；同内容幂等跳过；符号链接残形直接替换不备份
3. 可见性迁移：verify / wdc status 改「落点内容与模板一致」内容比对（断效果不断实现——坑11 教训）；「dotfiles 模板与 HEAD 一致（防写穿）」断言退役
4. triage 平移：漂移=落点≠模板；吸收=落点回写模板（显式 pathspec commit，「禁 git add -A」红线不变）；还原=自模板重渲染
5. 例外与既有不变项：`ubuntu.ico` 本就是拷贝安装（不动）；`~/.wdc` 指针机制不动；WSL 侧不受影响（委托契约调 LDC bootstrap/verify——LDC v0.6.0 入口参数与退出码未变）

## 验收清单

- [ ] validate.ps1 全绿（本机无 pwsh 环境提交走 CI 兜底——windows-latest）
- [ ] 本机（ASUS）bootstrap 重跑：7 项落点由符号链接自动迁移为渲染拷贝（内容不丢，最早原件 .bak 保全）
- [ ] 幂等：第二遍 bootstrap 零 CHANGED（**LDC 教训必读**：接管类判据不能依赖「落点是不是链接」——「已完成」的标记是产物不是形态，见下施工须知）
- [ ] verify -Quick 全绿（内容比对断言）；实测漂移链路：手改一个落点 → verify 抓到 → triage 吸收/还原双向
- [ ] pwsh profile / Git Bash bashrc 的漂移即时提示（工单24 产物）改读内容比对后观感正常（新开终端即见、零误报）
- [ ] fresh-machine 冒烟 workflow 绿（手动触发，锚 run id）
- [ ] 文档对齐：AGENTS.md 坑6 更新、GLOSSARY 写穿/分流词条、README 两处、inventory-machine.ps1 触点
- [ ] 发布 vX.Y.0（feat→MINOR）由主人指令触发；同批钉子无变动（vp-version 两仓同值未动）

# CHANGELOG 格式规范——Keep a Changelog 2.0.0 中文化改造版

> 基于规范原文：[Keep a Changelog 2.0.0](https://keepachangelog.com/en/2.0.0/)（官方简体中文译本尚无 2.0，[zh-CN/2.0.0](https://keepachangelog.com/zh-CN/2.0.0/) 为占位页）。本改造不逐句直译：取规范骨架为法条，按本项目「散文中文、标识符与既定格式英文」的语言传统（dev-standard §7、GLOSSARY「机器对等」）适配术语与工作流。**双仓同源拷贝，主作者位在 LDC**（统筹同 [dev-standard.md](dev-standard.md)）；WDC 侧拷贝由 dev-standard-guard 工作流同批守护。

## 1. 总则

- **Changelog 为人写，不为机器写**：只记显著变更（curate, don't accumulate），不逐条搬 git log；口吻面向使用者，不预设读过 commit。
- 文件恒名 `CHANGELOG.md`，位于仓库根，Markdown；**倒序排列**（新版本在上）——每个版本有节、旧条目不删；写错的条目可订正（改内容不是改历史），永不删除版本节。
- 前言四件套：一句话用途、合规徽章（`Keep a Changelog 2.0.0`）、遵循声明（钉本改造版）、版本方案声明（SemVer，v0.x 破坏性走 MINOR）+ Conventional Commits 映射（feat / fix 驱动版本号）。

## 2. 版本节

- 节标题：`## [X.Y.Z] - YYYY-MM-DD`——版本号方括号、**半角连字符**、ISO 8601 日期；不另立日期格式。
- 顶部常置 `## [Unreleased]` 收纳未发版变更；发版时摘录成新版本节，再立空的 Unreleased（Unreleased 有条目不算「未发版」欠账，是正典记录的一部分）。
- 版本可带**导语**（一段话概括本版主题）再进类型节——可选，有话则说，不硬凑。
- 撤回的已发布版本**照列不隐藏**：节标题尾加 `[YANKED]` 并写明原因。

## 3. 六类型（节名恒英文，节内正文中文）

| 节名 | 语义 | 判据 |
| --- | --- | --- |
| `Added` | 新功能 | 新增的能力面 |
| `Changed` | 既有功能的变化 | **有意为之**的行为改变 |
| `Deprecated` | 即将移除 | 留迁移窗口 |
| `Removed` | 已移除 | 通常先 Deprecated 后 Removed |
| `Fixed` | 缺陷修复 | 行为**原本是错的**、现已正确 |
| `Security` | 漏洞修复 | 有 CVE 号时 CVE 号先行 |

- 节内小节按上表 canonical 序排列。
- **节名保持英文**（对齐官方简体译本立场，2026-11-01 定夺）：条目由实施会话的 agent 起草（§6）——节名是 agent 每次收口都要稳定复现的格式 token，英文正典名是 agent 训练分布与跨仓惯例的最大公约数，中文节名反而引入「每仓一处本地约定」的漂移源；表内中文对照管人读，节下正文本就全中文。读者侧唯一代价是标题观感，写者侧收益是约定零负担——读写不对称，钉英文。
- Fixed 与 Changed 的分界：**错 vs 有意**——行为错了修好是 Fixed，有意改出新行为是 Changed。
- **不新增类型**（Improved / Internal / Dependencies 等一律不设）：依赖变更按对使用者的影响归入对应类型，无感则不记；已知问题不是类型——进正文、工单或 release notes 的「已知事项」。

## 4. 破坏性变更：`Breaking:` 标记

- 以 `**Breaking:**` 行首标记写在所属类型节内（通常 Changed / Removed），**不单列节**——2.0.0 正式化约定。
- 标记后直陈破的是什么面（CLI / 配置文件 / 清单格式 / 脚本接口）与升级提示；长迁移指引外链 ADR / 工单，不往条目里塞长文。
- 中文术语映射：破坏性变更 = `Breaking`；YANKED = 撤回；notable changes = 显著变更。

## 5. 链接与引用

- 文件尾以 reference 链接逐版本挂 compare：`[Unreleased]: …/compare/vX.Y.Z...HEAD` 恒指**最新 tag**，`[X.Y.Z]: …/compare/前版...本版`，最老版本指 tag/releases；发版时随新版本节同批续写（曾因忘续停在 v0.8.0 两个版本——续链是收口动作的一部分）。
- 引用提交用 7 位短 sha；引用工单写「工单NN」；跨仓锚写明仓别（如 `ldc 006c2e5`）。
- issue / PR 引用写标题散文，不裸挂 `#1234`（平台句柄不迁移）。

## 6. 双仓工作流（本项目特有）

- 条目由实施会话收口时写入 `[Unreleased]`——**agent 起草、人策展**（2.0.0 自动化指引）；发布（tag + release + Unreleased 摘录成版本节）由主人 explicit 指令触发。
- 双仓联动变更两仓 CHANGELOG 同批各记一条并互引锚点；**同号同日仅限联动变更**（dev-standard §5）。
- release notes 四段（本批内容 / 已知事项 / 验证锚点 / 升级方式）由 CHANGELOG 派生——**changelog 是正典记录**，平台生成的 release notes 不回填本文件。
- 本文件随 dev-standard 统筹：先改 LDC 侧提交，再同步 WDC 拷贝；漂移由每周 dev-standard-guard 拦截。

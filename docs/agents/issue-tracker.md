# Issue tracker：本地 Markdown 工单

本仓库的工单与规格以 markdown 文件形式存放在 `.scratch/` 下。

## 约定

- 一个特性一个目录：`.scratch/<feature-slug>/`
- 规格文件：`.scratch/<feature-slug>/spec.md`
- 实现工单一票一文件：`.scratch/<feature-slug>/issues/<NN>-<slug>.md`，从 `01` 起编号，永不合并为单个 tickets 文件
- 分诊状态记在工单文件顶部的 `Status:` 行（角色词表见 `triage-labels.md`）
- 评论与讨论历史追加在文件底部的 `## Comments` 标题下
- 完结归档：验收清单全部勾选（或结局已记录在 Comments）的工单，移入 `.scratch/<feature>/issues/done/` 保留原文件名；`done/` 不参与后续扫描，保持 frontier 干净

## 技能说「发布到 issue tracker」时

在 `.scratch/<feature-slug>/` 下新建文件（目录不存在则创建）。

## 技能说「取相关工单」时

读所指路径的文件。用户通常会直接给出路径或工单号。

## Wayfinding 操作（`/wayfinder` 用）

**map（地图）** 是一个文件，每张工单一个 **child** 文件。

- **Map**：`.scratch/<effort>/map.md`（Notes / Decisions-so-far / Fog 主体）。
- **Child ticket**：`.scratch/<effort>/issues/NN-<slug>.md`，从 `01` 起编号，正文写问题。`Type:` 行记录工单类型（`research`/`prototype`/`grilling`/`task`）；`Status:` 行记录 `claimed`/`resolved`。
- **Blocking**：工单顶部一行 `Blocked by: NN, NN`。所列工单全部 `resolved` 后解除阻塞。
- **Frontier**：扫描 `.scratch/<effort>/issues/` 中开放、未阻塞、未认领的工单，编号最小者优先。
- **Claim（认领）**：动手前先置 `Status: claimed` 并保存。
- **Resolve（解决）**：在 `## Answer` 标题下追加答案、置 `Status: resolved`，然后向 map 的 Decisions-so-far 追加上下文指针（gist + 链接）。

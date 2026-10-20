# Agent 技能

## 工单跟踪（issue tracker）

工单以本地 markdown 文件记录在本仓库 `.scratch/<feature>/` 下。见 `docs/agents/issue-tracker.md`。

## 分诊标签（triage labels）

默认五标签词表：`needs-triage`、`needs-info`、`ready-for-agent`、`ready-for-human`、`wontfix`。见 `docs/agents/triage-labels.md`。

## 领域文档（domain docs）

单一上下文：仓库根一个 `GLOSSARY.md` 与 `docs/adr/`。见 `docs/agents/domain.md`。

## 协作规矩与已知坑

协作规矩（一次一问、事实自查、决策归环境主人）与已知机器坑都在 `docs/agents/collaboration.md`——在任何机器上驱动 WDC 工作前先读它。机器对等（GLOSSARY「机器对等」词条）：规则属于仓库，绝不存单机 agent 记忆。

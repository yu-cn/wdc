# 领域文档（Domain Docs）

工程技能在探索代码库时应如何消费本仓库的领域文档。

## 探索前先读

- 仓库根的 **`GLOSSARY.md`**；或（若存在）仓库根的 **`GLOSSARY-MAP.md`**——它指向每个上下文一个 `GLOSSARY.md`，读与主题相关的那些。
- **`docs/adr/`**：读涉及你将工作区域的 ADR。多上下文仓库还应查 `src/<context>/docs/adr/` 的上下文级决策。

这些文件若不存在，**静默继续**。不要提示缺失，也不要建议先行创建——`/domain-modeling` 技能（经 `/grill-with-docs`、`/improve-codebase-architecture` 触达）会在术语或决策真正落定时惰性创建。

## 文件结构

单上下文仓库（多数仓库）：

```
/
├── GLOSSARY.md
├── docs/adr/
│   ├── 0001-event-sourced-orders.md
│   └── 0002-postgres-for-write-model.md
└── src/
```

多上下文仓库（根存在 `GLOSSARY-MAP.md`）：

```
/
├── GLOSSARY-MAP.md
├── docs/adr/                          ← 系统级决策
└── src/
    ├── ordering/
    │   ├── GLOSSARY.md
    │   └── docs/adr/                  ← 上下文专属决策
    └── billing/
        ├── GLOSSARY.md
        └── docs/adr/
```

## 使用词汇表的用语

产出物命名领域概念时（工单标题、重构提案、假设、测试名），使用 `GLOSSARY.md` 定义的术语，不漂移到词汇表明确 Avoid 的同义词。

若所需概念尚不在词汇表中，这是一个信号：要么你在发明项目不用的语言（重新考虑），要么存在真实缺口（记给 `/domain-modeling`）。

## 标记 ADR 冲突

产出与既有 ADR 矛盾时，显式指出而非静默覆盖：

> _与 ADR-0007（事件溯源订单）矛盾，但值得重启，因为……_

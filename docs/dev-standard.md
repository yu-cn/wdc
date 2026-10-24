# 开发规范（LDC / WDC 统一）

> **双仓同源拷贝**：本文在 yu-cn/ldc 与 yu-cn/wdc 各存一份，**主作者位在 LDC**（与 dotfiles/linux 主作者位同款统筹模式，ADR-0007）——改规范先改 LDC 侧提交，WDC 侧同步拷贝；不一致以 LDC 为准。
> **规范来源原则**：本文只把两仓已验证的实践显性化——每条规则都有 ADR、事故实录或既有惯例支撑；不为假想需求新增流程（新流程先过 ADR）。
> 分工：对外贡献者看 [CONTRIBUTING.md](../CONTRIBUTING.md)；agent 契约看 [AGENTS.md](../AGENTS.md)；本文是主人与 agent 共同遵守的内部开发规范。

## 1. 分支与提交

- **主干开发**：单人仓库，直接在 main 提交推送；不做分支/PR 仪式（拒绝的替代：feature 分支流——单人无第二双眼睛，仪式成本无收益；外部贡献走 CONTRIBUTING 的 PR 路径，不受本条约束）。
- **提交信息：Conventional Commits 1.0.0**（官方规范）：
  - 结构 `<type>(可选 scope): 中文描述` + 空行 + 可选正文 + 空行 + 可选脚注；
  - feat / fix 为规范保留 type，直接驱动版本号：feat→MINOR、fix→PATCH；v0.x 阶段破坏性变更按 semver 走 MINOR；
  - 扩展 type 用惯用集：build / chore / ci / docs / perf / refactor / revert / style / test；
  - scope 可选：单一主落点明显时取组件 / 域名，跨域大改省略；名词用英文；词表按仓登记——**LDC**：bootstrap · install-packages · user-tools · dotfiles · desktop · docker · cli · verify · plan · configs · pins · validate · ci · agents · standard · dev-env；**WDC**：bootstrap · validate · cli · configs · dotfiles · wsl · remove-leftovers · vp · triage · inventory · upstream · fonts · wt · base-windows · cli-tools · editors · adr · agents · docs · standard · dev-env · ci（新组件随 ADR/工单增补词表）；
  - 描述全中文、动词开头、句末不加句号（Angular 惯例；规范本身不限制语言）；
  - 破坏性变更：type 后加 `!` 或脚注 `BREAKING CHANGE: 说明`；
  - 锚点（工单 / ADR / CI run id）写正文或脚注，脚注用 git trailer 形态（如 `Refs: 工单07`）。
- **已推送历史不可回改**：修错用 revert；被 tag 锚定的提交永不改写（一次性例外已发生并收口：2026-10-25 全历史迁移至本规范，旧历史备份经主人确认后删除；此后本条无例外）。
- **钩子纪律**：pre-commit 是硬关（跑无副作用校验），禁止 `--no-verify` 绕过；钩子失败即修而不是绕过。跨环境提交（钩子未接线 / 依赖不在）走「CI 兜底」既定路径——push 后 validate 必绿，不绿即修，无需任何绕过动作。

## 2. 工单流（`.scratch/`）

- 布局：按特性域分目录（两仓主战场均为 `dev-env/`）；LDC 文件名 `NN-主题.md` 编号递增不复用，WDC 沿用其既有目录结构。
- 生命周期：**新开**（背景 / 内容 / 验收清单三段）→ **进行**（勾选 + 实录）→ **收口**（实录补验证锚点：CI run id、真机证据）。工单完成即归档保留——工单即档案，不删除。
- **实录纪律**：失败与事故必须入档（先例：validate 的 jq 硬依赖事故）；一句话可迁移的教训升级进 AGENTS 红线。
- 跨仓引用写明仓库名：「wdc 工单32 反哺 LDC 438f77c」形态。

## 3. ADR

- **新决策先写 ADR 再动代码**；编号单仓独立递增，文件名 `NNNN-英文-kebab-标题.md`、正文全中文。
- 格式：短、含取舍与「拒绝的替代」；背景段回答「谁在什么场景问的」。
- 双仓共用决策（统筹 / 委托 / 规范）落 LDC 编号，WDC 侧引用不复制。

## 4. 质量关卡

- **validate（无副作用校验）**：pre-commit 与 CI 双把关，每次提交本地必过；**不得引入解释器之外的运行时硬依赖**——缺失时降级放行 + CI 兜底（jq 事故教训）。
- **verify（机器断言）**：只读；exit 码语义全仓统一：0 就绪 / 1 失败 / 2 有待办手工步骤。
- **如实报告**：SKIP / PENDING 不得说成 OK；待手工步骤必须附交接命令。

## 5. 版本与发布

- semver；v0.x 破坏性变更走 MINOR（semver §4：主版本为零一切皆可变）。
- **tag 语义 = 发布时验证全绿**：push → CI 全绿（validate 必绿；冒烟面手动触发）→ annotated tag（信息含验证锚点）→ release。
- release notes 固定四段：**本批内容**（按特性分组、引 ADR）/ **已知事项** / **验证锚点**（本机形态 + CI run id + 跨仓锚点）/ **升级方式**。
- 发布由主人明确指令触发（「发布 vX.Y.Z」）——agent 不得自行 tag / release。

## 6. 双仓统筹（ADR-0007）

- **主作者位**：Linux 侧模板与清单在 LDC；WDC 侧冻结，需求回流 LDC。
- **钉子同值**：`configs/vp-version` 两仓同值，升级同日双改、各自记账。
- **委托契约**：WDC 的 WSL 阶段调用 LDC（clone/pull → root 委托 install-packages → user 委托 bootstrap → 验收委托 verify --quick）——改入口契约（参数 / 退出码 / 独立可跑性）前先想 WDC 调用方。
- **命名**：远端与仓内引用一律小写 `yu-cn/ldc`、`yu-cn/wdc`。
- **双仓改动自查**：这个改动另一仓有同源拷贝吗？有钉子要同值吗？动契约了吗？门面引用（README / 文档）要跟吗？

## 7. 文档与语言

- 散文全中文；标识符、命令、type 前缀、既定格式保持英文。
- 术语首现进 GLOSSARY；AGENTS.md 是 agent 契约——**红线新增须有事故或 ADR 支撑**，红线不是愿望清单。
- 机器私有内容永不入仓库（git 身份、自留地、本机清单）；agent 的单机记忆不替代仓库规则（WDC「机器对等」词条）。

## 8. 供应链与安全

- 直接下载的资产版本 + sha256 双钉，哈希自官方资产实算（ADR-0011 模式）；curl|sh 安装器的信任锚是官方域名本身，不在可钉范围。
- 提交内容自查：无凭据、无本机路径依赖、无临时文件。

# 自建配置树，不 fork 上游 WindowsDeveloperConfig

本仓库的目标是个人开发环境配置，与 microsoft/WindowsDeveloperConfig 的差异会持续扩大，长期同步上游是纯负担；因此决定不 fork，上游只作为官方写法的参考范例（其结构调研见 docs/research/），本仓库自建全部配置。代价是上游后续新增的配置需要手动搬运，对个人环境可接受。

**补充（访谈收官时确立）**：自建 ≠ 断联。上游是长期的「养料源」——持续关注其演进，有益的更新以**人工挑选移植（port）**的方式吸收，不做 git 级合并或自动同步。落地三件套：① docs/research/windowsdeveloperconfig.md 固化已核实的上游基线；② 吸收账本记录每次检查日期与已移植项（附上游链接）；③ 一个检查脚本对比上游新改动与我们的声明，输出「值得考虑」清单，是否移植由人决定。检查频率不自动化（GitHub watch 上游仓库 + 想起时跑），与不做可选层机制的 YAGNI 立场一致。

**修订标注（2026-11-07，主人定夺）**：上段「养料源」框架收回——wdc 无严格意义上的上游：WindowsDeveloperConfig 是初始构建时参考的资源之一（吸收账本 4 条中 3 条出自 2026-10-19 当日、此后零吸收；上游 HEAD 三周未动），不存在持续关注与移植的跟随义务。检查机制退役：check-upstream 移 `scripts/adhoc/` 留作历史工具、吸收账本封卷（`docs/upstream-ledger.md`，血统档案保留）、`wdc status` 的补课提醒撤除。本 ADR 本体立场（自建、不 fork、差异持续扩大、长期同步纯负担）不变；仓内「上游」一词此后仅指 fork 用户视角的 yu-cn/wdc 本仓（forking.md）。

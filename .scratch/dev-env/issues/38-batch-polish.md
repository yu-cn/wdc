# 38: 批量打磨——status 判定行 / get.ps1 钉版与 fork / 同源守护 / 冒烟幂等腿 / 剧本入库

**What to build:** 环境主人定夺（2026-10-26，批次评估「全都按你建议来」）六项落地：① `wdc status` 最近 bootstrap 判定行只搜主日志——提权委托流（工单19 起）七阶段在 elevated-*.log 收尾，判定行不在主日志，LETH 实测恒显示「（无判定行）」而真判定就在配对 elevated 日志尾；改取主/elevated 两日志较新者搜判定。② get.ps1 支持 `WDC_TAG` 钉版与 `WDC_REPO` 覆盖——irm|iex 传不了参数，env 形态最顺；tag 钉版对齐 LDC get.sh 既有能力，WDC_REPO 让 fork 用户一条命令引导自己的仓库（README 明说 fork 走手动三行是门面与体验不匹配）。③ dev-standard 双仓同源拷贝零守护，且跨仓 diff 全文假红（LETH 实测 67 行全红纯 CRLF/LF，内容一致）——两仓各加每周守护工作流（拉姊妹仓去 CR 归一比对，漂移即红；刻意不挂 push：双仓协同编辑必有先后，瞬时红污染 badge；漂移成因是忘同步非紧急事故，≤7 天窗口足够），WDC 侧 .gitattributes 补钉该文件 LF 消假差异。④ fresh-machine 冒烟补幂等重跑腿（对齐 LDC 32453e7：第二遍除「身份文件」占位提醒外零 `[CHANGED]` 才放行——占位未填每轮必报，是手工待办提醒不是机器变更）+ 月度定时常态化（公开仓库 runner 免费；此前仅手动）。⑤ 坑14 Git 升级计划任务剧本自 logs/（gitignore 盲区、机器间不可见）沉淀 scripts/adhoc/ 入库——创建器参数化去 LETH 硬编码路径，剧本本体逻辑不变。⑥ 工单收尾三连：35 研究载体随 ADR-0015 退役归档、24 LETH 受控漂移正面观感实测归档、33 Chrome useLatest 复测实录。

**Blocked by:** None

**Status:** ready-for-agent

- [x] wdc.ps1：判定行取主/elevated 两日志较新者（先搜 bootstrap 汇总行、兜底任意判定行），来源文件名如实展示
- [x] get.ps1：WDC_REPO / WDC_TAG env 支持（保持纯 ASCII 无 BOM——字节级复验），README 快速开始与 fork 段同步
- [x] .gitattributes：`docs/dev-standard.md` 钉 LF（消跨仓行尾假红）
- [x] CI：dev-standard-guard 工作流（每周 + 手动 dispatch，去 CR 归一比对姊妹仓 LDC）
- [x] CI：fresh-machine 幂等重跑腿 + 月度 cron + 重跑日志工件
- [x] scripts/adhoc/：git-upgrade-task.ps1 入库（头注释改 `*.log` 全局忽略口径）、创建器参数化；logs/ 原件清除
- [x] 工单 35/24 归档移位、33 复测实录（24 含 LETH 受控漂移实测：黄字命中/还原静默/延迟 ~0.9s）
- [x] CHANGELOG Unreleased 记账
- [ ] CI 绿锚点回填（validate / dev-standard-guard / fresh-machine）

## Comments

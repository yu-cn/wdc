# 25: fork 跟随指南 + 版本锚点（v0.1.0）

**What to build:** 优化方向研究 P1-③。开源后新角色（fork 用户）缺两样：①跟随上游演进的 recipe（README 只讲了初改，没讲日后怎么 merge 上游）；②版本锚点（上游不打 tag，fork 想稳没得跟）。交付：docs/forking.md（merge 策略按 ADR-0002 分层：scripts 收上游、configs/dotfiles 保留自己、.scratch 删）；README 链接之；打 v0.1.0 tag + GitHub Release 标记「开源基线（验证全绿）」。

**Blocked by:** None

**Status:** ready-for-agent

- [x] docs/forking.md：一次性设置 / 日常跟随 / 分层冲突预期 / 版本锚点说明
- [x] README「使用与改造」链接 forking.md
- [x] 文档节收录 forking.md
- [x] v0.1.0 tag + Release（锚定本批收口提交，validate CI 绿）

## Comments

- 2026-10-21（主机会话）：tag 语义定为「验证全绿的公开锚点」，不承诺兼容性——与上游调研里「官方也不打 tag 但示例用 -Ref」的观察呼应。
- 2026-10-21（主机会话）补：Release 备注同时声明 fresh-machine 的 runner 已知限制（工单26）与工单27 待决项，锚点如实。

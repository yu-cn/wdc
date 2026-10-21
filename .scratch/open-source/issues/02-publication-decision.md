# 02: 公开动作与许可证定夺（环境主人）

**What to decide:** 仓库侧准备已完成（工单 01）。转为公开剩三件事，归环境主人定夺：

1. **许可证确认**：已默认放 MIT（版权人 yu-cn）。如想换（如 Apache-2.0 / Unlicense），替换 LICENSE 文件即可，无其他联动。
2. **公开方式**：
   - a) **直接翻可见性**（默认建议）——全历史公开，含 `.scratch/` 工单实录（机器名、本机路径、工作日志；审计无凭据，轻度个人化）。历史即价值：20 张工单的决策链全在。
   - b) **全新公开仓库单提交起步**——历史干净，但丢掉全部工单历史与决策链。
3. **翻公开后收尾**：`gh repo edit yu-cn/WDC` 补 description / topics；抽查 README 链接（clone 命令、ADR/文档相对链接在公开页正常渲染）。

**Blocked by:** 01

**Status:** ready-for-human

## Comments

- 2026-10-21（主机会话）：翻可见性的操作入口：网页 Settings → Danger Zone → Change visibility，或 `gh repo edit yu-cn/WDC --visibility public --accept-visibility-change-consequences`。GitHub 会要求确认；翻公开后历史 fork/缓存不可撤回，故此动作留给主人亲手执行。

- 2026-10-21（主机会话）补记：环境主人定夺「按建议执行」（MIT 维持 + 直接翻可见性）后代跑三次均网络层失败（unexpected EOF / TLS handshake timeout / 一次 PATCH 返回 404 而 view 正常，疑似本机代理对 PATCH 不稳），仓库仍 PRIVATE。主人改为晚些自己执行；description/topics 未设置，翻公开后可一并补。

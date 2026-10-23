# 20: wdc CLI 使用体验优化——子命令化 + 单一实现

**What to build:** 现状：`wdc` 是 pwsh profile 与 Git Bash bashrc 里各一份的内联函数（约 13 行同构 bash/pwsh，已现漂移风险），只有一个固定动作 pull→bootstrap→verify：没有帮助可发现、不能只跑局部（verify/triage/看日志都要手敲长命令）、bootstrap 失败只说「日志在 logs/」不给出内容、无耗时汇总。环境主人指示（2026-10-20）：优化使用体验。方案：逻辑收敛为仓库内单一 `scripts/wdc.ps1`，两侧 shell 只留薄包装转发；子命令化——`sync`（默认，原全量动作）/ `status`（只读快照：远端差距、dotfiles 漂移、最近 bootstrap 结果）/ `verify [-Full]`（默认 -Quick）/ `triage`（工单 17 工具入口）/ `log [-Lines N]`（失败排查）/ `help`。sync 增强：fetch 后领先/落后报告、本地领先即中止（防意外 pull 合并）、UAC 预告、bootstrap 失败自动 tail 最近日志 30 行、总耗时。WSL 侧维持无 wdc（bootstrap+UAC 属 Windows 会话，跨 interop 徒增失败面）。

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [x] `scripts/wdc.ps1` 单一实现（六子命令，复用 lib/common.ps1 的报告风格）
- [x] pwsh profile 与 Git Bash bashrc 改薄包装（~/.wdc 解析 + 转发，错误提示保留）
- [x] 主机实测：help / status / verify / log / triage 入口，sync 全链路端到端（含 UAC）
- [x] README「常用命令」表补 wdc 子命令
- [x] status 增「距上次上游检查 N 天」提醒（读 upstream-ledger.md，>30 天提示跑 check-upstream；工单18 定的只提醒不巡检）
- [x] ASUS 复验：拉取后新 shell 直接用新 wdc

## Comments

- 2026-10-20（主机会话）：开工即实现。设计取舍：不做 `update`/`doctor` 等花哨命名（sync/status/verify/triage/log 与仓库现有动词一一对应）；verify 独立子命令默认 -Quick（秒级日常），sync 尾部的 verify 维持全量（同步即验收）。

- 2026-10-20（主机会话）：主机实测全过——help/status/verify(-Quick)/log 直跑与 Git Bash 薄包装路径（`bash -ic 'wdc status'`）均正常；`wdc sync` 端到端 1137s 全绿（fetch→一致跳过 pull→bootstrap 全阶段 OK→verify 三域漂移=0→带耗时汇总）。上线当天即立功：`wdc status` 一眼暴露 21:35 那次 UAC 被取消的早退 bootstrap（正常收尾日志显示汇总行、早退日志兜底显示最后一条判定行）。dotfiles 漂移检测对「未提交的模板编辑」与「写穿」同判（verify 断言同义），属预期——先 commit 再 verify。

- 2026-10-20（主机会话）增补：`wdc log` 与 sync 失败尾部接入 elevated-*.log（工单19 落盘机制的消费端）；status 增上游检查提醒（当前显示「距上次 2 天」）。顺带发现用户已在 23:25 实跑新 wdc——真实使用即复验。

- 2026-10-21（ASUS 会话）：本机复验全过。旧版 wdc 全量收敛：258ae2f→84ef9ad，bootstrap 全阶段 OK（提权子回合 409s / 父回合 422s），lazygit 0.66.1 实装；扩展 32 项全部在位、新装 0——9 个新扩展本机早已自装（自留地幂等）；三域漂移=0。工单19 落盘机制本机首证：elevated-20261021-000646.log 自 Preflight/Validate 至「[OK] bootstrap - 收敛完成」完整无断，且当日仅一份 bootstrap-*.log（无子回合第二 transcript）。新 shell 薄包装：wdc status 四行快照（仓库与 origin/main 一致 / dotfiles 漂移 / 上游检查距上次 2 天 / 最近 bootstrap → [OK] 收敛完成），并当场如实检出台面上一处 editorAssociations vscode-remote 写穿、给出 triage 入口——行为与主机一致；该写穿经环境主人定夺吸收（378cb68），吸收后 wdc verify -Quick 全绿（exit 0）。
- 2026-10-23（LETH会话）：体验修订（主人反馈「裸命令直接同步有些突兀」，参照业界：git/gh/kubectl 裸命令不跑长操作、jj 裸命令给只读状态）——**裸 `wdc` 从默认 sync 改为默认 status（只读快照）**，长/改状态操作一律显式子命令；新增 `wdc help [命令]`（-h/--help 同义，含单命令详解）、`wdc version`（-v/--version，git describe 取，v0.2.0-18-g…）、打错子命令给「你是不是想输…」建议（唯一前缀命中 → 全表最小编辑距离）；裸命令跑完快照附一行提示（`wdc sync` 同步 / `wdc help` 全命令）。sync/status/verify/trage/log 行为与守卫全部不变，包装层（bashrc/pwsh profile）透传参数无需改动。LETH 实测：help/-h/单命令详解/version/typo 建议（verion→version、syncx→sync、stat→status）/log -Lines/裸 status 全过。踩坑一枚：PowerShell 索引括号内 `$d[$i - 1, $j]` 会解析为 `$i - (1,$j)`（逗号优先级）——二维数组下标必须预计算或加括号。

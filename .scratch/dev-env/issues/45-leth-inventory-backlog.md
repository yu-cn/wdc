# 45: LETH inventory 反向吸收欠账（须在 LETH 机器会话执行）

**What to build:** README「新开发机接入」第 3 步（反向吸收：inventory 存档 + 主人按 ADR-0003 判据定夺）在 **LETH 从未执行**——`.scratch/` 仅 ASUS 存档两份（20261019、20261107 刷新）。**执行环境：LETH 机器会话**（inventory 只能清点本机；ASUS/其它机器会话扫到本票请跳过，勿在非 LETH 机器执行）。步骤：① LETH 上跑 `pwsh scripts/inventory-machine.ps1 > .scratch/inventory-LETH-<日期>.md` → commit + push；② 主人对账定夺——`wdc audit` 自装未声明面为候选清单，LETH/ASUS 双机自装交集是通用核心候选的天然试验场（ADR-0003 判据：某项只要存在「某台机器不需要」的情形即出局，归机器自留地）。

**Blocked by:** None

**Status:** ready-for-agent

- [ ] ① LETH 会话跑 inventory 存档 + commit + push
- [ ] ② 主人对账定夺（audit 自装面 vs ADR-0003 判据）；吸收项进 configs/dotfiles 并 CHANGELOG 记账

## Comments

- 2026-11-07（ASUS 会话，开单）：同批刷新了 ASUS 存档（inventory-ASUS-20261107.md，149 行，Git 2.56.0.4 后状态）+ audit 对账：已声明未装零项（声明面全核销）、自装未声明 53 项候选已报主人（倾向全部维持机器自留地：Typora 系红线自留、Lark/PotPlayer/ExpressVPN 属个人软件、7zip/eza/FFmpeg 等非「新机 bootstrap 即必备」）。

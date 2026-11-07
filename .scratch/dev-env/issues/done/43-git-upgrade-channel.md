# 43: Git 升级通道化——`wdc upgrade-git` 子命令（坑14 剧本常态化）

**What to build:** Git.Git `useLatest: true`（cli-tools.winget）——Git 出新版后每次全量收敛都试图升级，而 agent 会话宿主即 Git Bash，安装器自研 in-use 检查发现 bash 即中止（坑14①，`/FORCECLOSEAPPLICATIONS` 对其无效）→ Stage 3 cli-tools 域 FAIL。四起实录：ASUS 2026-10-24（三道坎连环）、ASUS 2026-10-30（坑17 迁名连坐）、LETH 2026-11-01（0x8A150006 ShellExecute failed，真机 Git 补装即按剧本配方执行）、**ASUS 2026-11-02（cli-tools 域 -1978286075，失败单元 Microsoft.WinGet/Package [Git]，本机自该日起收敛滞留 5 天——wdc status 判定行持续 FAIL，2026-11-07 会话日志实证）**。剧本已入库（`scripts/adhoc/git-upgrade-task-creator.ps1` + `git-upgrade-task.ps1`，工单38 ⑤）但零集成——只有背过坑14 的会话才会用。本单通道化：① 创建器加 `-ViaSudo`（非提权 shell 建 /RL HIGHEST 任务报「拒绝访问」，LETH 实证 `sudo schtasks` 内联通过；sudo 不在时如实报错并给管理员终端指引）；② `wdc upgrade-git` 子命令：按提权态选调用形态，登记后输出坑14 纪律提示（发起后本会话停手让 bash/sh 静默达成 / UAC 交主人放行 / 完成后验证 `git --version` + `wdc sync` 恢复收敛 / 日志 `scripts/adhoc/git-upgrade-schtasks.log`）；③ bootstrap Stage 3 域 FAIL 且输出含 `[Git]` 单元时定向提示该通道（提示为 INFO 性质，不改变退出码语义）；④ help 三面（$wdcCommands / helpOverview / helpDetail）同步；⑤ 坑14 附注「--silent 仍弹交互向导成因未查」维持不深究（低价值——剧本已附「用户点 OK 放行」注记，坑16 同族编码问题概率高）。

**Blocked by:** None

**Status:** done

- [x] ① git-upgrade-task-creator.ps1 加 -ViaSudo（sudo 缺席时如实报错 + 管理员终端指引）
- [x] ② wdc.ps1 加 upgrade-git 子命令（提权态自选形态 + 坑14 纪律提示输出）+ help 三面同步
- [x] ③ bootstrap-main.ps1 Stage 3：域 FAIL 且输出含 [Git] → 定向提示 wdc upgrade-git（FAIL 分支未真机触发——Git 已最新，仅 OK 路径过真机；逻辑为单行 grep，静态检查覆盖）
- [x] ④ 真机验证（ASUS 活案例：11-02 起收敛滞留）——upgrade-git 全链成功（详见 Comments）；七阶段分两次全绿，verify -Quick 全绿；收敛账本因 bootstrap 中途 FAIL 按设计未写，下次日常 sync 全量成功即恢复（快速路径回退机制不受影响，宁可慢不可假绿）
- [x] ⑤ CHANGELOG [Unreleased] 记账 + push 后 CI validate 绿

## Comments

- 2026-11-07（ASUS 会话，开单）：治理收口批巡检发现的第四起实证立项——wdc status 冒烟暴露 11-02 bootstrap 判定 FAIL，追 elevated 日志定位为 Git 单元（此前三起见坑14/工单39/40 实录）。同会话实施。
- 2026-11-07（ASUS 会话，①②③ 落地）：creator 加 -ViaSudo（含 sudo 缺席指引；退出码语义补齐——失败 exit 1 供调用方透传）；wdc.ps1 加 upgrade-git 分支（Test-IsElevated 自选形态、登记成功输出坑14 三件事纪律、日志路径指路）+ $wdcCommands/helpOverview/helpDetail/两处可用列表五面同步；bootstrap-main.ps1 Stage 3 流式输出加 List 收集，域 FAIL 且输出含 `[Git]` 时 INFO 指路（不改变退出码）。轻量验证过：`wdc help upgrade-git` 详解正确、`upgrade-gi` 错拼建议命中、命令枚举含新命令。
- 2026-11-07（ASUS 会话，④ 进行中——真机首跑即活案例）：本机 git 2.56.0.windows.3 差档（11-02 失败即此升级）。`wdc upgrade-git` 实跑：未提权会话自动走 ViaSudo，sudo schtasks 登记 SUCCESS（UAC 主人放行），任务 WDC-GitUpgrade-20261107-1853 定 18:55 起跑。按纪律本会话停手让 bash/sh 静默达成，等待任务完成后验证。
- 2026-11-07（ASUS 会话，④ 升级腿实证）：任务日志全程干净——18:54:55 起跑、18:55:05 静默达成（会话停手后 10 秒）、winget exit 0、**2.56.0.windows.3 → 2.56.0.windows.4**、gitconfig intact（坑14③ 未触发）。本次 `--silent --disable-interactivity` 全程无弹窗（坑14 附注「仍弹向导」为 10-24 旧安装器行为，现版本已不弹——注记留档不删）。
- 2026-11-07（ASUS 会话，④ 收敛腿实录）：`wdc sync` 全量（872s，chrome 域下载大头 + node@lts 24→26 更新）——**Stage 3 含 Git 的 cli-tools 域回绿**（799.8s OK），Stage 6 WSL 侧 FAIL：WSL 内 `~/dev/ldc` 本地领先 8 提交未推送，ensure_ldc 防丢护栏正确拦截（此前 LDC 会话成品批：ADR-0019/0020 等，工作树干净）——WSL 内 push（48d5919..8d60b34）后补跑 install-wsl-env.ps1 全绿（`[LDC_TODO=desktop]` 严格容忍正确消化，工单37 机制真实路径复验）。终态 `wdc verify -Quick` 全绿 exit 0。**5 天收敛滞留（11-02 起）收口**。账本未写属设计内（bootstrap 中途 FAIL 不记账），快速路径回退安全不受影响。
- 2026-11-07（ASUS 会话，⑤ 收口）：CHANGELOG [Unreleased] 记 Added 一条；push 后 CI validate 锚点见工单行。本单四起实录的重复人工处置至此通道化：下次任何会话撞 Git 升级，`wdc upgrade-git` 一条命令。

## Comments

- 2026-11-07（ASUS 会话，开单）：治理收口批巡检发现的第四起实证立项——wdc status 冒烟暴露 11-02 bootstrap 判定 FAIL，追 elevated 日志定位为 Git 单元（此前三起见坑14/工单39/40 实录）。同会话实施。

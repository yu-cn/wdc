# 19: bootstrap 提权子回合失败但原因未落盘——transcript 中断且 FAIL 详情丢失

**What to build:** 2026-10-20 主机重跑 bootstrap（拉取 258ae2f 后的工单 15 复验），汇总报「提权子回合 FAIL（469.2s）」，但子回合 transcript（logs/bootstrap-20261020-202233.log）停在 `[OK] base-windows` 之后、无 Stop-Transcript 尾注——cli-tools 之后的全部输出与失败原因没有落盘，排障只能靠事后机器状态反推。需查明：① 子回合中断点与退出码（是 winget 挂死、进程被杀、还是错误路径未落盘）；② 修复方向二选一：让失败详情可靠落盘（子回合输出重定向到文件而非仅靠 transcript），或先复现定位根因。

**Blocked by:** None (can start immediately)

**Status:** ready-for-human

- [x] 复现或推断子回合中断原因（不强行复现：实录已记——transcript 断于原生日令段而进程续活约 4.7 分钟后非零退出；落盘后再遇同类中断即自证）
- [x] 定夺修复方向并实施：子回合输出可靠落盘（2026-10-20 主人批准；当日实测全链路）

## Comments

- 2026-10-20（主机会话）实录：bootstrap 单命令收敛，UAC 放行后子回合正常起跑（transcript 头部完整，validate 全过，base-windows 域应用成功）；20:25:41 后 transcript 再无写入，父进程 -Wait 至 469.2s 收到非零退出，汇总 FAIL。事后 `winget configure test`：editors 漂移=0（已应用），cli-tools 剩 4–6 项漂移（gh/starship/fzf/make/uv/chrome 升级未完成，Chrome/WT 均未在运行，排除应用占用挡升级）。同参数单独提权重跑 `winget configure --file cli-tools.winget` 一次全绿（logs/clitools-reapply.log，输出另走重定向、完整落盘），漂移归零——同一操作隔数分钟一败一成，首败疑似 winget 升级单元偶发（源更新竞态/网络），无日志佐证，故先记事实。verify-machine 全量断言见当次会话记录。

- 2026-10-20（主机会话）实施：方向=Tee 落盘。子回合不再自建 transcript，改由父进程以 `-Command "& bootstrap.ps1 -ElevatedPass *>&1 | Tee-Object elevated-<ts>.log"` 包装启动——管道由独立包装进程持有，transcript 会断它不会断，子窗口照常实时可见。wdc 集成：sync 失败尾部与 `wdc log` 均纳入 elevated 日志。当日实测：子回合 437s 从 validate 到汇总行全程落盘，父进程汇总 [OK]，退出码 0。附注：21:35 另有一次 UAC 被取消的早退（用户实跑），走的是 transcript 路径且有尾注——两类日志互补，此后任何失败形态都有据可查。

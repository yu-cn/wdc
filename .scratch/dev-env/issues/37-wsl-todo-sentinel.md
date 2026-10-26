# 37: WSL 委托 exit-2 判定改按 LDC_TODO 机器标记（散文 grep 退役）

**What to build:** `setup-ubuntu.sh` 对 LDC bootstrap 退出码 2 的分类靠 grep 散文文案（「桌面域：登录」「root 阶段：cd」「git 身份：编辑」，工单32 遗留）——两仓间无守护的字符串契约：LDC 侧任何文案微调即静默失效，且两个失效方向都有害（root/身份真待办被吞成 rc=0 掩盖问题；桌面域待办误判真问题 Stage 6 红）。LDC 侧已完成契约机器化（LDC 工单08 / [ADR-0007 补记](https://github.com/yu-cn/ldc/blob/main/docs/adr/0007-wdc-ldc-coordination.md)，commit 00a0ea5）：exit 2 待办行尾带 `[LDC_TODO=tag]`，fresh-container handoff job 生产侧断言标记在位。本单把消费方切到标记，取**严格容忍形态**：待办集合恰为 `{desktop}`（WSL 无 GNOME 会话、登录桌面重跑永不适用）才按形态预期消化为完成；root 交接 / git 身份 / 未知新标记一律如实透传非零——宁可误红不可静默吞待办。

**Blocked by:** None（LDC 00a0ea5 已推送，契约标记已上线并 CI 实证）

**Status:** done

- [x] `scripts/wsl/setup-ubuntu.sh`：exit-2 判定改按 `LDC_TODO=` 计数恰为 1 且为 desktop；注释更新为契约口径（字面量属契约、变更与 LDC bootstrap.sh 同日双改）
- [x] CHANGELOG `[Unreleased]` 记 Changed 一条
- [x] 真机验证（WSL Ubuntu）：LDC bootstrap 实跑 exit 2、待办恰一条 `[LDC_TODO=desktop]`（root 已核销、git 身份已生效）；新判定逻辑对真实输出判容忍；root-handoff、git-identity、未知新标记三类合成负例均判不容忍（fail-safe 方向闭环）
- [x] WSL 内 `ldc validate.sh` 全绿（Windows Git Bash 下的 `ln` 符号链接 FAIL 属 MSYS 环境限制，真 Linux 全绿——本地 validate 以 WSL 为准）
- [ ] push 后 CI validate 全绿（锚点回填 Comments）

## Comments

- 2026-10-26（ASUS 会话）：识别于主人评估「WDC↔LDC 协作（尤其 WSL 部分）是否合适」→ LDC 侧先行落地（LDC 工单08）→ 本单消费方切换。真机验证实录：机器 `~/dev/ldc` 经 /mnt/d 本地镜像 ff-only 推进至 00a0ea5（github.com:443 自 WSL 直连被 TLS 拦截 `certificate signer not trusted`，代理仅绑 Windows 环回、WSL 不可达——LETH 宿主网络坑同族形态）；bootstrap 实跑输出形态与线上期望一致。完整委托编排（`install-wsl-env.ps1`）重跑两次均 abort 于 ensure_ldc fetch 的同款 TLS 拦截（幂等、机器状态零变化）——完整链路留待网络翻面后随任意一次 bootstrap 自然覆盖；判定逻辑已对真实输出单测闭环。

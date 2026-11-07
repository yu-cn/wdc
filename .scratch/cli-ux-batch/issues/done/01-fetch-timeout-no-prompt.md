# 工单01：wdc fetch 超时 + 禁交互防护（status/sync）

Status: done

## 背景

wdc.ps1 的 `git fetch`（status wdc.ps1:193、sync :276）无超时、无禁交互：坏网络挂起违背
「秒级快照」承诺；更险的是凭据过期时 GCM 弹 GUI 等待——agent 会话里即无提示挂死。
ldc 已有同款防护（5s/10s timeout + `GIT_TERMINAL_PROMPT=0` + 未达降级按缓存判读，
ldc:151、:216-217）——wdc 补齐对齐。

## 内容

- wdc.ps1 内加有界 fetch 助手：System.Diagnostics.Process + WaitForExit(ms) 硬超时（common.ps1
  的 Wait-WdcProcess 是轮询壳，此处直接进程级实现更简）；子进程环境注入
  `GIT_TERMINAL_PROMPT=0` + `GCM_INTERACTIVE=never`（GCM 弹 GUI 是 Windows 特有面）
- status：5s 预算；超时/失败 → INFO「fetch 未达（超时/断网）——按上次 fetch 缓存判读」
  （对齐 ldc 口径），ahead/behind 照算（origin/main 引用本地既有）
- sync：10s 预算；fetch 失败即中止（对齐 ldc sync「不盲按陈旧 origin/main 判一致」）
- fetch 只读可安全 kill（无锁残留风险），Kill(true) 杀进程树（git 可能带 gcm 子进程）

## 验收清单

- [ ] status 断网/超时路径：5s 内降级 INFO，快照其余项照常
- [ ] sync fetch 失败：FAIL 中止，不盲同步
- [ ] 正常网络路径行为不变（多 5s 上界、零可见差异）
- [ ] validate 全绿

## 实录

- 实现：Invoke-WdcFetchBounded（Process+WaitForExit(ms) 硬超时 + GIT_TERMINAL_PROMPT=0 + GCM_INTERACTIVE=never，Kill(true) 收进程树）；status 5s 未达降级按缓存判读、sync 10s 失败即中止
- 真机：正常路径零可见差异；fetch 未达路径经 status -Json state=fetch-unreachable 实证（LDC 侧同口径对照）；validate 全绿（cceb6b0）

# 01: 收敛入口全局互斥体

**What to build:** `bootstrap.ps1` 与 `wdc sync` 收敛路径入口取全局命名互斥体；
已被占用则友好报错退出（退出码非零），只读入口不受影响。

**Blocked by:** None (can start immediately)

**Status:** done

- [x] 互斥体取锁封装进 scripts/lib（`Enter-WdcRunLock`/`Exit-WdcRunLock`；取锁点在 bootstrap-main
      提权重发分支之后——只有真正跑阶段的进程持锁，`wdc sync` 经 bootstrap 子进程间接受保护）
- [x] 占用时输出「已有一次收敛在跑」并 exit 3；wdc sync 对退出码 3 特判给出专属提示
- [x] verify / triage / validate 等只读入口不取锁（`-ValidateOnly` 同样不取）
- [x] GLOSSARY.md 补「运行锁」词条
- [x] validate.ps1 全绿（PSScriptAnalyzer Error 级通过）

## Comments

- 2026-10-25（自主执行会话）：完成。锁名 `Global\WdcBootstrap`（上游 `Global\WindowsDevConfigSetup`
  同思想）。前持锁进程崩溃由内核废弃转交所有权（AbandonedMutexException 即到手），无陈旧锁清理问题。
  实测两路径：持锁中获取 → HELD、释放后获取 → ACQUIRED（正常释放）；强杀持锁进程后获取 →
  RECOVERED（废弃转交）。未做真实双 bootstrap 并发冒烟（避免本机真触发收敛），竞争语义由互斥体直测覆盖。
  verify-machine 新增的「续跑任务已清」断言属姊妹工单（bootstrap-resume）内容，同批落地。

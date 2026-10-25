# 01: 收敛入口全局互斥体

**What to build:** `bootstrap.ps1` 与 `wdc sync` 收敛路径入口取全局命名互斥体；
已被占用则友好报错退出（退出码非零），只读入口不受影响。

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] 互斥体取锁封装进 scripts/lib（复用点：bootstrap.ps1、wdc.ps1 的 sync 路径），
      `Global\` 前缀 + finally 释放
- [ ] 占用时输出「已有一次收敛在跑」并 exit 非零；wdc sync 转发退出码
- [ ] verify / triage / validate 等只读入口不取锁（现有行为不变）
- [ ] GLOSSARY.md 补「运行锁」词条
- [ ] validate.ps1 全绿（PSScriptAnalyzer Error 级通过）

## Comments

- 2026-10-25（对标评估会话）：立单。设计约束与否决项见同目录 [spec.md](../spec.md)。

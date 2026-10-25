# Spec：bootstrap 运行锁（对标上游可借鉴项）

## 背景

bootstrap 与 `wdc sync` 都会发起 winget 安装收敛，当前无并发防护
（grep bootstrap.ps1 / bootstrap-main.ps1 / scripts/lib 无 mutex、锁文件实现，2026-10-25 核实）：
`wdc sync` 与手工重跑 `bootstrap.ps1` 并发时，两个 winget 会话可能互相踩安装/卸载。
上游引擎有全局命名互斥体 `Global\WindowsDevConfigSetup` 防并发（docs/research/
windowsdeveloperconfig.md「权限要求」节），对标结论为值得吸收
（环境主人 2026-10-25 对标评估定夺：立工单待实现）。

## 设计约束

- 全局命名互斥体（`Global\` 前缀）：跨会话、跨提权/非提权边界互斥；内核语义保证
  持锁进程崩溃后自动释放，无需陈旧锁清理
- 取锁点 = 收敛入口（`bootstrap.ps1` 与 `wdc sync` 路径）；`verify` / `triage` /
  `-ValidateOnly` 等只读入口不取锁
- 已被占用时友好退出：输出「已有一次收敛在跑」，退出码非零（供 wdc sync 转发）
- 命名进 GLOSSARY（如「运行锁」词条），防后续实现者另起炉灶

## 已评估并否决的替代

- **锁文件**：进程被杀后留下陈旧锁文件，需要另写陈旧检测/清理逻辑；互斥体的内核
  生命周期语义天然免维护，零额外代码。

# Spec：bootstrap 重启自动续跑（对标上游可借鉴项）

## 背景

新机器 bootstrap 在提权回合内启用 WSL 功能后必须重启一次才能装 Ubuntu；现流程要求用户
重启后**人工重跑** `bootstrap.ps1` 收尾（README「首次运行你需要配合的五件事」第 3 条）。
上游 microsoft/WindowsDeveloperConfig 对同一场景用计划任务（WindowsDevConfigResume）在
下次登录自动续跑，且「只重启一次，绝不循环」（docs/research/windowsdeveloperconfig.md
「应用与验证」节）。这是新机接入体验的真实缺口，对标结论为值得吸收
（环境主人 2026-10-25 对标评估定夺：立工单待实现）。

## 设计约束

- 续跑任务一次性：只在 bootstrap 确实请求过重启时登记；成功或失败后自清，绝不形成重启循环
- 续跑动作 = 重跑 `bootstrap.ps1`（其幂等性保证已完成阶段全部跳过、只收敛剩余漂移）
- 提权运行（`schtasks /RL HIGHEST`，续跑要过 UAC 的阶段不少）；脱离 agent 会话进程树的
  计划任务路径已由坑14 实证可靠（会话内 Start-Process 分离进程活不过工具调用回收）
- 续跑日志落 `logs/`，与既有分阶段报告同格式，`verify-machine.ps1` 全绿即可验收
- README「五件事」第 3 条同步改写（人工重跑步骤消失，改为「重启后自动续跑，无需操作」）

## 已评估并否决的替代

- **RunOnce 注册表键**：更轻，但 RunOnce 在 UAC 分离进程与日志留存上不如计划任务可控，
  且上游 wsl-comfort 的 RunOnce 经验（账本 10-22 行）是「注释明写 elevated」的提权上下文，
  与我们 bootstrap-main 的单提权回合结构错位；计划任务一行 `schtasks` 即登记、自清即删，
  语义更显式。若实现时发现 ONCE+logon 触发不可靠，可回退评估 RunOnce。

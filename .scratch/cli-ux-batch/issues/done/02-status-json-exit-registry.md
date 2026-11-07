# 工单02：wdc status -Json 机器可读出口 + 退出码注册表进 help

Status: done

## 背景

两仓哲学是 agent 驱动 + 机器对等（GLOSSARY），但 agent 判定 state 只能 scrape 带颜色的
`[OK]/[FAIL]` 行。退出码（0 成功 / 1 失败 / 3 收敛锁占用）散在代码里没进 help。

## 内容

- wdc.ps1 加 `[switch]$Json`；status 分支先算后印：`-Json` 输出单行紧凑 JSON
  （ConvertTo-Json -Compress），键：`tool/version/command`、`repo{state,ahead,behind}`、
  `dotfiles{drift_count,drift_items[]}`、`identity{ok}`、`wsl{state}`、
  `last_bootstrap{log,verdict}|null`、`hints[]`；人读输出零变化
- pwsh 绑定器把 `--json` 当未知参数（实测：A parameter cannot be found that matches
  parameter name '-json'）——正典旗标 `-Json`（与 `-Full` 同族）；包装层
  （pwsh profile 函数 / bashrc 函数）把 `--json` 归一为 `-Json` 再转发，UX 与 ldc 对齐
- help 总览补退出码行：`退出码：0 成功 · 1 失败 · 3 收敛锁占用（sync）`

## 验收清单

- [ ] `wdc status -Json` 输出合法 JSON（ConvertFrom-Json 回解验证）
- [ ] 人读输出逐字节不变（无 -Json 时）
- [ ] 包装层 `wdc status --json` 两壳（pwsh/Git Bash）都归一成功
- [ ] help 总览含退出码行
- [ ] validate 全绿

## 实录

- 真机：`wdc status -Json` 合法 JSON（含 ahead:2 正确反映未推送提交）；pwsh 绑定器拒 --json 实录进票；包装层归一后 Git Bash `wdc status --json` 实证可用；help 总览含退出码行；validate 全绿（cceb6b0）

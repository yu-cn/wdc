# 工单04：子命令表单一来源 + 子命令 -h 落单命令详解

Status: done

## 背景

wdc 子命令表手抄 4 处：`$wdcCommands`（wdc.ps1:34）+ 两处报错文案硬编码列表（:141 漏
help/version、:158 含之，两处还不一致）+ help 总览文本。加一个子命令要改 4 处。
ldc 报错直接拼 `$LDC_COMMANDS`（ldc:119）。另：`wdc verify -h` 显示总览而非 verify 详解
（Help 触发时 Topic 为空）；ldc 侧 `-h` 挂子命令被静默吞——两边统一成「子命令 + -h = 单命令详解」。

## 内容

- 报错/提示文案的命令列表一律 `($wdcCommands -join ' / ')` 动态拼（help 总览是排版文案，
  保持手写但收口时人工核对——排版自由度与单一来源的边界：报错文案必须拼变量）
- Help 分支：`$Topic` 为空且 `$Command` 是显式传入的子命令（`$PSBoundParameters.ContainsKey('Command')`
  守卫——裸 `wdc -h` 仍出总览，因 Command 缺省 status 是默认值非用户输入）→ 按 $Command 出详解
- ldc 侧同语义联动（LDC cli-ux-batch 工单02）

## 验收清单

- [ ] `wdc verify -h` 出 verify 详解；`wdc -h` / 裸 `wdc help` 仍出总览
- [ ] 未知子命令报错列表来自 $wdcCommands（加词只改一处验证：临时加词报错跟随）
- [ ] validate 全绿

## 实录

- 真机：`wdc verify -h` 出 verify 详解、`wdc -h` 出总览（PSBoundParameters 守卫）；`wdc syncz` 报错列表来自 $wdcCommands（含新词 plan）；validate 全绿（cceb6b0）

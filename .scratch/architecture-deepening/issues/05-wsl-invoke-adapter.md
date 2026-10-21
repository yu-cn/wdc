Status: done

# 05 · WSL 调用与探测的适配层

## 问题

wsl.exe 的三个事实——输出带 NUL 要剥、默认用户靠 whoami 探测、提权上下文会挂死（已知坑①）——散在 6+ 个调用点各自处理；install-wsl-env.ps1 与 verify-machine.ps1 两条近乎复制的 bash 探测长单行已形态分叉（后者多查 links/id）。

## 方案（已实施）

common.ps1 增四个小函数：`Get-WslDistros`（-l -q 净化）、`Get-WslDefaultUser`（whoami 探测）、`Invoke-WslScript`（bash 跑脚本 → Lines / Exit / Ok；坑①守卫以注释入接口契约）、`ConvertTo-WslPath`（盘符路径转换）；两条探测单行合并为 `scripts/wsl/probe.sh`（key:value 单行输出，安装期 INFO 与验收断言同源解析）。install-wsl / install-wsl-env / verify-machine 全部改走适配层。

## 验收清单

- [x] 真机 WSL 阶段与 `wdc verify` 全绿（探测口径不变）——install-wsl-env 直跑全绿；verify -Quick 六断言全 OK，探测值与改前一致（docker 29.9.1 / uv 0.13.1 / node v24.22.1 / links 1 / id tidytorch）
- [x] 探测项增减只改一处（probe.sh 单一来源，两消费者自动跟随）
- [x] validate.ps1 全绿

## Comments

- 2026-10-21 实施（工单 04-06 批次）。附注两条：旧断言 `uv:0\.` 隐含主版本假设（uv 升 1.x 会假失败），随合并顺带改为「非 MISSING」；probe 输出较旧安装侧探测多 links / id / vp 三键（与断言面同集，正是「同口径」的目的）。

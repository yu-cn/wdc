Status: ready-for-agent

# 05 · WSL 调用与探测的适配层

## 问题

wsl.exe 的三个事实——输出带 NUL 要剥、默认用户靠 whoami 探测、提权上下文会挂死（已知坑①）——散在 6+ 个调用点各自处理；install-wsl-env.ps1 与 verify-machine.ps1 两条近乎复制的 bash 探测长单行已形态分叉（后者多查 links/id）。

## 方案候选

common.ps1 增 `Invoke-Wsl`（distro / user / 命令 → 干净输出）+ `Get-WslDefaultUser`；两条探测单行合并为 `scripts/wsl/probe.sh`（key:value 输出，安装期探测与验收断言同口径解析）。codebase-design 判据：已有两个真实消费者，接缝为真，不是假想。

## 验收清单

- [ ] 真机 WSL 阶段与 `wdc verify` 全绿（探测口径不变）
- [ ] 探测项增减只改一处（probe.sh）
- [ ] validate.ps1 全绿

## Comments

- 2026-10-21 开单（架构评估候选 5，Worth exploring）。

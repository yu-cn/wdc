# 工单03：inventory 补录 WSL 平台状态

Status: done

## 背景

inventory 的 WSL 节只收 `wsl -l -v`——`.wslconfig` / `wsl.conf` / DNS 姿态现状均不入账，跨机对账（ADR-0003 反向吸收判据）无从谈起（LETH 2026-11-07 清单实录：查无此物）。ADR-0008 后 .wslconfig/wsl.conf 已入声明（断言面有 verify 兜底），inventory 仍需记录**现状全貌**——尤其 DNS 姿态（dnscrypt 三层）定性为机器自留地后，跨机差异只能靠盘点呈现。

## 内容

- inventory-machine.ps1 WSL 节补录：
  - `.wslconfig`：在位/缺失、渲染事实（核数/内存配额）、与声明渲染一致否（Test-WslConfig 同源）
  - `wsl.conf`：全文逐行（小文件；Ubuntu 在位时有界捕获，未装 SKIP）
  - DNS 姿态探测：`dnscrypt-proxy` 包有无 + `/etc/systemd/resolved.conf.d/` 清单（自留地现状，非断言）
- 严格只读不变

## 验收清单

- [x] 本机跑出报告含三块内容且值正确
- [x] 无 WSL 机器路径 graceful（Ubuntu 探测门内收；.wslconfig 块纯 Test-Path——构造性 graceful，无 WSL 真机未复验）
- [x] validate 全绿

## 实录

- 真机输出：`.wslconfig: 在位 [ok]（机器 22 核/32GB → 渲染 16 核/16GB）`；wsl.conf 全文逐行（[boot]/[user]/[network] 三段）；`dnscrypt-proxy(apt): 已装` + `resolved drop-in: 50-dnscrypt-proxy.conf`
- validate 全绿（PSScriptAnalyzer 过 inventory-machine.ps1）

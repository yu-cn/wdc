# 工单02：`/etc/wsl.conf` 整文件管理权收归 WDC——保护合并

Status: done

## 背景

主人 2026-11-14 定夺「WSL 配置归 WDC」：按「配置属于谁」而非「文件在哪个文件系统」划界——wsl.conf 的读者是 WSL 平台（wslservice/init）非发行版内工具。工单41（2026-11-01）把它移交 LDC 是 root 直调缺 SUDO_USER 的实现便利，非领域理由。联动：LDC ADR-0021 / LDC 工单13 已先行收口（22122a2——机器形态段瘦身为默认 shell + docker 组两件）。

## 内容

- setup-ubuntu.sh root 阶段（委托 LDC install-packages.sh **之前**、SKIP_LDC 亦跑——WDC 自有面，CI 冒烟可覆盖）：wsl.conf **保护合并**声明键
  - `[boot]` `systemd=true`、`[user]` `default=<WDC_USER>`
  - 保护语义：段内首见替换、重复剔除、缺键段尾补、缺段文末补；**其余段与键（本机 DNS 姿态 `[network]`）原样保留保护不动**
  - 变更后提示 `wsl --shutdown` 生效（fresh-machine 时序不变：LDC docker_skipped 无 systemd 中间态自跳口径不变）
- verify-machine.ps1 WSL 相新增断言：两声明键在位且值正确（`[user] default` 与 `Get-WslDefaultUser` 探测值互证——两个独立来源）；Ubuntu 未就位 SKIP

## 验收清单

- [x] 本机（wsl.conf 已含声明键 + 手工 [network] 段）：root 阶段幂等跳过、[network] 原样保留
- [x] 真机 verify 断言绿；validate 全绿（shellcheck 过 setup-ubuntu.sh）
- [x] LDC 联动验收：本机 LDC verify --quick 绿（22122a2 已证）

## 实录

- 语义靶句（WSL 内副本五用例全过）：幂等双 NOCHANGE；值扰动（systemd=false/default=hacker）双 CHANGED 且复原=原件——**[network] 段全程未动**（cmp 实证）；裸 [boot] 文件补 [user] 段、[user] 缺键补段尾、空文件保底补段
- 真机 root 阶段实跑（`wsl -u root setup-ubuntu.sh root ubuntu -`）：首行 `wsl.conf 声明键已一致（保护合并幂等）`→ LDC 委托全 SKIP 幂等；verify -Quick 两声明键断言 OK（[user] default 与 whoami 探测互证）
- validate：shellcheck 过（setup-ubuntu.sh）；LDC 侧 root 阶段机器形态段新面（默认 shell / docker 组）真机全 SKIP

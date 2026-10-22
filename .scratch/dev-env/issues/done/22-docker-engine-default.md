# 22: WSL 侧 Docker Engine 纳入默认配置

**What to build:** 环境主人定夺（2026-10-21）：把原 README「默认不装，要用即装」的 WSL 侧 Docker Engine 纳入默认（通用核心）。改动：setup-ubuntu.sh root 阶段新增官方源安装（`have docker` 幂等守卫）+ `usermod -aG docker`（幂等；免 sudo 需重登 WSL 生效）+ 确保 `/etc/wsl.conf` 的 `[boot] systemd=true`（守护进程自启依赖；主机本已启用，写入为兜底新机）；探测/断言加 docker 项（不钉版本，同 gh 官方源浮动策略）；README Docker 节改「默认装」运维说明。Windows 侧 Docker Desktop 仍不声明（自留地）。

**Blocked by:** None

**Status:** ready-for-agent

- [x] setup-ubuntu.sh：Docker 官方源安装 + docker 组 + systemd 确保（均幂等）
- [x] install-wsl-env.ps1 探测 / verify-machine.ps1 断言加 docker
- [x] README：WSL 侧装箱清单加 Docker；Docker 节改默认装说明
- [x] 两机复验：主机已就位（见 Comments），verify 断言绿即收口；ASUS 待下次 sync 安装后复验

## Comments

- 2026-10-21（主机会话）：主机事实自查——docker 29.9.1 已装、默认用户已在 docker 组、wsl.conf `[boot] systemd=true` 且 PID1=systemd（守护进程自启就绪）。即主机早已手动就位，本工单是把现状纳入声明。
- 2026-10-22（ASUS 本机会话）：ASUS 侧复验收官——docker 29.9.1 在位（10-21 深夜起的 sync 已装）、今日提权 bootstrap 幂等通过（「Docker Engine（已装则跳过）」）、verify -Quick「WSL docker」断言绿。两机俱验，收口归档。（勘误：本机 hostname=ASUS，此前工单注释「主机会话」均指另一台机器。）

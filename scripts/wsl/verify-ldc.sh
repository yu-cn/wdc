#!/usr/bin/env bash
# verify-ldc.sh — WDC 对 WSL 侧的验收委托包装（工单32/LDC-0007）：发行版内一切断言走 LDC 单一实现，
# 退出码透传（0 全绿 / 1 有 FAIL）。WDC 侧只补机器形态差异：无 systemd 的发行版（wsl.conf 刚写入
# 未重启的中间态）透传 LDC_SKIP_DOCKER=1——与安装面 setup-ubuntu.sh 同判定，LDC 的 docker 断言
# 才与安装面口径一致。LDC 不在位 → FAIL 指回安装入口。
set -uo pipefail
LDC_DIR="$HOME/dev/ldc"

if [ ! -f "$LDC_DIR/scripts/verify-machine.sh" ]; then
    echo "[FAIL] WSL LDC 委托 - $LDC_DIR 不在位——重跑 bootstrap（install-wsl-env.ps1 会定位/clone LDC）"
    exit 1
fi
if [ ! -d /run/systemd/system ]; then
    export LDC_SKIP_DOCKER=1
fi
exec bash "$LDC_DIR/scripts/verify-machine.sh" --quick

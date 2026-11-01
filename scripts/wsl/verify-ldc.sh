#!/usr/bin/env bash
# verify-ldc.sh — WDC 对 WSL 侧的验收委托包装（工单32/LDC-0007）：发行版内一切断言走 LDC 单一实现，
# 退出码透传（0 全绿 / 1 有 FAIL）。工单41 边界最小核心化后 WDC 只保留透传验收面——机器形态差异
# （无 systemd 中间态跳过 docker 域）由 LDC 的 docker_skipped() 自判定（verify-machine.sh 同读），
# 本包装不再注入 LDC_SKIP_DOCKER（env 变量保留为外部覆盖语义，ADR-0007 补记 2026-11-01）。
# LDC 不在位 → FAIL 指回安装入口。
set -uo pipefail
LDC_DIR="$HOME/dev/ldc"

if [ ! -f "$LDC_DIR/scripts/verify-machine.sh" ]; then
    echo "[FAIL] WSL LDC 委托 - $LDC_DIR 不在位——重跑 bootstrap（install-wsl-env.ps1 会定位/clone LDC）"
    exit 1
fi
exec bash "$LDC_DIR/scripts/verify-machine.sh" --quick

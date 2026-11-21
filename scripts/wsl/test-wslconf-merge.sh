#!/usr/bin/env bash
# test-wslconf-merge.sh — wsl.conf 保护合并单测（v1 收官批 2026-11-22）
# 用例覆盖 ADR-0008 四语义 + 守护面：首见替换/重复剔除/缺键段尾补/缺段文末补/未管理段保护/
# CRLF 容忍/幂等（无变更返回 1）/空文件。本地 WSL 与 CI 容器均可跑（纯临时文件，不碰 /etc）
set -uo pipefail
SELF="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=scripts/wsl/wslconf-lib.sh
. "$SELF/wslconf-lib.sh"

PASS=0; FAIL=0
t() { # t <用例名> <输入（printf 串）> <段> <键值> <期望输出（printf 串）> <期望返回码>
    local name="$1" input="$2" sec="$3" kv="$4" want="$5" wantrc="$6" f got rc
    f=$(mktemp)
    printf '%b' "$input" > "$f"
    ensure_wslconf_key "$sec" "$kv" "$f"; rc=$?
    got=$(cat "$f"); rm -f "$f"
    local wantout; wantout=$(printf '%b' "$want")
    if [ "$got" = "$wantout" ] && [ "$rc" -eq "$wantrc" ]; then
        PASS=$((PASS+1)); echo "[OK] $name"
    else
        FAIL=$((FAIL+1)); echo "[FAIL] $name (rc=$rc 期望 $wantrc)"; echo "--- got ---"; printf '%s\n' "$got"; echo "--- want ---"; printf '%s\n' "$wantout"
    fi
}

# 1 首见替换（改值，声明值生效）
t '首见替换' '[boot]\nsystemd=false\n' boot 'systemd=true' '[boot]\nsystemd=true\n' 0
# 2 重复剔除（段内多键只留声明值一个）
t '重复剔除' '[boot]\nsystemd=false\nsystemd=true\n' boot 'systemd=true' '[boot]\nsystemd=true\n' 0
# 3 缺键段尾补（[boot] 段在但无键）
t '缺键段尾补' '[boot]\n' boot 'systemd=true' '[boot]\nsystemd=true\n' 0
# 4 缺段文末补（整段缺失——文末空行+段+键）
t '缺段文末补' '[boot]\nsystemd=true\n' user 'default=dev' '[boot]\nsystemd=true\n\n[user]\ndefault=dev\n' 0
# 5 未管理段保护（[network] 原样保留，合并 [boot] 不动它）
t '未管理段保护' '[boot]\nsystemd=false\n[network]\ngenerateResolvConf = false\n' boot 'systemd=true' \
  '[boot]\nsystemd=true\n[network]\ngenerateResolvConf = false\n' 0
# 6 CRLF 容忍（带 \r 的段头/键行正确识别与处理）
t 'CRLF 容忍' '[boot]\r\nsystemd=false\r\n' boot 'systemd=true' '[boot]\nsystemd=true\n' 0
# 7 幂等（已一致——返回 1 无变更）
t '幂等无变更' '[boot]\nsystemd=true\n' boot 'systemd=true' '[boot]\nsystemd=true\n' 1
# 8 空文件（直接段+键）
t '空文件' '' boot 'systemd=true' '[boot]\nsystemd=true\n' 0

echo "=== wsl.conf 保护合并单测：$PASS 过 / $FAIL 败 ==="
[ "$FAIL" -eq 0 ]

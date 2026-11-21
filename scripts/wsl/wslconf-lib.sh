#!/usr/bin/env bash
# wslconf-lib.sh — wsl.conf 保护合并单一来源（ADR-0008；LDC ADR-0021 收编回 WDC）
# 从 setup-ubuntu.sh 抽出为可测库（v1 收官批 2026-11-22）：只管声明键（[boot] systemd /
# [user] default），其余段与键（如本机 DNS 姿态 [network]）保护不动。setup-ubuntu 与单测共源。
# 单测：scripts/wsl/test-wslconf-merge.sh（本地 WSL / CI 容器均可跑）

ensure_wslconf_key() {
    # 保护合并一枚声明键：段内首见替换、重复剔除、缺键段尾补、缺段文末补；其余行原样保留。
    # $1=段名（不含方括号） $2=键值行（k=v） $3=目标文件（默认 /etc/wsl.conf——单测传临时文件）
    # 写回走 cat > 原 inode（保留属主/权限，mktemp 是 0600）。返回 0=有变更已写回，1=无变更
    local sec="[$1]" kv="$2" f="${3:-/etc/wsl.conf}" tmp
    tmp=$(mktemp)
    awk -v sec="$sec" -v kv="$kv" -v k="${kv%%=*}" '
        function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
        BEGIN { insec = 0; done = 0 }
        {
            line = $0; sub(/\r$/, "", line)
            if (line ~ /^[ \t]*\[[^]]*\][ \t]*$/) {
                if (insec && !done) print kv
                insec = (trim(line) == sec); print line; next
            }
            if (insec && line ~ "^[ \t]*" k "[[:space:]]*=") {
                if (!done) print kv
                done = 1; next
            }
            print line
        }
        END {
            if (!done) {
                if (insec) print kv
                else { if (NR > 0) print ""; print sec; print kv }
            }
        }
    ' "$f" > "$tmp"
    if ! cmp -s "$f" "$tmp"; then
        cat "$tmp" > "$f"
        rm -f "$tmp"
        return 0
    fi
    rm -f "$tmp"
    return 1
}

#!/usr/bin/env bash
# setup-ubuntu.sh — WSL 侧薄委托（工单32；ADR-0007 统筹：发行版内一切收敛走 LDC 单一实现）
# 本脚本只剩 WDC 保留职责的包装层：WSL 生命周期引导（apt 引导依赖 / wsl.conf systemd / 默认 shell）
# + WDC 特有 opinion（移除清单 Go 等）+ 身份带过。包/语言栈/dotfiles/验收全部委托姊妹仓库 LDC
# （clone 到 ~/dev/ldc，仓库步与 ldc sync 同语义）。由 install-wsl-env.ps1 调用，两种角色各跑一次：
#   root: LDC 引导依赖 → LDC 定位（以默认用户身份）→ 委托 install-packages.sh → WDC opinion
#   user: 身份带过 → LDC 定位 → 委托 bootstrap.sh（root 阶段已核销自动跳过）
set -euo pipefail

ROLE="${1:?用法: setup-ubuntu.sh <root|user|__ensure_ldc> <user> [win身份文件路径]}"
WDC_USER="${2:?}"
# 身份带过唯一动作点（LDC 对已存在的 .gitidentity 不覆盖——占位护栏不破坏）
IDENT_SRC="${3:-}"
LDC_URL="https://github.com/yu-cn/ldc.git"

log() { printf '[setup-ubuntu] %s\n' "$*"; }

user_home() { getent passwd "$WDC_USER" | cut -d: -f6; }

systemd_ready() { [ -d /run/systemd/system ]; }

ensure_ldc() {
    # LDC 定位（ADR-0007 契约1；$HOME 必须已是目标用户的 home）：~/dev/ldc 不存在则 clone；
    # 已存在则 fetch + pull --ff-only（与 ldc sync 仓库步同语义），分叉/本地领先中止交人工
    local dir="$HOME/dev/ldc" counts ahead behind
    if [ -d "$dir" ] && [ ! -d "$dir/.git" ]; then
        log "ERROR: $dir 已存在但不是 git 仓库——不代删，人工处置后重跑"; exit 1
    fi
    if [ ! -d "$dir" ]; then
        log "clone LDC → $dir"
        mkdir -p "$(dirname "$dir")"
        git clone "$LDC_URL" "$dir"
    fi
    if git -C "$dir" remote get-url origin >/dev/null 2>&1; then
        git -C "$dir" fetch --quiet
        # rev-list 输出 TAB 分隔（"ahead<TAB>behind"）——read 切分，勿按空格 %%/##
        local ahead=0 behind=0
        read -r ahead behind <<<"$(git -C "$dir" rev-list --left-right --count 'HEAD...origin/main' 2>/dev/null || printf '0 0')"
        if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
            log "ERROR: ~/dev/ldc 与 origin/main 分叉（领先 $ahead / 落后 $behind）——人工处理（ldc 仓库内对齐）后重跑"; exit 1
        fi
        if [ "$ahead" -gt 0 ]; then
            log "ERROR: ~/dev/ldc 本地领先 $ahead 个提交未推送——人工处理（push 或对齐）后重跑"; exit 1
        fi
        if [ "$behind" -gt 0 ]; then
            git -C "$dir" pull --ff-only
            log "已拉取 LDC $behind 个提交"
        else
            log "LDC 已与 origin/main 一致"
        fi
    else
        log "LDC 无 origin 远端——跳过仓库同步"
    fi
}

if [ "$ROLE" = "__ensure_ldc" ]; then
    # 内部角色：root 阶段经 su -l 以默认用户身份调回本脚本，保证 clone 落在用户 home、owner 正确
    ensure_ldc
    exit 0
fi

if [ "$ROLE" = "root" ]; then
    log "LDC 引导依赖（git curl ca-certificates gnupg——clone 与 LDC 厂商 apt 源的前置）"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq git curl ca-certificates gnupg >/dev/null

    log "LDC 定位（以 $WDC_USER 身份落 ~/dev/ldc）"
    su -l "$WDC_USER" -c "bash '$0' __ensure_ldc '$WDC_USER'"

    log "systemd 自启确保（WDC 保留职责：Docker 守护进程依赖）"
    if ! grep -q '^systemd=true' /etc/wsl.conf 2>/dev/null; then
        printf '\n[boot]\nsystemd=true\n' >> /etc/wsl.conf
        log "已写入 [boot] systemd=true——wsl --shutdown 后下次进入生效"
    fi

    # 无 systemd 的中间态（wsl.conf 刚写入未重启）里 systemctl 不可用——透传 LDC_SKIP_DOCKER=1
    #（LDC 的 root 完成度核销同读此变量，与安装面对齐）；生效后重跑自动补装（幂等）
    if ! systemd_ready; then
        log "systemd 未生效（wsl.conf 刚写入的中间态）——透传 LDC_SKIP_DOCKER=1，docker 域待重启后重跑补装"
        export LDC_SKIP_DOCKER=1
    fi

    log "root 委托 LDC install-packages.sh（apt 清单/gh/Docker/桌面应用域按机器形态自动 SKIP）"
    bash "$(user_home)/dev/ldc/scripts/install-packages.sh"

    log "WDC opinion · 移除清单：移除 Go（工单21：退出通用核心；~/go 用户数据不碰）"
    [ -d /usr/local/go ] && rm -rf /usr/local/go || true

    log "WDC opinion · 默认 shell = bash（LDC 未接管 chsh 前保留在包装层；root 改免 PAM）"
    current_shell=$(getent passwd "$WDC_USER" | cut -d: -f7)
    [ "$current_shell" = "/bin/bash" ] || chsh -s /bin/bash "$WDC_USER"

    log "WDC opinion · docker 组（LDC 的 usermod 依赖 SUDO_USER，root 直调无此变量——包装层补，幂等）"
    if getent group docker >/dev/null 2>&1 && ! getent group docker | grep -qw "$WDC_USER"; then
        usermod -aG docker "$WDC_USER"   # 免 sudo 需重新登录 WSL 生效（工单22）
    fi

    log "root 阶段完成"
    exit 0
fi

# ---------------- user 阶段 ----------------
log "身份带过（从 Windows 侧带过，两侧一致；LDC 对已存在的 .gitidentity 不覆盖）"
if [ ! -e "$HOME/.gitidentity" ] && [ -n "$IDENT_SRC" ] && [ -f "$IDENT_SRC" ]; then
    cp "$IDENT_SRC" "$HOME/.gitidentity"
fi

if ! systemd_ready; then
    export LDC_SKIP_DOCKER=1   # 与 root 阶段同判定：bootstrap 的 root 完成度核销才不误报 docker
fi

log "LDC 定位（~/dev/ldc，已存在则对齐 origin/main）"
ensure_ldc

log "user 委托 LDC bootstrap.sh（root 已核销自动跳过；无 GNOME 会话桌面域 SKIP；幂等）"
out=$(mktemp)
set +e
bash "$HOME/dev/ldc/bootstrap.sh" 2>&1 | tee "$out"
rc=${PIPESTATUS[0]}
set -e
# bootstrap 退出码 2 = 有待办手工步骤。WSL 机器形态的唯一预期待办 = 桌面域（无 GNOME 会话，
# 登录桌面重跑在 WSL 永不适用）；root 交接 / git 身份待办是真问题，不容忍。模式用「标签：关键词」
# ——phase 标题也含「· 标签」（如 === 3/7 · root 阶段 ===），裸标签会误伤；待办明细才有冒号后缀
if [ "$rc" -eq 2 ] && grep -q '桌面域：登录' "$out" \
    && ! grep -q 'root 阶段：cd' "$out" && ! grep -q 'git 身份：编辑' "$out"; then
    log "bootstrap 待办=桌面域（WSL 无 GNOME 会话，预期内不适用）——视为完成"
    rc=0
fi
rm -f "$out"
if [ "$rc" -ne 0 ]; then
    log "ERROR: LDC bootstrap 退出码 $rc——明细见上方，修复后重跑（幂等）"
fi
exit "$rc"

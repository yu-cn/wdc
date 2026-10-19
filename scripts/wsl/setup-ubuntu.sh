#!/usr/bin/env bash
# setup-ubuntu.sh — Ubuntu 发行版内环境（WDC WSL 侧，工单 07）
# 由 install-wsl-env.ps1 调用，两种角色各跑一次：
#   root: apt 工具集 + gh 官方源 + Go 官方 tarball（钉版本）+ 默认 shell 改 bash
#   user: uv + vp + starship + Homebrew 残留清理 + dotfiles 链接 + 身份带过
set -euo pipefail

ROLE="${1:?用法: setup-ubuntu.sh <root|user> <user> <repo_wsl路径> [win身份文件路径]}"
WDC_USER="${2:?}"
REPO_WSL="${3:?}"
GO_VERSION="1.27.2"     # 钉版本：升级时改这里并在吸收账本记一笔
VP_VERSION="1.3.0"      # 与 Windows 侧 install-languages.ps1 保持一致

log()  { printf '[setup-ubuntu] %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

if [ "$ROLE" = "root" ]; then
    export DEBIAN_FRONTEND=noninteractive
    log "apt 基础包（build-essential git curl fd-find bat jq zoxide）"
    apt-get update -qq
    apt-get install -y -qq build-essential git curl fd-find bat jq zoxide gpg ca-certificates >/dev/null

    log "gh（apt 官方源）"
    if ! have gh; then
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
        chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
        apt-get update -qq && apt-get install -y -qq gh >/dev/null
    fi

    log "Go ${GO_VERSION}（官方 tarball，钉版本）"
    if [ ! -x /usr/local/go/bin/go ] || ! /usr/local/go/bin/go version | grep -q "go${GO_VERSION}"; then
        arch=$(dpkg --print-architecture)
        curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${arch}.tar.gz" -o /tmp/go.tgz
        rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tgz && rm -f /tmp/go.tgz
    fi

    log "默认 shell = bash（反转 wsl-comfort 的 zsh）"
    current_shell=$(getent passwd "$WDC_USER" | cut -d: -f7)
    [ "$current_shell" = "/bin/bash" ] || chsh -s /bin/bash "$WDC_USER"

    log "root 阶段完成"
    exit 0
fi

# ---------------- user 阶段 ----------------
log "uv（管 Python）"
# 显式路径探测：非登录 shell 的 PATH 看不到 ~/.local/bin（同 vp 的问题，工单13）
if [ ! -x "$HOME/.local/bin/uv" ]; then curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null; fi
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

log "vp ${VP_VERSION}（管 Node，与 Windows 侧同工具同钉子）"
# 显式路径探测：非登录 shell 的 PATH 看不到已装的 vp（工单13）；两种官方布局都认（工单12）
vp_bin=""
for d in "$HOME/.vite-plus/bin/vp" "$HOME/.local/share/vite-plus/bin/vp"; do
    if [ -x "$d" ]; then vp_bin="$d"; break; fi
done
if [ -z "$vp_bin" ]; then
    export VP_VERSION
    curl -fsSL https://vite.plus/sh | bash >/dev/null   # 注意：官方给的是 |sh，但其脚本含 bash 语法，Ubuntu 的 sh=dash 会 Bad substitution
    for d in "$HOME/.vite-plus/bin/vp" "$HOME/.local/share/vite-plus/bin/vp"; do
        if [ -x "$d" ]; then vp_bin="$d"; break; fi
    done
fi
if [ -z "$vp_bin" ]; then log "ERROR: vp 二进制未找到（安装器执行后仍缺失）"; exit 1; fi
# 默认跟随 LTS：与 Windows 侧 install-languages.ps1 三步对齐（工单13——此前干净机器 WSL 侧无 Node）
"$vp_bin" env default lts
"$vp_bin" env install lts
"$vp_bin" env on

log "starship"
if ! have starship; then curl -sS https://starship.rs/install.sh | sh -s -- -y >/dev/null; fi

log "Homebrew 残留清理（本机应不存在）"
[ -d "$HOME/.linuxbrew" ] && rm -rf "$HOME/.linuxbrew" || true

log "dotfiles 链接（备份旧文件为 *.bak）"
link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then return 0; fi
    [ -e "$dst" ] && [ ! -L "$dst" ] && mv "$dst" "$dst.bak"
    ln -sfn "$src" "$dst"
}
link "$REPO_WSL/dotfiles/wsl/bashrc"           "$HOME/.bashrc"
link "$REPO_WSL/dotfiles/wsl/gitconfig"        "$HOME/.gitconfig"
mkdir -p "$HOME/.config"
link "$REPO_WSL/dotfiles/shared/starship.toml" "$HOME/.config/starship.toml"

log "身份文件（从 Windows 侧带过，两侧一致）"
IDENT_SRC="${4:-}"
if [ ! -e "$HOME/.gitidentity" ] && [ -n "$IDENT_SRC" ] && [ -f "$IDENT_SRC" ]; then
    cp "$IDENT_SRC" "$HOME/.gitidentity"
fi

log "user 阶段完成"

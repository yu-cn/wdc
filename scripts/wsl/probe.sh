#!/usr/bin/env bash
# probe.sh — WSL 侧环境探测（key:value 单行输出；安装期 INFO 与验收断言共用，防两处漂移，工单05）
# 由 install-wsl-env.ps1 与 verify-machine.ps1 经 wsl.exe 调用。
# 显式路径探测：非交互 shell 里 bashrc 会提前 return，不能依赖其 PATH；vp 两种官方布局都认（工单12）
printf 'shell:%s\n' "$(getent passwd "$(whoami)" | cut -d: -f7)"
printf 'docker:%s\n' "$(/usr/bin/docker --version 2>/dev/null | cut -d' ' -f3 || echo MISSING)"
printf 'uv:%s\n' "$("$HOME/.local/bin/uv" --version 2>/dev/null | cut -d' ' -f2 || echo MISSING)"
if [ -x "$HOME/.vite-plus/bin/vp" ] || [ -x "$HOME/.local/share/vite-plus/bin/vp" ]; then
    printf 'vp:OK\n'
else
    printf 'vp:MISSING\n'
fi
if [ -x "$HOME/.vite-plus/bin/node" ]; then
    printf 'node:%s\n' "$("$HOME/.vite-plus/bin/node" -v)"
elif [ -x "$HOME/.local/share/vite-plus/bin/node" ]; then
    printf 'node:%s\n' "$("$HOME/.local/share/vite-plus/bin/node" -v)"
else
    printf 'node:MISSING\n'
fi
printf 'links:%s\n' "$(readlink "$HOME/.bashrc" 2>/dev/null | grep -ci wdc)"
_gid=$(git config user.name 2>/dev/null)
printf 'id:%s\n' "${_gid:-MISSING}"

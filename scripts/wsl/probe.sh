#!/usr/bin/env bash
# probe.sh — WSL 特有项探测（key:value 单行输出；安装期 INFO 与验收断言共用，防两处漂移，工单05）
# 发行版内一切（包/语言栈/dotfiles/身份）已委托 LDC verify（工单32/LDC-0007）——本探针只剩
# WDC 保留职责的 WSL 特有项：默认 shell、systemd 生效态。由 install-wsl-env.ps1 与
# verify-machine.ps1 经 wsl.exe 调用。
printf 'shell:%s\n' "$(getent passwd "$(whoami)" | cut -d: -f7)"
if [ -d /run/systemd/system ]; then
    printf 'systemd:yes\n'
else
    printf 'systemd:no\n'
fi

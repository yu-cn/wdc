# 01 定位改口径：ADR-0009 + README/GLOSSARY/wdc 帮助/CHANGELOG

Status: ready-for-agent
Type: task

## 内容

一次性定位的叙事落点 + ADR-0009：README（首段/plan 行/sync 行/bootstrap 行/重跑口径/使用与改造）、GLOSSARY（首段 + 三新词条 + bootstrap/机器对等/分流轻触）、scripts/wdc.ps1（帮助文本三处，命令面不动）、docs/forking.md（标题口径）、CHANGELOG Unreleased。

## 验收

- [x] ADR-0009 入 docs/adr/，含拒绝的替代（装完即走 / 删机制 / sync 改名）
- [x] README 首段出新定位，无「日常一键同步」口径
- [x] GLOSSARY 三新词条 + 首段姿态句
- [x] wdc.ps1 帮助无「日常一键」，命令名/旗标/退出码未动
- [x] validate.ps1 全绿

## Comments

- 2026-11-21 开票即收（同会话）。validate 全绿含 CLI parity 契约断言（命令表未动即契约无涉，如预期）。执行中发现并修正一处既有认知错误：本仓已有 `fresh-machine.yml` 新机冒烟 CI（月度定时 + 手动，fresh clone → 5.1 入口 bootstrap → 幂等重跑零变更证明）——CI 面比「只跑 validate」宽，且恰与新的一次性定位对齐，无需改动。


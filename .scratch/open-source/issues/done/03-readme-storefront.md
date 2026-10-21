# 03: README 开源门面优化

**What to build:** 环境主人指示（2026-10-21）：README 作为开源项目门面还需优化。方向：访客第一屏看懂「这是什么、一条命令得到什么」；结构按门面逻辑重排，实质内容不丢。

**Blocked by:** None

**Status:** ready-for-agent

- [x] 顶部改造：一句定位 tagline + CI（validate workflow）/ License（MIT）徽章；标题去「个人」前置，正文首句如实说明作者个人环境开源
- [x] 新增「一条命令得到什么」装箱清单：系统（27 项注册表）/ CLI（17 包）/ 编辑器（VSCode + 32 扩展）/ 语言运行时（vp·uv·Go）/ WSL 侧 / dotfiles，六组带 configs 链接，数字以仓库实测为准
- [x] 快速开始五件配合事项收进 `<details>` 折叠（summary 保留一览），第一屏更干净
- [x] 其余节（使用与改造/常用命令/各层职责/Docker/新开发机接入/文档/许可证）原文保留，节序按「是什么→装什么→怎么装→怎么改→日常用→架构→高级」重排
- [x] 不发明事实：ADR 未展开 WDC 缩写含义，门面不写；徽章只挂实际存在的 workflow 与许可证

## Comments

- 2026-10-21（主机会话）：数字自查——base-windows 27 项资源（逐个数）、cli-tools 17 包、扩展清单 grep 非空非注释行 32、WSL Go 钉 1.27.2（setup-ubuntu.sh）。徽章在仓库仍私有时显示 unknown 属预期，翻公开后自动就位。

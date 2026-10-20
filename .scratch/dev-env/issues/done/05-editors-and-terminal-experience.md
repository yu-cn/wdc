# 05: editors 域与 WT/VSCode 体验优化

**What to build:** 环境主人应用 editors 配置后：VSCode 收敛为 winget 用户版单份（商店 MSIX 卸载）、23 个扩展自动装齐（不钉版本）、保存时格式化真实生效（Python→ruff、TS/JS/JSON/CSS→prettier、ruff 整理 import）、文件卫生三件套与 .venv 排除就位、Settings Sync 关闭；Windows Terminal 主题真正生效（Catppuccin 配色正式定义并全局默认，替换断链引用）、原生 Ubuntu profile 显示、Comfort Shell profile 与死掉的 Copilot profile 及其 fragment 清除。三个 shell（pwsh/Git Bash/WSL bash）的别名、fzf、zoxide 体验一致（Git Bash 现有 rc 结构为统一模板）。

**Blocked by:** 01, 02

**Status:** ready-for-agent

- [ ] VSCode 仅存 winget 用户版一份，扩展 23 项装齐
- [ ] Python 文件保存触发 ruff 格式化与 import 整理；TS/CSS 保存触发 prettier
- [ ] 文件卫生三件套与 .venv 的 watcher/search 排除生效
- [ ] Settings Sync 处于关闭
- [ ] WT 全局配色为已定义的 Catppuccin 方案（不再引用不存在的名字）
- [ ] WT 中 WSL 入口为原生 Ubuntu profile；Comfort Shell 与 Copilot profile 及两个 fragment 消失
- [ ] gs/gl/gd 别名与 Ctrl-R/Ctrl-T/Alt-C、z 跳目录在 pwsh 与 Git Bash 中行为一致

## Comments

- 2026-10-19（自主执行会话）：已完成并通过验收标准，实现落在对应 commit（git log 按工单号检索）。

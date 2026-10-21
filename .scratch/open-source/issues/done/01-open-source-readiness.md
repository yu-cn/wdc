# 01: 开源化仓库侧准备（审计 + LICENSE + README/CONTRIBUTING）

**What to build:** 私有库转公开前的仓库侧准备：全库敏感信息审计（凭据、邮箱、机器派生值、个人路径、git 身份）、补 LICENSE、README 去私有措辞并新增「朋友怎么用」（直接用 / fork 改造两路径）、新增 CONTRIBUTING.md。公开动作（翻可见性、许可证最终确认）不在本工单，见 02。

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [x] 敏感信息审计：git 提交作者均为 GitHub noreply 邮箱；全库无明文邮箱/token/密码；dotfiles 无机器派生值（terminal-settings.json 的 GUID 均为 Windows Terminal 内置静态 GUID，WSL 条目按 ADR-0004 安装期渲染）；gitconfig 身份走每机本地 `~/.gitidentity`；脚本无写死仓库地址（fork 可直接 bootstrap）。`.scratch/` 实录含机器名（ASUS）与 `C:\Users\User` 本机路径——通用用户名、无凭据，属轻度个人化内容
- [x] LICENSE（MIT，版权人 yu-cn——默认放置，最终定夺见工单 02）
- [x] README：删「私有仓库，需登录」措辞；intro 标注开源与 MIT；新增「朋友怎么用」节（两种用法 + fork 改造清单）；文档节收 CONTRIBUTING；文末增许可证节
- [x] CONTRIBUTING.md：fork 自用为主、通用核心判据（ADR-0003）、外部走 GitHub Issues/PR、CI 即 validate
- [x] `pwsh validate.ps1` 全绿后按显式路径提交（禁 `git add -A`）

## Comments

- 2026-10-21（主机会话）：审计与改动一气呵成。`gh repo view` 确认远端当前 PRIVATE（github.com/yu-cn/WDC）；logs/ 未被跟踪（`*.log` 已 ignore）。审计结论：内容本身已达公开安全水准——身份文件、noreply 邮箱、ADR-0004 机器自适应渲染这些既有设计把卫生提前做完了。

- 2026-10-21（主机会话）补记：环境主人反馈——「朋友」是对话语境（描述谁会用），不应进公开文档；README 节名改为「使用与改造」，README/CONTRIBUTING 相关措辞同步中性化。

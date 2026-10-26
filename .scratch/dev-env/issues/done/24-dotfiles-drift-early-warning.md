# 24: dotfiles 漂移即时提示（开新终端即见）

**What to build:** 优化方向研究 P1-②。写穿是唯一复发事故类（工单14/17 及 378cb68），现状靠 verify 事后抓，两次 sync 之间是盲区。设计取舍：原分析设想的 starship 提示符模块，落地评估后弃——starship 自定义命令在 Windows 走 cmd、WSL 走 sh，一份 toml 无法三 shell 通用（破坏「一份配置」原则），且每提示符一次 git 调用有延迟感。改为**开终端一次性提示**（pwsh profile + Git Bash bashrc）：漂移>0 时黄色一行「commit 吸收或 wdc triage 处置」——同时把 collaboration 红线「dotfiles 提交前核对无漂移」自动化。`--no-optional-locks` 防与 lazygit/starship 抢锁。WSL 侧**不加**：写穿是 Windows 应用（WT/VSCode UI）行为，且 WSL 经 /mnt 跑 git status 慢（drvfs）。

**Blocked by:** None

**Status:** done

- [x] dotfiles/windows/pwsh-profile.ps1：漂移提示（守卫式，~/.wdc 指针缺失静默跳过）
- [x] dotfiles/windows/bashrc：同款（bash 方言，unset 临时变量）
- [x] 主机实测：临时改 dotfiles 模板 → 新开 shell 出黄字 → 还原后消失
- [x] 两机复验：下次 sync 后日常使用观感（延迟可接受性、误报率）

## Comments

- 2026-10-21（主人会话）：合法的模板编辑（吸收流）也会提示——这不是误报而是红线提醒「改完记得 commit」，与吸收流程语义一致。
- 2026-10-22（ASUS 本机会话）：ASUS 侧今日两次 sync 部署到位；无漂移状态下正确保持静默（零误报）。黄字提示的正面观感仍待一次真实漂移事件，暂不勾选。（勘误：本机 hostname=ASUS。）
- 2026-10-26（LETH 会话，工单38 批次收口）：受控漂移实测补齐正面观感——向渲染拷贝 `~/.config/starship.toml` 追加一行注释制造落点漂移，新开 pwsh 即见黄字「wdc: dotfiles 落点漂移（starship）——重跑 bootstrap 渲染，或 wdc triage 分流」，同窗口内 Git Bash 侧 bashrc 同款提示亦正确触发（工具 shell 每次调用加载 bashrc 所见）；删除该行后复归静默、`wdc status` 漂移全绿。延迟实测：带 profile 启动较 `-NoProfile` 基线差约 0.9s（含漂移检查 7 文件 hash + git porcelain 探测，LETH 冷启），交互开壳无感级。两机观察齐（ASUS 零误报静默 + LETH 正负两态），末项勾选，归档。

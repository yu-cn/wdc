# WDC — 个人 Windows 开发环境

把「我的 Windows 开发环境」变成可重放、可迁移的声明式仓库：新机器 clone 后跑一条命令即得完整环境；一次性配置姿态（ADR-0009）——跑完即休眠，机器日常归用户、漂移合法，更新与回归皆为显式手动行为。WDC 即 Windows Developer Config，名字沿自 microsoft/WindowsDeveloperConfig——初始构建的参考范例之一（做法自建、不 fork、无跟随义务，ADR-0001 及 2026-11-07 修订标注）。

## Language

**环境配置**:
声明「一台机器应当处于什么状态」的幂等配置——装哪些软件、开哪些系统设置。
_Avoid_: settings、安装脚本

**dotfiles**:
声明「我这个人偏好什么」的个人配置文件（shell profile、编辑器与终端设置等），与环境配置相对：机器 vs 人。
_Avoid_: 配置文件（在本仓库语境下歧义）

**bootstrap**:
把一台新机器带到目标状态的唯一入口：clone 后运行的一条命令，应用全部环境配置并安装 dotfiles；一次性配置、更新、回归共用同一条幂等入口（ADR-0009）。
_Avoid_: setup.sh、装机脚本

**一次性配置（one-shot）**:
WDC 的默认姿态（ADR-0009）：bootstrap 跑一次把机器带到声明状态，之后 WDC 不主动碰机器——无定时收敛、无漂移纠察；漂移是机器日常的合法状态，不是待处置的异常。
_Avoid_: 持续收敛（旧姿态词）、装机即走（本仓保留显式更新/回归的重放能力）

**更新（update）**:
显式手动行为（ADR-0009）：拉取新声明后重跑收敛（`wdc sync` / bootstrap），把机器带到新声明状态。
_Avoid_: 自动更新

**回归（re-converge）**:
显式手动行为（ADR-0009）：漂移后重跑收敛，把机器拉回**当前**声明状态；漂移积累越久单次回归覆盖面越大，先 `wdc plan` 干跑预演。
_Avoid_: 回滚（指回到旧版本或配置前状态，另一回事）、同步（旧叙事的日常口径已废）

## 分层

**Windows 侧**:
运行在 Windows 本体上的那一半环境（软件、系统设置、Windows 下的 dotfiles）。

**WSL 侧**:
运行在 WSL/Ubuntu 里的另一半环境（apt 包、Linux 下的 dotfiles），与 Windows 侧同仓库管理、各自的安装机制独立。
_Avoid_: Linux 环境（指代不清）

**WSL 平台配置**:
WSL 平台自身的配置层（ADR-0008）：Windows 侧 `%USERPROFILE%\.wslconfig`（VM 形态——机器派生值安装期公式渲染）+ 发行版内 `/etc/wsl.conf`（root 阶段保护合并声明键 `[boot]` systemd / `[user]` default）。按「配置属于谁」而非「文件在哪个文件系统」划界，归 WDC 单一实现（LDC ADR-0021 收编）；wsl.conf 未管理段（如 DNS 姿态 `[network]`）保护不动，属机器自留地。
_Avoid_: WSL 设置（歧义）

**通用核心**:
配置中每台开发机都需要的那部分；某项只要存在「某台机器不需要」的情形即出局，归机器自留地。判据双轴（ADR-0003 修订标注，2026-11-21）：除「每机都需要」外还须**开发环境相关**——通用消费软件（浏览器/网盘/媒体/聊天类）即使人人用也出局（Chrome 判例：Edge 预装等价）；系统级开发提效（Everything/PowerToys 类）保留。
_Avoid_: 默认配置

**机器自留地**:
不进仓库、由各台机器自行安装维护的个性化工具（如本机的 JetBrains 套件）；bootstrap 对其一概不碰。
_Avoid_: 可选模块

**移除清单**:
bootstrap 显式执行的一小份清理清单，只含两类（ADR-0007）：本仓自清理（退役 WT fragments）与迁移冲突（VSCode 商店版换 winget 版）；**清单外一概不碰**——不卸载任何已装软件与语言栈，机器自留地绝对安全。
_Avoid_: 卸载列表、清理脚本

**运行锁**:
bootstrap 收敛进程持有的全局命名互斥体（`Global\WdcBootstrap`）：同一时刻只允许一个收敛会话（bootstrap / `wdc sync`）在跑，后来者以非零退出码（3）让路；持锁进程崩溃由内核语义自动转交，无陈旧锁。
_Avoid_: 锁文件（指代不同的实现）

**续跑任务**:
WSL 功能启用需重启时登记的一次性登录计划任务（`WdcBootstrapResume`）：重启登录后自动重跑 bootstrap 收尾；任意一次 bootstrap 启动即被清除，绝不循环。
_Avoid_: RunOnce、自启项（指代不同的机制）

**机器对等**:
所有开发机地位平等、无主从：每台 clone 后 bootstrap 即得完整环境，工单与决策经仓库（`.scratch/` + git）流转，由环境主人定夺、任一机器会话可执行。机器各漂各的，一致性只在各自手动更新/回归的时点对齐（ADR-0009），无「随时全绿」承诺。
_Avoid_: 主机、主开发机、第二台机

**双边最优化**:
WDC 与 LDC 是两个独立项目（2026-11-01 环境主人定夺，工单41），各自面向对应环境达到最优：Windows 侧用 Windows 母语（如 pwsh 侧 fzf 走 PSReadLine 处理器），Linux/WSL 侧用 Linux 母语；不刻意追求形式统一，双仓实现允许各自演化。统一仅在其服务于委托实质处保留最小面：退出码语义 + `LDC_TODO` 机器标记（LDC-0007 契约）。
_Avoid_: 形式统一、原样移植、双仓同款实现（对齐的是目标，不是实现）

**身份文件**:
每台机器本地保存 git user.name/email 的文件（`~/.gitidentity`），bootstrap 首次生成占位、永不入仓库；gitconfig 模板通过 include 引用它。
_Avoid_: git 凭据（指代不同的东西）

**渲染（render）**:
bootstrap 把模板内容拷贝到落点的安装方式（[LDC ADR-0015](https://github.com/yu-cn/ldc/blob/main/docs/adr/0015-copy-render-not-symlink.md)）：覆盖前轮转备份 `.bak`/`.bak.N`、同内容幂等跳过、符号链接残形直接替换不备份；模板仍是唯一声明源。渲染账本（`%LOCALAPPDATA%\wdc\rendered.sha256`）判定漂移方向——纯模板更新免 `.bak` 直接重渲染（LDC ADR-0015 补注）。
_Avoid_: 符号链接安装（旧模型）

**落点内容断言**:
verify/status 的「落点与模板一致」逐项 hash 比对——断效果不断实现（坑11 教训）；取代旧「dotfiles 与 HEAD 一致（防写穿）」断言（LDC ADR-0015 后退役）。
_Avoid_: readlink 断言、防写穿断言（旧模型语义）

**写穿**:
机器侧工具直改落点渲染物（WT / VSCode / gh auth setup-git 等）。渲染拷贝模型下仓库不受污染；落点≠模板即「落点漂移」，triage 负责分流。
_Avoid_: 污染仓库（旧模型语义，已不存在）

**分流（triage）**:
落点漂移的逐文件处置（ADR-0003 判据）：吸收=落点回写模板（显式 pathspec commit，「禁 git add -A」不变）/ 还原=自模板重渲染（丢弃机器改动，不可逆）。触发时机为用户主动（ADR-0009）——漂移非异常，本命令是按需诊断工具而非日常纪律。
_Avoid_: git checkout（旧实现）

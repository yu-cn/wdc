# Agent 协作规矩与已知坑

供任何机器上的 agent 会话遵循。规则属于仓库（机器对等，见 GLOSSARY）：不依赖任何单机的私有记忆。

## 协作规矩

- **一次只问一个问题**，不要批量出题；提问前先把事实查尽（脚本/仓库/日志）。
- **事实自己查，决策交环境主人**：拿不准的不擅自定夺——在 `.scratch/<feature>/issues/` 开工单记录（约定见 issue-tracker.md），由环境主人定夺，任一机器会话可执行。
- **小修直接 commit main**（pre-commit 钩子会跑无副作用校验把关），push 是常态；大改先开工单。
- **打 tag 与发 release 同一会话收口**：push tag 不等于 release 发布（v0.3.0 实录：tag 已推、release 漏建，次日才补发）——打 tag 后同一会话内 `gh release create <tag> --latest --title <名> --notes-file <笔记>` 收口；笔记以 tag 注释的主题句为骨架、按上一版 release 的版式扩写（非 draft、非 prerelease、无附件）。
- **红线**：机器自留地工具（JetBrains/Typora 等）一概不碰（ADR-0003）；`~/.gitidentity` 内容不得出现在任何产出物（校验用「非空」检查，不打印值）；dotfiles 模板提交前 `git status` 核对无漂移（ADR-0015 渲染拷贝后仓库不可能被工具写穿，本项守的是「未提交模板编辑」收口——profile/bashrc 第二路提示同源）。
- **长操作要有心跳**：轮询/后台任务以 30–45 秒级可见进度汇报，勿长时间静默。
- **文档语言**：散文中文；标识符与既定格式保持英文（Status 标签词表、工单行格式如 `Status:`/`Blocked by:`、文件名、命令、代码）。

## 已知坑（真机实录）

1. **wsl.exe 在提权上下文 + PS 管道捕获输出会挂死**（可致 WSL 服务楔死，解法=重启电脑）——根除姿势（工单30，吸收自上游 WindowsDeveloperConfig：其两条流程全程提权运行，含提权下发行版内执行）：安装类命令 `Start-Process` 新控制台、绝不捕获；查询/发行版内执行走临时文件重定向 + 关 stdin + 硬超时杀；只看退出码（输出文本随系统语言变）。仓库内一律经 `scripts/lib/common.ps1` 的 `Wait-WdcProcess`/`Invoke-WslBounded` 调用，勿再写 `& wsl.exe ... 2>&1`。`bootstrap.ps1 -NoElevate` 保留为显式逃生通道。
2. **Git Bash 里调 wsl.exe 传 `/mnt/...` 参数会被 MSYS 路径转换改写**（报 No such file or directory / 127）——加 `MSYS_NO_PATHCONV=1` 前缀。
3. **控制台乱码只是显示问题**（GBK 代码页）——脚本已自设 UTF-8，乱码不影响执行与判断。
4. **winget 退出码语义**：validate 的 1 = 仅警告（良性），负 HRESULT 才是错；`configure test` 漂移判定看「未处于」计数 + 退出码。
5. **`git config --global/--file/--local` 按设计不展开 include**（需 `--includes`），只有全栈查询默认展开——用带作用域查询探测「include 是否生效」会假阴性。
6. **机器侧工具/生成器直改落点（旧「写穿」面，ADR-0015 后仓库不受污染）**：渲染拷贝模型（2026-10-26 落地）下 WT 设置 UI、VSCode、gh auth setup-git、VS 动态 profile 生成器等直改的都是落点渲染物，仓库模板不再可能被写穿——符号链接时代的事故类（工单14/17/24、坑14 注记）与「dotfiles 与 HEAD 一致（防写穿）」断言一并退役。落点 ≠ 模板即「落点漂移」：verify/status 逐项内容比对抓取（单一来源 `Test-DotfileInSync`），处置走 `wdc triage`——吸收=落点回写模板（显式 pathspec commit）/ 还原=自模板重渲染（丢弃机器改动，不可逆），判据 ADR-0003。**主人纠正实录仍适用（2026-10-25）**：动态生成器（VS 2022 Developer 终端对、pwsh source 标注）每次启动重写落点——强制还原=打地鼠且违背「自留地不碰」，必须吸收进模板静态声明（WT 按 source 去重，声明后写穿消失）；**模板跟随机器真相，绝不反向还原**。改模板不再即时生效——须重跑 bootstrap（或 wdc sync）重渲染；改落点的持久偏好走 triage 吸收或自留地。红线「禁 git add -A」不变。历史档案：模板对齐 WT 序列化规范格式（commit 5cb1811）的教训随写穿面一起退役——仓库文件不再被工具整文件重写。
7. **同 ID 多版本并存的 winget 卸载会匹配歧义**（0x8A150014）——`Remove-WingetPackage` 已按逐版本显式卸载处理。补注（2026-10-21，官方码表核实）：0x8A150014 实为 NO_APPLICATIONS_FOUND「找不到包」，匹配歧义对应 0x8A150016 MULTIPLE_APPLICATIONS_FOUND；当日另实证——配置单元引用已从 winget 目录除名的包（Microsoft.CascadiaCode，manifest 404）即报 0x8A150014，处置见 `.scratch/cascadia-font-source/`。
8. **dotfiles 与 `.sh` 的行尾已由 `.gitattributes` 钉 LF**——Windows checkout 的 CRLF 会破坏 WSL 侧 include/bash 执行；新增跨侧文件时记得纳入规则。同族坑：`dotfiles/**` 的文本规则会误伤二进制资产（`ubuntu.ico` 曾被洗损 2 字节）——新增二进制资产记得 `binary` 豁免（现行规则 `*.ico binary`）。
9. **机器派生值（发行版 ID/随机 GUID/本机路径）不入仓库文件**——按 ADR-0004 安装期渲染到机器本地（如 WT fragment）。
10. **先改内容后 `git mv` 会丢内容**——mv 只暂存「改名」，mv 前的工作区编辑留在原地不随提交走（porcelain 显示 `RM`，第二列 M 即此意）；工单 15 归档实录踩中。规矩：要移动的文件先 commit 内容，再 mv 提交改名；或 mv 后核对 porcelain 无第二列残留。
11. **WT 的 fragment 官方读取位置是 `%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\<源名>\`**——包内 `Packages\...\LocalState\fragments` 不被读取（2026-10-21 实录：渲染在包内位置长期不生效，环境主人发现 WT 无 Ubuntu profile 才揭出；改写官方路径后即刻出现）。教训有二：路径照官方文档，别猜「同类就近」；断言尽量断言「效果」而非「中间产物在位」——旧断言只查文件存在，全绿掩盖了不生效。**后续收尾（2026-10-22）**：官方路径上片段机制亦不可靠（短命消失、WSL 自带片段不物化），WDC 的 WSL profile 渲染机制整体退役、改模板静态声明——见 ADR-0006；本坑的路径与断言教训仍然成立。（根治标注 2026-10-26：settings.json 落点已改渲染拷贝——ADR-0015，WT 直改不再触及仓库。）
12. **换镜像同时写两套 apt 源文件会全量重复声明**（2026-10-23 实录：`/etc/apt/sources.list`（legacy 一行式）与 `/etc/apt/sources.list.d/ubuntu.sources`（deb822）并存、指向同一 CERNET 镜像，每次 `apt-get update` 透出一屏 "Target Packages ... is configured multiple times"，`-qq` 压不住 stderr；同内容重复 apt 仅告警不报错，功能无损）——与 WDC 脚本无关（setup-ubuntu.sh 只写 `sources.list.d/github-cli.list` 独立源）。处置：备份后注释老 `sources.list` 活跃行（原文件存 `/root/sources.list.bak-<日期>`），以 deb822 为唯一事实源，`apt-get update` 告警归零收口。规矩：换镜像只写一套、优先 deb822；诊断第一步 `cat` 两文件比对 URL——同一则留 deb822，不同则留实际要用的那个，总之只留一份。

13. **VSCode 自更新会注册 Developer 签名的 identity MSIX**（2026-10-24 实录：LETH 上 VSCode 自更新后出现包名 `Microsoft.VisualStudioCode`、版本 1.0.143.1、SignatureKind=Developer、PackageRootFolder 在安装目录内的 sparse 包——VSCode 拿 Windows 包标识用，非商店第二份，功能版本仍单一）——verify 的「商店 MSIX 已卸」断言与 remove-leftovers 的商店版卸载都按 `SignatureKind -eq 'Store'` 判定；勿按包名一刀切：identity 包卸了会随每次 VSCode 自更新回归，属打地鼠。

14. **升级 Git for Windows 会被「进程占用检查 / 参数转换 / 提权读链接」三道坎连环拦**（2026-10-24 ASUS 实录，全程日志取证）：① agent 会话宿主即 Git Bash（bash.exe 链在调用期间常驻）→ Git 安装器自研 in-use 检查发现 bash 即中止，静默模式下提示框被压成默认 Cancel；`/FORCECLOSEAPPLICATIONS` 是 Inno 内建开关、对 Git 自研检查无效（开关完整送达仍 Cancel，安装器日志实证）。可行姿势=计划任务（`schtasks /SC ONCE`，脱离会话进程树——Start-Process 分离的后台进程活不过工具调用回收）+ 任务脚本内轮询「bash/sh 清零且连续 3 个 5 秒采样静默」再发起 winget；发起后 agent 会话须停手让静默达成，UAC 弹窗交用户。② 经 Git Bash 传 `--custom '/FORCECLOSEAPPLICATIONS'` 会被 MSYS 路径转换改写成 `C:/Program Files/Git/FORCECLOSEAPPLICATIONS`（坑②同族，安装器命令行日志实证）——整条命令包进 pwsh 单引号字符串内层可绕，或 `MSYS_NO_PATHCONV=1` 前缀。③ 提权安装器跑 `git config --system` 前会读 `~/.gitconfig`（符号链接）报 Invalid argument → system config 写入逐条弹错、旧 `etc/gitconfig` 被清；恢复=提权**直接写文件**（Set-Content 写回 Git for Windows 默认 11 项，不调 git 即绕开符号链接读取）。注意 2.56 起 `mingw64` 目录整体迁名 `ucrt64`——恢复时 `http.sslcainfo` 必须指向 `ucrt64/etc/ssl/certs/ca-bundle.crt`，照旧版默认抄 mingw64 路径会让 push/clone 全挂 "error adding trust anchors"（ASUS 二次实证）。gh 无此三道坎，winget 直升即可。附注：本次 schtasks 路径 `--silent` 仍弹了交互向导（成因未查），报错弹窗点 OK 放行不碍文件安装。

15. **仓库缺席 → 系统配置全量死链失联**（2026-10-25 实录：临时删除 WDC 本地仓库，dotfiles-map 的 7 个落点全变死链——git 每条命令 fatal（读不到全局配置）、WT settings.json 失效丢全部 profile，bashrc/pwsh profile/VSCode×2/starship 静默降级；`~/.gitidentity` 刻意不入仓库故幸存）——链接进仓库是 ADR-0002 第三层的设计本意，失效面只在仓库缺席窗口；install-dotfiles.ps1 的死链清理只覆盖搬移/改名后的重装自愈，不覆盖缺席期。处置（2026-10-25 定夺：仅文档化，机制不动；LETH 同日二发复发，恢复步骤已真机验证）：① `cat ~/.wdc` 读回原仓库路径（指针文件在 $HOME，不受删库影响）→ ② `rm -f ~/.gitconfig` 清死链（先 `ls -l` 确认是链接；**死链在位时 git 一切命令 fatal、含 clone 本身，实测 exit 128——不清链连 clone 都跑不了**，此刻全局配置退回裸默认）→ ③ clone 回原路径（凭据在 Windows 凭据管理器不受影响；同路径则其余六链即刻复活）→ ④ 提权重跑 install-dotfiles.ps1 重建 .gitconfig 链（其余项报 OK）→ ⑤ verify-machine.ps1 + git status 验收。补注（同日二次定夺）：setup-ubuntu.sh 的 ensure_ldc 已加死链预清（clone 前检测 `~/.gitconfig` 死链则清，真文件不动）——官方重装路径（install-wsl-env.ps1）可自愈，上面手动配方保留为兜底；LDC 侧同构缺陷已对等补录进 LDC AGENTS.md「已知坑」。备选已评估并否决：`~/.gitconfig` 改 include 包装可让 git 在仓库缺席时静默降级（实测 include 指缺失文件不报错、指存在文件正常展开），代价 = 机器侧 `git config --global` 增量写入落 $HOME 包装、逃出「dotfiles 与 HEAD 一致」漂移断言、双机增量同步断；WT 单文件读取无 include 机制，仓库缺席时必然失联——缺席场景若高频发生再重估。**根治标注（2026-10-26，ADR-0015）**：落点已改渲染拷贝——仓库缺席不再产生死链（落点为实体文件，运行面不再依赖仓库在位）；本坑降级为历史档案，上述恢复配方保留备查。

16. **raw 服务器按原样返回 UTF-8 BOM，`irm | iex` 一行命令会被 BOM 前缀绊倒**（2026-10-26 实录：`powershell -c "irm <url> | iex"` 报「意外的属性 CmdletBinding」——irm 按 charset 解码正确但不剥 BOM，返回串开头带 `\uFEFF`；5.1 解析器对带 BOM 前缀的字符串会把首部 `[CmdletBinding()]`/`param()` 判非法，管道/参数/scriptblock Create 三形态全挂且报错逐字一致；文件执行不受影响（读文件时剥 BOM），远端与本地内容仅行尾差异非版本漂移）——处置：get.ps1 删除零参数装饰性的 `[CmdletBinding()]`+`param()`（头部约束注明不可加回），文档一行命令原样可用；此类脚本的通用替代命令是 `irm <url> -OutFile <临时文件>` 后 `&` 执行（需 `-ExecutionPolicy Bypass`——裸机默认 Restricted 拦文件执行而 iex 不受限，两形态真实差异）。规矩：凡要走 `irm | iex` 的脚本头部不得带 attribute/param；文件本体 BOM 必须保留（5.1 裸读无 BOM 中文文件按 GBK 乱码）。

- **禁 `git add -A`**：永远按显式路径 add——triage 吸收走显式 pathspec commit；全量 add 会把非目标改动无声带进 commit，提交前 `git status` 核对。

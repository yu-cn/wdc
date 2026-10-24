# Agent 协作规矩与已知坑

供任何机器上的 agent 会话遵循。规则属于仓库（机器对等，见 GLOSSARY）：不依赖任何单机的私有记忆。

## 协作规矩

- **一次只问一个问题**，不要批量出题；提问前先把事实查尽（脚本/仓库/日志）。
- **事实自己查，决策交环境主人**：拿不准的不擅自定夺——在 `.scratch/<feature>/issues/` 开工单记录（约定见 issue-tracker.md），由环境主人定夺，任一机器会话可执行。
- **小修直接 commit main**（pre-commit 钩子会跑无副作用校验把关），push 是常态；大改先开工单。
- **打 tag 与发 release 同一会话收口**：push tag 不等于 release 发布（v0.3.0 实录：tag 已推、release 漏建，次日才补发）——打 tag 后同一会话内 `gh release create <tag> --latest --title <名> --notes-file <笔记>` 收口；笔记以 tag 注释的主题句为骨架、按上一版 release 的版式扩写（非 draft、非 prerelease、无附件）。
- **红线**：机器自留地工具（JetBrains/Typora 等）一概不碰（ADR-0003）；`~/.gitidentity` 内容不得出现在任何产出物（校验用「非空」检查，不打印值）；dotfiles 提交前 `git status` 核对无漂移（写穿污染见下）。
- **长操作要有心跳**：轮询/后台任务以 30–45 秒级可见进度汇报，勿长时间静默。
- **文档语言**：散文中文；标识符与既定格式保持英文（Status 标签词表、工单行格式如 `Status:`/`Blocked by:`、文件名、命令、代码）。

## 已知坑（真机实录）

1. **wsl.exe 在提权上下文 + PS 管道捕获输出会挂死**（可致 WSL 服务楔死，解法=重启电脑）——根除姿势（工单30，吸收自上游 WindowsDeveloperConfig：其两条流程全程提权运行，含提权下发行版内执行）：安装类命令 `Start-Process` 新控制台、绝不捕获；查询/发行版内执行走临时文件重定向 + 关 stdin + 硬超时杀；只看退出码（输出文本随系统语言变）。仓库内一律经 `scripts/lib/common.ps1` 的 `Wait-WdcProcess`/`Invoke-WslBounded` 调用，勿再写 `& wsl.exe ... 2>&1`。`bootstrap.ps1 -NoElevate` 保留为显式逃生通道。
2. **Git Bash 里调 wsl.exe 传 `/mnt/...` 参数会被 MSYS 路径转换改写**（报 No such file or directory / 127）——加 `MSYS_NO_PATHCONV=1` 前缀。
3. **控制台乱码只是显示问题**（GBK 代码页）——脚本已自设 UTF-8，乱码不影响执行与判断。
4. **winget 退出码语义**：validate 的 1 = 仅警告（良性），负 HRESULT 才是错；`configure test` 漂移判定看「未处于」计数 + 退出码。
5. **`git config --global/--file/--local` 按设计不展开 include**（需 `--includes`），只有全栈查询默认展开——用带作用域查询探测「include 是否生效」会假阴性。
6. **被符号链接的 settings.json 会被 UI 写穿**：Windows Terminal 设置 UI 保存、VSCode 的 innocuous 操作（如打开 .md 时选编辑器）都会把状态重写进仓库文件——改这类设置改仓库模板；写穿由 verify 的「dotfiles 与 HEAD 一致」断言兜底暴露，处置=还原机器噪声 / 吸收点名偏好（ADR-0003 判据）。
7. **同 ID 多版本并存的 winget 卸载会匹配歧义**（0x8A150014）——`Remove-WingetPackage` 已按逐版本显式卸载处理。补注（2026-10-21，官方码表核实）：0x8A150014 实为 NO_APPLICATIONS_FOUND「找不到包」，匹配歧义对应 0x8A150016 MULTIPLE_APPLICATIONS_FOUND；当日另实证——配置单元引用已从 winget 目录除名的包（Microsoft.CascadiaCode，manifest 404）即报 0x8A150014，处置见 `.scratch/cascadia-font-source/`。
8. **dotfiles 与 `.sh` 的行尾已由 `.gitattributes` 钉 LF**——Windows checkout 的 CRLF 会破坏 WSL 侧 include/bash 执行；新增跨侧文件时记得纳入规则。同族坑：`dotfiles/**` 的文本规则会误伤二进制资产（`ubuntu.ico` 曾被洗损 2 字节）——新增二进制资产记得 `binary` 豁免（现行规则 `*.ico binary`）。
9. **机器派生值（发行版 ID/随机 GUID/本机路径）不入仓库文件**——按 ADR-0004 安装期渲染到机器本地（如 WT fragment）。
10. **先改内容后 `git mv` 会丢内容**——mv 只暂存「改名」，mv 前的工作区编辑留在原地不随提交走（porcelain 显示 `RM`，第二列 M 即此意）；工单 15 归档实录踩中。规矩：要移动的文件先 commit 内容，再 mv 提交改名；或 mv 后核对 porcelain 无第二列残留。
11. **WT 的 fragment 官方读取位置是 `%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\<源名>\`**——包内 `Packages\...\LocalState\fragments` 不被读取（2026-10-21 实录：渲染在包内位置长期不生效，环境主人发现 WT 无 Ubuntu profile 才揭出；改写官方路径后即刻出现）。教训有二：路径照官方文档，别猜「同类就近」；断言尽量断言「效果」而非「中间产物在位」——旧断言只查文件存在，全绿掩盖了不生效。**后续收尾（2026-10-22）**：官方路径上片段机制亦不可靠（短命消失、WSL 自带片段不物化），WDC 的 WSL profile 渲染机制整体退役、改模板静态声明——见 ADR-0006；本坑的路径与断言教训仍然成立。
12. **换镜像同时写两套 apt 源文件会全量重复声明**（2026-10-23 实录：`/etc/apt/sources.list`（legacy 一行式）与 `/etc/apt/sources.list.d/ubuntu.sources`（deb822）并存、指向同一 CERNET 镜像，每次 `apt-get update` 透出一屏 "Target Packages ... is configured multiple times"，`-qq` 压不住 stderr；同内容重复 apt 仅告警不报错，功能无损）——与 WDC 脚本无关（setup-ubuntu.sh 只写 `sources.list.d/github-cli.list` 独立源）。处置：备份后注释老 `sources.list` 活跃行（原文件存 `/root/sources.list.bak-<日期>`），以 deb822 为唯一事实源，`apt-get update` 告警归零收口。规矩：换镜像只写一套、优先 deb822；诊断第一步 `cat` 两文件比对 URL——同一则留 deb822，不同则留实际要用的那个，总之只留一份。

13. **VSCode 自更新会注册 Developer 签名的 identity MSIX**（2026-10-24 实录：LETH 上 VSCode 自更新后出现包名 `Microsoft.VisualStudioCode`、版本 1.0.143.1、SignatureKind=Developer、PackageRootFolder 在安装目录内的 sparse 包——VSCode 拿 Windows 包标识用，非商店第二份，功能版本仍单一）——verify 的「商店 MSIX 已卸」断言与 remove-leftovers 的商店版卸载都按 `SignatureKind -eq 'Store'` 判定；勿按包名一刀切：identity 包卸了会随每次 VSCode 自更新回归，属打地鼠。

- **禁 `git add -A`**：符号链接在位后，全量 add 会把写穿漂移无声带进 commit——永远按显式路径 add，提交前 `git status` 核对 dotfiles/ 无漂移。

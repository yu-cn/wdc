# 32: WSL 阶段委托 LDC（ADR-0007 统筹落地）

**What to build:** 姊妹仓库 [LDC](https://github.com/yu-cn/ldc)（v0.1.0+ 已发布，双架构 CI 冒烟全绿）已把「Ubuntu/Debian 机器**内部**的收敛」做成单一实现。本工单把 WDC 的 WSL 阶段从「setup-ubuntu.sh 双角色自实现」退位为「WSL 生命周期管理 + 委托 LDC」，消灭双实现漂移——vp 钉子与 `dotfiles/wsl/`（bashrc/gitconfig）与 LDC 的 `dotfiles/linux/` 已是两份近似拷贝，属并行演进的漂移源。职责边界与委托契约的完整决策记录见 [LDC ADR-0007](https://github.com/yu-cn/ldc/blob/main/docs/adr/0007-wdc-ldc-coordination.md)：WDC 保留 Windows 侧全部 + WSL 生命周期（启用 WSL、装发行版、wsl.conf systemd、默认用户）；发行版内部一切（包/语言栈/dotfiles/验收）走 LDC。LDC 侧已就绪的接口事实：`install-packages.sh` 可 EUID=0 内联跑（`wsl -u root` 直调）；`bootstrap.sh` 对已完成 root 阶段的机器自动核销跳过；接管外来符号链接（本仓库现行 dotfiles/wsl 链接）时会兜底创建 `.bashrc.local`/`.gitconfig.local` 自留地；无 GNOME 会话桌面域自动 SKIP；无 systemd 的发行版传 `LDC_SKIP_DOCKER=1`；验收 `verify-machine.sh --quick` 已容器化双架构实证。

**Blocked by:** None（LDC 已发布 github.com/yu-cn/ldc，前置满足）

**Status:** done

- [x] `scripts/wsl/setup-ubuntu.sh` → 薄委托：WSL 内定位/clone LDC 到 `~/dev/ldc`（已存在则 fetch + `pull --ff-only`，分叉中止交人工——与 `ldc sync` 仓库步同语义）→ root 段改 `wsl -d Ubuntu -u root -e bash ~/dev/ldc/scripts/install-packages.sh` → user 段改 `wsl -d Ubuntu -e bash ~/dev/ldc/bootstrap.sh`（身份带过逻辑保留——LDC 对已存在的 `.gitidentity` 不覆盖）
- [x] `dotfiles/wsl/` 冻结：README 注明「由 LDC dotfiles/linux 接管」，一个过渡版本后删除；机器迁移由 LDC 接管时替换旧链接实现
- [x] `scripts/verify-machine.ps1` 第 5/6 组 WSL 断言改委托 LDC verify；保留 WSL 特有项（默认 shell=bash、systemd 开启）
- [x] `configs/vp-version` 两仓库同值联动：升级同日双改、各自账本互引记账（本单实施时确认两仓同值 1.3.0，升级规矩见两仓 AGENTS.md / ADR-0007）
- [x] WDC 特有 opinion（移除清单 Go 等）保留在委托包装层 pre/post 钩子，不进 LDC
- [x] 迁移验收：既有 WSL 机器重跑 bootstrap 后 dotfiles 落点全部指向 LDC 仓库、`ldc status` 全绿、WDC verify（含委托段）全绿

## Comments

- 2026-10-24（DGX 会话）：本工单规格自 LDC 仓库 `.scratch/dev-env/03-wdc-wsl-delegation.md` 同步（该文件保留为 LDC 侧镜像）。跨仓库统筹规则（Linux 模板主作者位归 LDC、钉子同值、改 LDC 阶段脚本入口契约前先想 WDC 调用方）见 LDC 仓库 AGENTS.md「姊妹仓库 WDC 统筹」节。
- 2026-10-24（DGX 会话）：LDC 侧实测给本工单的提示——Chrome 安装后脚本会接管 apt 源（换 deb822 `.sources` 并清外来 `.list`），LDC 的 `add_vendor_repo` 已按厂商源 URL 标记判重；WDC 侧若在包装层动 apt 源，注意与本仓已知坑12 同款的双文件重复声明问题。
- 2026-10-24（LETH 会话，实施收口）：委托落地——`setup-ubuntu.sh` 双角色入口保留，内部全换委托：root 角色 apt 引导依赖（git/curl/ca-certificates/gnupg）→ 经 `su -l` 以默认用户身份定 LDC（clone 落用户 home、owner 正确）→ wsl.conf systemd（WDC 保留职责）→ 委托 `install-packages.sh` → WDC opinion post 钩子（移除 Go、chsh bash、docker 组——LDC 的 usermod 依赖 SUDO_USER，root 直调无此变量）；user 角色身份带过 → 定 LDC → 委托 `bootstrap.sh`。无 systemd 中间态（wsl.conf 刚写入未重启）两侧同判定透传 `LDC_SKIP_DOCKER=1`。bootstrap 退出码 2（有待办）按明细行解析：仅桌面域待办视为 WSL 预期消化为完成，root 交接/git 身份待办如实 FAIL。verify 新增 `scripts/wsl/verify-ldc.sh` 委托包装（`verify-machine.sh --quick` 退出码透传 + 同款 LDC_SKIP_DOCKER 判定）；probe.sh 精简为 WSL 特有两键（shell/systemd），docker/uv/node/links/id 断言全数移交 LDC verify。
- 2026-10-24（LETH 会话）：LDC 侧随迁修正（LDC commit 438f77c）——迁移验收时发现本机 WSLg 使 `have gsettings` 为真，LDC 桌面应用域误激活：code/chrome 装进 WSL、扩展 CLI 全数失败。裁定：**WSL 不装 Linux 桌面软件，即便有 WSLg**（GUI 由 Windows 侧承载）——LDC 门禁收紧为 `desktop_stack_present()`（gsettings 且非 WSL 内核，common.sh 单一来源），安装/断言/apply-desktop/root 完成度四处同口径，ADR-0008 补记。本次误装的 code/chrome 及厂商源/keyring/`~/.config/Code` 链接已清理还原。
- 2026-10-24（LETH 会话）：迁移验收实录——重跑 install-wsl-env：root 委托已核销、user 工具全幂等 SKIP（uv/vp/starship/lazygit=钉子）、桌面域 SKIP、dotfiles 接管（`.bashrc`/`.gitconfig` 链接由 /mnt/d 的 WDC 仓库重指 `~/dev/ldc`，`.bashrc.local`/`.gitconfig.local` 兜底创建，hooksPath 接线）；`ldc status` 全绿；WDC verify（含委托段）全绿。包装层实录两 bug：rev-list 输出 TAB 分隔用 `%% *` 切不开（`[: integer expected]`，改 `read -r`）；待办解析裸标签「· root 阶段」误伤 phase 标题 `=== 3/7 · root 阶段 ===`（改「标签：关键词」形态）。

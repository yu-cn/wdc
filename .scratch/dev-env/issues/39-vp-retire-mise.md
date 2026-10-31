# 39: 语言管理器换轨 WDC 面——vp 退役、mise 升正（联动 LDC ADR-0016/0017、工单10）

**What to build:** 2026-10-31 主人定夺语言面换轨（LDC [ADR-0016](https://github.com/yu-cn/ldc/blob/main/docs/adr/0016-vp-retire-mise-takeover.md)：fss 硬前置 mise 与两仓声明的 vp 双轨错位，本机 mise 已 winget 手装未声明；主人确认 vp 仅作 Node 管理器用）。WDC 面落点——① `configs/cli-tools.winget` 声明 mise（useLatest 免钉）、头注释 vp 措辞退役；② `scripts/install-languages.ps1` 重写：vp 安装 / env default lts / env on 全退役，改确保 `mise use -g node@lts`；③ `scripts/lib/common.ps1` 的 Get-VpPin / Get-VpWinExe 等 vp 助手退役；④ `verify-machine.ps1` / `inventory-machine.ps1` / `install-wsl-env.ps1` / `bootstrap-main.ps1` 的 vp 面换 mise 断言与编排；⑤ `dotfiles/windows/pwsh-profile.ps1` 的 `%APPDATA%\vite-plus\env.ps1` source 换 mise activate；⑥ `configs/vp-version` 删除、`.gitattributes` 相应行核对；⑦ `configs/vscode-extensions.txt` 去 `voidzero.vite-plus-extension-pack`；⑧ `remove-leftovers.ps1` 增 vp 卸载（vp→mise 属「迁移冲突」通道，ADR-0007 宪章内）；⑨ dev-standard 同步拷贝：§1 WDC 词表去 vp、§6 钉子同值标注「当前无实例」（LDC 主笔先行）；⑩ README 5 处措辞、demo 重录、CHANGELOG 记账；⑪ fresh-machine 冒烟已知噪声面复核（vp 相关行消失后的幂等基线更新）。双仓同号 v0.9.0（破坏性 MINOR）与 LDC 同日发版。

**Blocked by:** None

**Status:** todo

- [ ] ① cli-tools.winget：mise 声明 + 头注释退役
- [ ] ② install-languages.ps1 重写（mise + node@lts 默认）
- [ ] ③ lib/common.ps1 vp 助手退役
- [ ] ④ verify / inventory / install-wsl-env / bootstrap-main 换面
- [ ] ⑤ pwsh-profile.ps1 换 mise activate
- [ ] ⑥ vp-version 删除 + .gitattributes 核对
- [ ] ⑦ VSCode 清单去 vite-plus 扩展包
- [ ] ⑧ remove-leftovers 增 vp 卸载（迁移冲突通道）
- [ ] ⑨ dev-standard 拷贝同步（词表去 vp、§6 标注无实例）
- [ ] ⑩ README / demo 重录 / CHANGELOG
- [ ] ⑪ 冒烟幂等基线复核
- [ ] 真机验收（ASUS：bootstrap 重跑收敛、vp 消失、mise+node@lts 就位、fss 前置 `mise --version` 通过）+ CI 绿 + v0.9.0 同日发版（联动 LDC 工单10）

## Comments

- 2026-10-31（ASUS 会话，开工）：联动 LDC ADR-0016/0017 与工单10 同日提交；两 ADR 落纸见 LDC 仓。
- 2026-10-31（ASUS 会话，真机验收实录）：install-languages 实跑 OK（mise use -g node@lts——Windows 侧复用 fss 已装 node 24.14.0，零下载；WSL 侧同命令解析 26.13.0，两侧各自满足 lts 语义）；install-dotfiles 重渲染 pwsh profile + Git Bash bashrc（漂移双信号即清）；remove-leftovers 实跑——用户 PATH 清 2 条 vite-plus 注入，`~/.vite-plus` 目录**占用未删（FAIL 如实报告，幂等收尾）**：占用者是 ZCode 上下文插件（`zcode-context/0.3.10/dist/server.mjs` 经 vp node shim 运行，6 进程）——不能杀，待 ZCode 重启后任一次 bootstrap 自动收尾；已为该形态补 try/catch 优雅降级（占用不炸阶段，PATH 清理照走）。verify -Quick 全绿（含经委托的 LDC 侧新断言：mise=钉子 2026.10.25 / uv=钉子 0.13.6）。发现 vp 第三种布局变体 `~/.vite-plus\<版本>\`（版本化子目录，删根目录即覆盖）。待办：⑩ demo 重录（agg 不在本机，发版腿）、⑪ 冒烟基线复核、CI 锚点、v0.9.0 与 LDC 同日发版。
- 2026-10-31（ASUS 会话，CI 锚点）：实现提交 6578fef push 后 validate 绿 run 41208294073；fresh-machine 冒烟已触发 run 41208406792（结论收口时回填；重点观察面：新装机 mise winget 首装 + node@lts 全新解析 + 幂等重跑腿基线）。

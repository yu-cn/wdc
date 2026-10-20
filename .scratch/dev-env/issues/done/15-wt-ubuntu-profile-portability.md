# 15: WT 模板 Ubuntu 条目依赖动态源 GUID，跨机变孤儿被静默丢弃

**What to build:** `dotfiles/windows/terminal-settings.json` 的 Ubuntu 条目原为 `source: "Microsoft.WSL"` + GUID 的「动态源覆盖」形态。新版 WSL 生成器的 profile GUID 由**发行版注册 ID 派生**（每机随机），主机的 GUID 在第二台机上对不上号 → 条目成为孤儿、WT 静默丢弃 → Ubuntu profile 消失（第二台机实测）。纯静态写法才是可移植形态。

**Blocked by:** None (can start immediately)

**Status:** ready-for-human

- [x] 修复：条目改为无 source 纯静态（`wsl.exe -d Ubuntu`，两机发行版同名；GUID 保留模板原值以不动主机侧行为），`startingDirectory: ~`
- [x] 其余机器复验：拉取后重跑 bootstrap，确认 Ubuntu profile 由 fragment 正常供给（模板已无 WSL 条目，各机自适应渲染）（2026-10-20 主机复验通过，见 Comments）

## Comments

- 2026-10-20（第二台机会话）：环境主人发现 Ubuntu profile 消失。取证：原配置 `.bak` 里是静态条目 `WSL Ubuntu`（`wsl.exe --distribution-id {a2b0a3e7-…}` + 本机 icon 路径，同样不可移植但可用）；state.json 的 generatedProfiles 含派生 GUID，坐实「GUID 随发行版注册 ID 变化」。

- 2026-10-20（第二台机会话）：附带记录——环境主人原 Ubuntu profile 的个人化（colorScheme "Ubuntu"、Ubuntu Mono 13、发行版 shortcut.ico）被模板默认值（Catppuccin Mocha + Cascadia Mono NF）接管，原样保留在 `LocalState/settings.json.bak`。是否吸收进核心由主人按 ADR-0003 定夺（点名=进核心，沉默=自留地，可用 profile 级 override 恢复个人化）。

- 2026-10-20（第二台机会话）：方案升格为 ADR-0004（环境主人原则：「配置不应写死路径/名称，需按机器环境适配」）。模板移除全部 WSL 条目（只存通用内容）；新增 scripts/install-wt-profiles.ps1 在安装期枚举本机发行版、渲染机器本地 fragment（名称/ID/图标全按本机派生，GUID 名字哈希稳定）；install-dotfiles 挂为 3/4 步；verify 增 fragment 断言。同日第二次写穿实录：WT 设置 UI 保存会把全量状态（含 `--distribution-id`、`C:\Users\...` 图标路径）重写进被链接的 settings.json——UI 编辑属违规操作，漂移断言把关。

- 2026-10-20（主机会话）：主机复验通过——bootstrap 后 `Dotfiles 3/4` 报「fragment 已渲染（发行版：Ubuntu）」，verify-machine 全量断言全绿（含「WT WSL fragment 已渲染」）。两机均已走 fragment 供给，工单收口。

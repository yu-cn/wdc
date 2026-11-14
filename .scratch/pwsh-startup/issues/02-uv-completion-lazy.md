# 工单02：uv 补全惰性加载

Status: ready-for-agent

## 背景

`uv generate-shell-completion powershell` 产物 **766KB**，spawn + 求值 ~670ms（求值 444ms），而多数会话根本不用 uv——每开一个终端固定付这笔税，是 profile 第三大单项。依赖工单01 先落地（同批测量基线），但机制独立、可单独收口。

**Blocked by:** 01（仅基线先后，非机制依赖）

## 内容

- **方案 A（推荐）**：pwsh profile 里 `Register-ArgumentCompleter -CommandName uv` 薄壳——首次对 uv 按 Tab 时才 spawn + 求值真补全脚本，机制：
  - 保留现行 `Get-Command uv` 存在性守卫：uv 缺席不注册薄壳
  - 薄壳内首次触发时 IEX 完整补全脚本（IEX 过程中原生 completer 即注册）；**置位标志**（如 `$script:__uvCompletionLoaded`）后薄壳恒返回空——同命令多 completer 叠加执行，薄壳让路避免双份候选
  - 首 Tab 即有结果：薄壳触发加载的同一轮，已注册的原生 completer 会接着跑并出候选
- **方案 B（fallback）**：uv 也走工单01 缓存 dot-source——但 766KB 解析 ~400ms 仍是大头，仅省 spawn ~230ms，收益小；A 失败（补全框架不配合）再退 B
- 渲染拷贝模型（坑6）：改模板不即时生效——收口后须重渲染真机验证

## 验收清单

- [ ] `uv <Tab>` 子命令补全正常（含首 Tab），候选无双份
- [ ] 非 uv 会话零生成成本：新开终端无 uv 进程 spawn（对照分步基准）
- [ ] uv 缺席机器不注册薄壳、开终端无报错
- [ ] 分步基准前后对比留档 Comments（预期在工单01 之上再省 ~650ms）
- [ ] validate 全绿 + 落点重渲染后真机验证

## 实录

- 2026-11-14（ASUS 会话，开单）：诊断数据见 [../spec.md](../spec.md)。

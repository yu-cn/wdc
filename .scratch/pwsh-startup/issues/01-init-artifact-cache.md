# 工单01：starship / gh / zoxide init 产物 bootstrap 缓存

Status: ready-for-agent

## 背景

profile 每次开终端对三份静态产物重复 spawn + 求值（spec.md 诊断在案）：starship **双层 spawn**（init 产物是 117 字节壳，内嵌再 spawn `--print-full-init`）~700-820ms；gh spawn ~200ms（求值仅 17ms）；zoxide ~110ms。合计 ~1s，热态可省大头。

## 内容

- **生成时机与落位**：bootstrap 渲染侧（install-dotfiles.ps1 与 `wdc sync` 共用路径；建议 scripts/lib 独立函数供两处调用）——工具在场（`Get-Command` 守卫）时生成三份缓存到 `%LOCALAPPDATA%\wdc\cache\`：
  - `starship init powershell --print-full-init` → `starship-init.ps1`（单层直取，绕双层 spawn）
  - `gh completion -s powershell` → `gh-completion.ps1`
  - `zoxide init powershell` → `zoxide-init.ps1`
- **目录先例**：与 `Get-WdcRenderStateFile` 的 `%LOCALAPPDATA%\wdc\` 同区（ADR-0004 机器本地派生值不入仓库——缓存不是落点，**不入 dotfiles map、不参与漂移比对**）
- **profile 模板三处改**（dotfiles/windows/pwsh-profile.ps1）：缓存在 → dot-source；缺失 → 现行 spawn 写法原样回退。存在性守卫原则不变——未 bootstrap 的新机器开终端零报错
- **失效策略**：每次 bootstrap / sync 重渲染时重新生成（工具升级后重跑即刷新）；profile 内**不做版本校验**（校验即 spawn，抵消收益）。风险注记：工具升级未重渲染期间缓存滞后一版（补全/提示符可能缺新命令），可接受、重跑收口
- **编码**：产物是工具英文输出，纯 ASCII 写盘即可；生成器函数含中文注释按仓库脚本惯例（坑16：含中文须 BOM）
- **渲染拷贝模型**（坑6）：改模板不即时生效——收口后须重跑 bootstrap（或 sync）重渲染并真机验证

## 验收清单

- [ ] bootstrap / `wdc sync` 渲染时生成三份缓存（工具在场时）；工具缺席机器跳过不报错
- [ ] profile 三处守卫：缓存命中 dot-source、缺失回退现行 spawn；删缓存目录后重开终端回退无报错
- [ ] 真机重渲染后 WT 新开 pwsh 功能回归：starship 提示符正常、`z` 跳目录正常、gh Tab 补全正常
- [ ] 分步基准前后对比留档 Comments（spec.md 测量方法；预期热态全量省 ~0.8-1s）
- [ ] validate 全绿 + 落点重渲染后真机验证

## 实录

- 2026-11-14（ASUS 会话，开单）：诊断数据见 [../spec.md](../spec.md)。首 Tab 验证姿势参考 cli-ux 工单05 实录（`TabExpansion2` 离线探测）。

# 工单01：starship / gh / zoxide init 产物 bootstrap 缓存

Status: done

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

- [x] bootstrap / `wdc sync` 渲染时生成三份缓存（工具在场时）；工具缺席机器跳过不报错（真机渲染三份 CHANGED 在案；缺席分支剥 PATH 实测全 SKIP 零产物零报错）
- [x] profile 三处守卫：缓存命中 dot-source、缺失回退现行 spawn；删缓存目录后重开终端回退无报错（移走缓存目录实测 exit 0）
- [x] 真机重渲染后 WT 新开 pwsh 功能回归：starship 提示符正常、`z` 跳目录正常、gh Tab 补全正常（TabExpansion2 离线探测，cli-ux 工单05 同法）
- [x] 分步基准前后对比留档 Comments（spec.md 测量方法；热态全量省 ~0.8-1s，同窗口 A/B 见实录）
- [x] validate 全绿 + 落点重渲染后真机验证

## 实录

- 2026-11-14（ASUS 会话，开单）：诊断数据见 [../../spec.md](../../spec.md)。首 Tab 验证姿势参考 cli-ux 工单05 实录（`TabExpansion2` 离线探测）。
- 2026-11-14（ASUS 会话，执行收口）：实现 commit 350a0ee——lib `scripts/lib/pwsh-init-cache.ps1`（纯函数不依赖 common.ps1，报告归调用方）+ install-dotfiles.ps1 接线（.wdc 指针块后）+ profile 模板三处守卫 + `__wdcInitCachePath` 命中器用后即清。真机重渲染（install-dotfiles.ps1 直跑）：template-update 方向直接覆盖无 .bak 噪声，三份缓存生成（starship 10,648B / gh 10,978B / zoxide 4,444B，Parser 零错）。
  - **幂等教训两发**：`Set-Content` 落盘追加行尾——字符串哈希比对与读回原文比对双双失配（二轮全 CHANGED）；终局 `[IO.File]::WriteAllText`（utf8NoBOM、不追加行尾）+ 读回严格比对，二轮全 OK
  - **功能回归**（缓存命中路径）：prompt 函数在位、`__zoxide_z` 在位、gh 候选 18、`prompt()` 调用无异常；init 机件（`__wdcInitCachePath`/`$__init`）用后即清不落会话
  - **profile 点注稳态同法对照**（三次点注去首次 PSReadLine 导入噪声）：改造前 3147/5299/2994ms → 改造后 809/714ms
  - **同窗口 A/B**（只切缓存在否，规避机器负载噪声——spec 已记墙钟 1.8↔6.7s 摆动）：回退态 7.0/7.2s vs 命中态 3.9-5.8s，省 ~1.2-3.2s
  - **测试伪影注记**：同一会话二次点注 profile 时第 6 行 mise 报 `& $miseCmd.Source` 无效——activate 产物定义了 `mise` 函数包装，`Get-Command mise` 二次解析到函数致 `.Source` 为空；真实开窗首启无此态，mise 行 spec 明确不动，留档防复现时误判
  - validate 全绿（`pwsh-init-cache.ps1` 经 validate 动态扫描自动纳入 PSSA 面）

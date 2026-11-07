# 工单07：cli-parity 契约挂 dev-standard-guard + validate 断言

Status: done

## 背景

双仓 CLI 体验对齐今天靠人肉对账（子命令表/退出码/-h 语义/补全口径），漂移无机械守护。
dev-standard-guard 已有双仓同源文件周检机制（curl 姊妹仓归一比对）——契约文件挂进同一循环，
零新流程。主作者位 LDC（同 dev-standard 模式）。

Blocked by: LDC cli-ux-batch 工单06（契约文件先在 LDC 落地）

## 内容

- 拷贝 LDC 的 `docs/cli-parity.md`（含机器可读注释行 `<!-- wdc-commands: … -->` /
  `<!-- ldc-commands: … -->`）到本仓，同批同内容
- dev-standard-guard.yml 的同源比对循环加 `docs/cli-parity.md`
- validate.ps1 加一档断言：解析 wdc.ps1 的 `$wdcCommands` 行 vs 契约注释行——不一致 FAIL
  （把「改实现忘改契约」从周检提前到提交时）

## 验收清单

- [ ] guard workflow 本地等价演练：两仓文件 diff 为空
- [ ] validate 断言：临时删一个命令词 → FAIL；还原 → OK
- [ ] validate 全绿

## 实录

- 拷贝自 LDC d4eb5fc，diff 归零验证（tr -d CR 双侧）；guard 循环纳入；validate 断言负测实录（删 sync 词 FAIL、还原 RC=0 全绿）；$wdcCommands 词序对齐契约（严格比对即序敏感，工单内定夺）；validate 全绿（afa0ba1）

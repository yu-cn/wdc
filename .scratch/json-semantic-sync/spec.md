# spec · JSON 落点语义比对

## 问题

渲染拷贝模型（ADR-0015）下落点漂移按字节判定（`Test-DotfileInSync` 单一来源，六方共读）。VSCode 设置 UI 触碰任意一项即把该键重排到文件尾——**键序差异、内容零差异**也判 drift（2026-11-14 LETH 实录：`window.autoDetectColorScheme` 值未变、纯位置移动，两文件同字节数）。这类假漂移：吸收=固化无语义的键序进模板，还原=下回 UI 触碰复发，两头都是打地鼠。

## 定夺

主人 2026-11-14 同意改语义比对（本会话提出，逐字节 diff 取证后拍板）。

## 方案

`Test-DotfileInSync`（scripts/lib/dotfiles-map.ps1，保持自包含无依赖）字节不符且 Source 为 `*.json` 时，追加一层语义等价比对：

- 对象键序不计；数组序保持语义（数组有序是 JSON 语义，不可比掉）；值严格相等（字符串大小写敏感、`"1"`≠`1`、true≠1）
- 解析失败（非 JSON / 极端形态 / pwsh 5.1 无 `-AsHashtable`）一律兜底回字节判定 drift——宁严勿松，不可假绿

面内自动同步：status / verify / triage / inventory / profile 提示六方共用单一来源，无需各自改动。

## 边界

- LDC 侧（bash/jq）同构问题不在本票范围（双边各自优化；LDC 是否跟进由 LDC 侧会话定夺）
- 渲染账本（Get-DriftDirection）不动——仅 drift 态调用，语义 ok 不进入方向判定

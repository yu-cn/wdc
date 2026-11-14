# 01 · Test-DotfileInSync JSON 落点语义比对（键序差异不再判漂移）

Status: done
Type: task

## 背景

2026-11-14 LETH：wdc sync 收敛完成后 VSCode 设置 UI 重写落点，`window.autoDetectColorScheme` 键值未变、位置从 73 行移到文件尾——字节判定报 drift。吸收/还原两路均打地鼠（详见 [spec.md](../spec.md)），主人拍板改语义比对。

## 验收清单

- [x] `Test-JsonSemanticEqual` 递归比对：对象键序不计 / 数组序保持 / 标量严格（字符串 `-ceq`、类型不混、数值语义等）
- [x] `Test-DotfileInSync` 字节不符且 `*.json` 时走语义层；解析异常兜底回 drift
- [x] 冒烟用例：键序互换→ok、数组重排→drift、改值→drift、带注释 JSON→按解析结果、字节一致→ok（快路径不变）、非 JSON 不受影响
- [x] 真机：当前 VSCode settings 键序漂移在改后判 ok，`wdc status` 零漂移、`wdc verify -Quick` 绿
- [x] validate.ps1 全绿；CHANGELOG Unreleased 记账

## Comments

- **2026-11-15 实施（LETH 会话）**：15/15 冒烟用例全过。两处实测修正了用例假设——① pwsh 7 解析器（Newtonsoft）实际**容忍尾逗号**，尾逗号模板 vs 无尾逗号落点语义等价判 ok 属正确结论（兜底路径改用不可解析垃圾输入验证，PASS）；② 空落点文件（存在但空）判 drift 属正确（坏渲染），`absent` 以真缺失验证 PASS。真机：7 落点逐项全 ok、`wdc status` 漂移清零（改后无需重渲染，原键序漂移被语义层消化）、validate 3/3 全绿。渲染账本（Get-DriftDirection）不动——仅 drift 态调用，语义 ok 不进入方向判定。

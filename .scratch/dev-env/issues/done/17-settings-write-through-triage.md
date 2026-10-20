# 17: settings.json 写穿的吸收/还原工作流（VSCode 类高频写穿）

**What to build:** WT/gh 之外，VSCode 也会在 innocuous 操作时自动写穿被符号链接的 settings.json（2026-10-20 实录：`workbench.editorAssociations` md 关联 + 实验性 UI 开关）。人工 `git checkout` 还原可行但费神；需要一个顺滑的分流工作流。

**Blocked by:** None (can start immediately)

**Status:** needs-triage

- [x] 定夺（环境主人）：加一个 `scripts/triage-dotfiles-drift.ps1`——展示 dotfiles/ 与 HEAD 的 diff，逐块二选一（吸收进模板并 commit / 还原为机器噪声），还是维持人工流程（文档已写清）（2026-10-20 定夺：加脚本，做最小版）

## Comments

- 2026-10-20（ASUS 会话）：首次实录即被「dotfiles 与 HEAD 一致」断言当场暴露（断言上线首日抓获 WT、三日内抓获 VSCode，防线有效性已验证）。本次两笔写穿按「未点名的机器噪声」默认还原；若环境主人希望 md→markdown 编辑器关联等成为跨机偏好，点名即可吸收进模板。

- 2026-10-20（ASUS 会话）：`editorAssociations`（md→markdown 编辑器）第二次写回（同一会话两次），判定为环境主人真实偏好：**已吸收进模板**（机器无关值，无路径/ID），commit 341f035。否决即一行 revert。另：agent 再次因 `git add -A` 误携写穿文件——协作文档已增「禁 add -A、显式按路径」红线。

- 2026-10-20（主机会话）：环境主人定夺加脚本，做**最小版**：逐文件（不逐 hunk）二选一——吸收（显式路径 pathspec commit，绝不 add -A）/ 还原（checkout HEAD），回车默认还原（噪声是常态，ADR-0003 判据）。已实现 `scripts/triage-dotfiles-drift.ps1`（含 `-DryRun` 只看不动手；未跟踪文件不碰、留人工）；verify-machine 的写穿断言 FAIL 时现在直接提示处置命令，发现→处置闭环。

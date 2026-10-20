# 17: settings.json 写穿的吸收/还原工作流（VSCode 类高频写穿）

**What to build:** WT/gh 之外，VSCode 也会在 innocuous 操作时自动写穿被符号链接的 settings.json（2026-10-20 实录：`workbench.editorAssociations` md 关联 + 实验性 UI 开关）。人工 `git checkout` 还原可行但费神；需要一个顺滑的分流工作流。

**Blocked by:** None (can start immediately)

**Status:** needs-triage

- [ ] 定夺（环境主人）：加一个 `scripts/triage-dotfiles-drift.ps1`——展示 dotfiles/ 与 HEAD 的 diff，逐块二选一（吸收进模板并 commit / 还原为机器噪声），还是维持人工流程（文档已写清）

## Comments

- 2026-10-20（ASUS 会话）：首次实录即被「dotfiles 与 HEAD 一致」断言当场暴露（断言上线首日抓获 WT、三日内抓获 VSCode，防线有效性已验证）。本次两笔写穿按「未点名的机器噪声」默认还原；若环境主人希望 md→markdown 编辑器关联等成为跨机偏好，点名即可吸收进模板。

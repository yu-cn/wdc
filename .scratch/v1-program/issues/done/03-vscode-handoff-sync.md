# 03 VSCode 全让位——扩展/设置/键位归原生设置同步

Status: done
Type: task

## 定夺

主人 2026-11-21（W-B 推进前讨论）：VSCode 自带账号级设置同步，WDC 没必要插手——**全让位**（本体归 WDC；扩展/设置/键位归同步）。上游 WindowsDeveloperConfig 边界查实同款：只装本体、零扩展管理、不碰 settings/keybindings、不进用户 profile（除 WT/pwsh profile）。原「要求关闭 VSCode 设置同步」设计（仓库是唯一主人）撤销——替账号做主、与原生机制打架，正是「弄坏已有环境」批评的具体形态。

## 内容

- dotfiles-map 7→5：VSCode settings/keybindings 出列（六方消费自动跟随单一来源）
- `configs/vscode-extensions.txt`、`scripts/install-vscode-extensions.ps1`、`dotfiles/windows/vscode-{settings,keybindings}.json` 除名（git rm）
- bootstrap-main Stage 4 瘦身（只余语言默认环境）；`wdc exit` 撤扩展卸载段（账号数据，数据面不动延伸）
- README：编辑器段、首跑配合事项第 4 条**反转**（关同步→登录开同步）、fork 改造清单
- 判据落档：ADR-0003 修订标注二 + GLOSSARY「通用核心」判例二

## 验收

- [x] validate 全绿（脚本静态 + 契约）
- [x] `wdc exit` 预演实测：扩展段消失、dotfiles 处置 3 还原 2 删（gitconfig/bashrc/WT 有 .bak，pwsh/starship WDC 创建）
- [x] CHANGELOG 记账

## Comments

- 2026-11-21 开票即收。附带红利：VSCode 设置 UI 键序假漂移源（json-semantic-sync 票的起因）随落点出列消失；坑6 类 VSCode 写穿落点面消失。存量机过渡：落点文件原样在位（实体渲染拷贝），主人登录开同步后 VSCode 自行接管（上传当前态为账号事实源）。

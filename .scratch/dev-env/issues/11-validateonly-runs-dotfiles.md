# 11: bootstrap -ValidateOnly 实际执行了 dotfiles 安装

**What to build:** `bootstrap.ps1 -ValidateOnly` 行为与文档不一致：README 与脚本头注释均称该模式「只做无副作用校验」，但 Stage 6（Dotfiles 安装）没有 `-ValidateOnly` 守卫，实际执行了符号链接替换与身份迁移。修复方向二选一：给 Stage 6 补守卫，或修正文档措辞——决策归环境主人（任一机器会话可执行）。

**Blocked by:** None (can start immediately)

**Status:** needs-triage

- [x] 定夺修复方向：Stage 6 补 `-ValidateOnly` 跳过守卫，或 README/脚本注释改口（2026-10-20 定夺：补守卫，文档措辞不动）
- [x] 按定夺实施并通过仓库的无副作用校验

## Comments

- 2026-10-19（第二台机会话）：真机验收（工单 10）时发现。首跑 `pwsh bootstrap.ps1 -ValidateOnly`：Stage 2–5 均按守卫 SKIP，唯独 Stage 6 完整执行——`~/.gitidentity` 从既有 .gitconfig 迁移身份，.gitconfig/.bashrc/pwsh profile/VSCode settings+keybindings/终端 settings/starship.toml 全部替换为仓库符号链接（旧文件均有 `.bak` 备份）。对本机全量收敛无影响（这些变更本就要发生），但「无副作用校验」的承诺被打破：干净 VM 上首跑校验也会直接动机器。

- 2026-10-20（主机会话）：环境主人定夺补守卫。理由：Stage 2–5 四个阶段已有同款守卫，Stage 6 属遗漏而非设计；validate 模式做符号链接替换+身份迁移是全流程副作用最重的一步，改文档等于永久合法化一个会动机器的「校验」。已实现（与其余阶段同款一行），`bootstrap.ps1 -ValidateOnly` 实测 Stage 6 SKIP。

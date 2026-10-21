Status: ready-for-human

# 01 · vp 语言栈事实的单一来源

## 问题

版本钉子 `1.3.0` 硬编码三处（install-languages.ps1 字面量、setup-ubuntu.sh 字面量、verify-machine.ps1 正则形态 `'1\.3\.0'`——连写法都漂了）；vp「两种官方布局」探测在 4 个文件 × 2 种语言各写一份。升级 vp 需跨 3 文件同步，漏一处即机器间静默不一致。

## 方案（已实施）

- 新增 `configs/vp-version`（钉子唯一来源；`.gitattributes` 钉 LF——WSL 侧 bash 逐行读，同一族防护）
- `scripts/lib/common.ps1` 增 `Get-VpPin` / `Get-VpWinExe`；install-languages.ps1、verify-machine.ps1 改用（verify 的钉子断言改读钉子文件，不再可能落后）
- `scripts/wsl/setup-ubuntu.sh` user 阶段改读 `$REPO_WSL/configs/vp-version`（缺失或为空即 FAIL，不静默降级到不钉版安装）

## 验收清单

- [ ] validate.ps1 全绿（commit 时 pre-commit 自动跑）
- [ ] 真机 bootstrap：languages 阶段 OK、日志显示钉子 1.3.0
- [ ] WSL 侧重跑（bootstrap -NoElevate）：setup-ubuntu.sh user 阶段 vp 段 OK
- [ ] `pwsh scripts/verify-machine.ps1`：「vp Windows 侧 = 钉子」OK

## Comments

- 2026-10-21 实施（ZCode 会话，该环境无 shell）：编辑已写盘未提交，提交命令见当次会话收尾；validate 由 pre-commit 钩子把关，真机项待环境主人执行。

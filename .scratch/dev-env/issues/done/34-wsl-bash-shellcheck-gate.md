# 34: validate 增 WSL shellcheck 关卡（bash 语义静态检查）

**What to build:** `validate.ps1` 增第 3 段：WSL Ubuntu 在位时对 `scripts/wsl/*.sh` 跑 shellcheck（有界文件捕获，坑①纪律）。动机：工单32 实录——`rev-list --left-right --count` 输出 TAB 分隔被按空格 `%% *` 切开，`bash -n` 全绿放行、shellcheck 必红；WDC 的 bash 脚本此前只有语法级把关。shellcheck 由 LDC `cli-tools.pkg` 装进发行版（委托后自然就位）；无 WSL 机器（CI runner）或 shellcheck 未装（LDC 接管前的旧机）→ SKIP 不拦 commit。

**Blocked by:** None

**Status:** done

- [x] validate.ps1 加 Validate 3/3 段（exit 0 / 127=未装 SKIP / 超时 SKIP / 其余 FAIL 转发 findings）
- [x] 本机验证全绿（LETH：WSL 在位 + shellcheck 就位，3 脚本过）

## Comments

- 2026-10-24（LETH 会话）：随 v0.4.0 收口。工单32 两个包装层 bug 均属 shellcheck 可拦类别（SC2046 词切分族）。

# 08 ASUS v1.0.0 发布后 48h 补验（双机闭环）

Status: done
Type: task

> 编号说明：移交指定文件名 `05-asus-post-release-verify.md` 与既有 done/05-pwsh-source-agnostic.md 撞号，
> 顺延取当时下一空号 08（编号事实性顺延，处置口径不变——开票即收口归档）。

## 三步结果（2026-11-22，ASUS，会话移交自 LETH；tag 4e207ce / HEAD d484e84）

### ① wdc sync

- 拉取 38 提交（v0.14.0 d3c6e67 → d484e84）；CLI 注入选择在非交互会话走默认「装」（cli.json 落定）。
- 首轮（agent 会话内）bootstrap Stage 3 cli-tools 域 FAIL，根因 Mise 单元（移交预判命中，LETH 实录同款）：

  ```
  Microsoft.WinGet/Package [Mise]
    The configuration unit failed while attempting to apply the desired state.
  2026-11-21T18:17:48Z ERROR Failed to run process 'winget': ... remove_all: Access is denied.:
    "C:\Users\User\AppData\Local\Microsoft\WinGet\Packages\jdx.mise_Microsoft.Winget.Source_8wekyb3d8bbwe\mise"
  [FAIL] cli-tools - winget configure 退出码 -1978286075
  ```

  ZCode MCP 服务占 mise shim 锁 → 按移交停手；主人无 ZCode 普通终端重跑 `wdc sync` 全量收敛成功
  （提权子回合退出码 0，323s），Stage 4–7 首轮亦全过（WSL 段 30.6s 拉发行版内 ldc 到最新）。
- 预期现象均如期：pwsh 停 7.6.10（坑19 跨形态升级假绿）、Chrome/VSCode 扩展两让位、
  Git.Git 无新版未触发坑14、字体/gh/bat/delta 等 40+ 单元 applied。

### ② wdc verify（Quick）

- 单项 FAIL，系 v1.0.0 遗留断言（bef1b63 让位批漏改，另立 09 票收口）：

  ```
  [FAIL] 扩展清单全部在位 - Cannot find path 'D:\Devs\Repos\WDC\configs\vscode-extensions.txt' because it does not exist.
  ```

- 其余全绿：Windows 侧 5 落点内容一致 / 身份与注册表 / 语言栈 / WSL 平台配置两半边 / LDC verify --quick 全过；
  两处 SKIP 为 LDC 侧 headless 形态预期（ADR-0005/0008）。

### ③ wdc clean-legacy（报告模式，恒 exit 0）

发现 3 项：

- **uv 双装遮蔽**：`~/.local/bin/uv.exe` 0.13.1（+同批 uvx.exe/uvw.exe）遮蔽 winget 声明版 →
  **LETH 同款处置**：删三副本，`uv --version` 复析为 0.13.9（WinGet Links，声明面）。
- **Cascadia per-user 字体 74 文件**（LETH 仅 2 文件，ASUS 为全套 Cascadia Code/Mono × 普通/NF/PL 变体）→
  **LETH 同款处置**：`HKCU\...\Windows NT\CurrentVersion\Fonts` 74 注册值 + `%LOCALAPPDATA%\Microsoft\Windows\Fonts`
  74 文件全删（.NET API 枚举、值↔文件配对零孤儿后动手；WM_FONTCHANGE 已广播；同目录其余 per-user 字体
  为机器自留地未触碰）。
- **死计划任务 `\WDC-GitUpgrade-20261107-1853`**：原样记录（SafeToFix，正道 `wdc clean-legacy -Fix`，主人定夺）。

复跑幂等确认：uv/Cascadia 两节转 `[OK]`，唯余死任务一项；其余六节干净。

## 顺带（坑18 巡检）

- 仓库根 `tmpwebapp-node-modulesprepare.log` 同日复发（02:06，video2code stderr 反斜杠被吃同款），无取证价值已删；
  其余 ignored 面干净（非 logs/、非插件目录零残渣）。

## 结论

- 除 09 票所列 v1.0.0 遗留物外，ASUS 与 v1.0.0 声明一致；v1.0.0 双机闭环成立
  （发现的问题以 v1.0.1 收口，不回改 1.0.0 tag——移交口径）。

## Comments

- 2026-11-22 会话实录：sync 一折（Mise shim 锁停手→主人无 ZCode 重跑过）→ verify 单项 FAIL 定性
  （bef1b63 漏改 verify-machine.ps1:56）→ clean-legacy 三项处置/记录 → 本票 + 09 票 + exit-mechanism 02
  归档 + 04 票补记同批 commit 收口。

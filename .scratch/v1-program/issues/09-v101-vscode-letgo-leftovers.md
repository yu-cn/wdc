# 09 v1.0.1 盘面——VSCode 让位批漏改残留（ASUS 48h 补验发现）

Status: ready-for-human
Type: task

根提交 bef1b63（工单03 VSCode 全让位，ADR-0003 修订标注二）删除扩展清单/安装脚本/模板并同步改了
exit-wdc.ps1 等 12 处，但漏了三处仍引用已删文件的地方；CI 又无 verify 腿，绿灯放行进 v1.0.0。
**修不修、何时修、v1.0.1 是否成版归主人定夺**（08 票联动；不回改 1.0.0 tag）。

## 逐项（含取证）

1. **P1 · verify 断言读已删清单**——`scripts/verify-machine.ps1:56-60`「扩展清单全部在位」无条件
   `Get-Content configs\vscode-extensions.txt`：任何机器在 v1.0.0 跑 `wdc verify` 必 FAIL（ASUS 双跑实录，
   机器本体收敛无恙——bootstrap 全绿）：

   ```
   [FAIL] 扩展清单全部在位 - Cannot find path 'D:\Devs\Repos\WDC\configs\vscode-extensions.txt' because it does not exist.
   ```

   建议方向：断言整块退役（扩展已归账号态/自留地，ADR-0003 口径下无机器侧断言面）；或以清单文件存在为
   前置的门卫写法（防未来再引入清单时旧坑复发）。
2. **P2 · undo-table 指已删清单**——`docs/undo-table.md:71` 退出指引让用户按 `configs/vscode-extensions.txt`
   逐个 `code --uninstall-extension <id>`。建议：该行改为「扩展随账号（Settings Sync），无机器侧退面」。
3. **P3 · editors.winget 注释陈旧**——`configs/editors.winget:1-3` 注释仍指向已删编排层
   （`scripts/install-vscode-extensions.ps1` + `configs/vscode-extensions.txt`），且 Settings Sync 表述是让位前
   口径（README 已反转为「登录开同步」）。dscv3 死锁史实可留作背景，指向与口径需改。
4. **根因放大器 · CI 无 verify 腿**——fresh-machine.yml 六步为 bootstrap / 幂等重跑 / 快照断言 /
   clean-legacy 零发现 / exit 全退 / 退了→装重装，无一步跑 `wdc verify`；validate.ps1 亦为静态检查 +
   winget configure validate，不含机器断言——本 P1 得以绿灯进版。建议：fresh-machine 增 verify 腿
   （幂等重跑步之后最自然），或 validate 阶段点验 verify 脚本引用的仓库文件齐备。是否补腿、补哪种归主人。

## Comments

- 2026-11-22 开票（ASUS 48h 补验 08 票联动）。四项均为断言/文档残留，无行为面损伤；1–3 为同根
  （bef1b63 漏网），4 为流程缺口。

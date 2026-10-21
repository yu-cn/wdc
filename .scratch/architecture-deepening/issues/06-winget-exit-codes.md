Status: done

# 06 · winget 退出码语义收一处（先查证）

## 问题

退出码语义（0/1 良性、负 HRESULT 才是错——坑④）只活在 validate.ps1 的注释里；bootstrap.ps1 出现无注魔数 `-1978335189`；bootstrap-main 的 apply 阶段对 `winget configure` 只认 0——**若 configure 也把 1 当「仅警告」，全量收敛会假 FAIL**。

## 查证结论（2026-10-21）

官方码表（microsoft/winget-cli `returnCodes.md`）：`0x8A15002B = APPINSTALLER_CLI_ERROR_UPDATE_NOT_APPLICABLE`（无适用升级，非错误）——bootstrap.ps1 那个魔数即此；**全表没有通用的「1=警告」语义**，配置类错误清一色 `0x8A15C00x` HRESULT；本仓 `logs/` 全量检索亦无 `winget configure` 退出码 1 的实例。结论：configure 回 1 未实证良性，**宁严勿松，维持只认 0**；未来真机若实测 configure 回 1 且单元全部成功，再放宽 Test-WingetExitCode 的 configure 分支（届时在此补实录）。

## 方案（已实施）

common.ps1 增 `Test-WingetExitCode`（按 operation 分域：validate 认 0/1，configure / upgrade 只认 0）；validate.ps1、bootstrap-main Stage 3 改调同一判码；bootstrap.ps1 魔数具名 `$noUpgrade` 并注明 0x8A15002B 出处（改动保持 5.1 可解析）。

## 验收清单

- [x] 查证结论记录于本工单（如上）
- [x] 判码口径三处统一；validate 全绿（单测矩阵：validate+1=True、configure+1=False、0=True、负 HRESULT=False）
- [x] 真机 bootstrap 冒烟无假 FAIL——判码行为与改前一致（configure 仍只认 0，仅收敛实现），提权侧确认并入工单 03 的 sync 冒烟

## Comments

- 2026-10-21 查证 + 实施（工单 04-06 批次）。

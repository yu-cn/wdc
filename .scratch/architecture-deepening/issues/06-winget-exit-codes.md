Status: ready-for-agent

# 06 · winget 退出码语义收一处（先查证）

## 问题

退出码语义（0/1 良性、负 HRESULT 才是错——坑④）只活在 validate.ps1 的注释里；bootstrap.ps1 出现无注魔数 `-1978335189`；bootstrap-main 的 apply 阶段对 `winget configure` 只认 0——**若 configure 也把 1 当「仅警告」，全量收敛会假 FAIL**。

## 查证步骤（第一步，先做）

1. 翻 `logs/` 与 `elevated-*.log`：找 `winget configure` 退出码 1 的实例，看单元是否实际全部成功
2. 无实例则在真机手动构造一次带良性警告的 configure（如未指定模块的单元）观察退出码

## 方案（查证后）

语义收进 common.ps1 判码函数（0/1 良性 · 负 HRESULT 错 · 具名常量），validate / apply / PS7 升级共用；bootstrap.ps1 的魔数具名并注明出处。注意 bootstrap.ps1 须保持 5.1 可解析（改动约束见其文件头）。

## 验收清单

- [ ] 查证结论记录于本工单 Comments（configure 的 1 到底良性与否）
- [ ] 判码口径三处统一；validate.ps1 全绿
- [ ] 真机 bootstrap 冒烟无假 FAIL

## Comments

- 2026-10-21 开单（架构评估候选 6，Worth exploring，含一个翻日志即可定论的正确性疑问）。

# 存量机升级到 v1.0.0 指引

> 适用：已用旧版 WDC 收敛过的机器（直接用 [yu-cn/wdc](https://github.com/yu-cn/wdc) 或 fork）。v1.0.0 是产品定位里程碑（[ADR-0009](adr/0009-oneshot-manual-update-reconverge.md) 一次性配置 + 显式更新/回归 + 完整退出），本指引讲清升级会自动发生什么、哪些行为变了、哪些建议手动做。

## 一条命令

```powershell
wdc sync
```

fetch → `pull --ff-only` → 全量 bootstrap → verify。本地领先/分叉/工作区脏时自动中止交人工（fail-safe 语义不变）；全程幂等、落点覆盖前 `.bak` 保护、JSON 语义比对防假漂移。

## 升级中自动发生什么（无需干预）

| 变化 | 对存量机的效果 |
|---|---|
| WT 模板 commandline 改裸 `pwsh.exe`（工单05，MSI→MSIX 时代适配） | 落点重渲染一次；MSI 旧机 / MSIX 新机同一模板通吃 |
| Chrome 除名声明面（[ADR-0003 修订标注](adr/0003-universal-core-only.md)，工单02） | **不卸载**——Chrome 原样保留，转为机器自留地自管（以后自己更新） |
| VSCode 全让位原生设置同步（ADR-0003 修订标注二，工单03） | settings/keybindings 落点出管理面、文件原样留在原地；扩展不再自动安装/更新 |
| pre-install 快照机制上线（工单01） | 存量机自动落「快照缺席」标记——将来 `wdc exit` 的注册表还原按 [undo 表](undo-table.md) 恢复 Windows 默认值并明示 |
| 定位叙事（ADR-0009） | 零行为变更——`wdc sync` 从「日常」改口「手动更新/回归入口」，漂移合法不纠察 |

## 建议的两件手动事（升级前后皆可）

1. **登录 VSCode 并开启设置同步**（齿轮/账户图标 → 开启设置同步）——扩展/设置/键位从此随账号走。不开启也不坏：只是扩展冻结在当前版本、新机要手动装。
2. **扫一遍 `wdc clean-legacy`**（报告模式，零变更）——看历史残留（uv 双装遮蔽 / Cascadia per-user 字体 / 死计划任务类）；确认后 `-Fix` 清安全项。

## 可选：pwsh 7.6 → 7.7

7.6 是 LTS，继续用完全没问题。要上 7.7 注意：**官方已停发 MSI，winget 拒绝跨安装技术升级（且退出码 0 假绿）**，需手动两步：

```powershell
winget uninstall -e --id Microsoft.PowerShell
winget install -e --id Microsoft.PowerShell --source winget --accept-package-agreements --accept-source-agreements
```

WDC 全链已源不可知（WT 裸 `pwsh.exe` / 入口层候选含 WindowsApps 别名 / 计划任务动作运行时解析），两种形态均正常工作。

## 新能力速览

- `wdc plan`——更新/回归前的干跑预演（漂移积累越久，单次回归覆盖面越大，先看一眼）
- `wdc clean-legacy [-Fix]`——版本残留签名清扫
- `wdc exit [-KeepTools] [-Yes]`——完整退出（[ADR-0010](adr/0010-wdc-exit.md)：声明面全退、数据面不动）

## fork 用户

照 [forking.md](forking.md) merge 上游即可；冲突预期按层：`scripts/` 机制层倾向收上游，`configs/` 与 `dotfiles/` 偏好层倾向保自己。

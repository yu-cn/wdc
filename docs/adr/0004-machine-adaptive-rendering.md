# 机器派生值不入库：通用模板 + 安装期机器适配渲染

配置中凡由具体机器环境派生的值（WSL 发行版注册 ID、随机的 GUID、本机图标路径、用户名路径），不得硬编码进仓库文件——它们跨机必错（第二台机实测：WT 的 Ubuntu 条目因 GUID 与发行版 ID 派生规则失效而消失；WT 保存设置时又把本机路径写穿符号链接进仓库）。模式与身份文件（ADR-0003 的 `~/.gitidentity`）同构：**仓库只存通用模板与生成逻辑，机器派生值在 bootstrap 安装期解析，渲染到机器本地、不入仓库的位置**。

首例落地：Windows Terminal 的 WSL profile。settings.json 模板只保留跨机不变的内容（配色、字体、通用 profile），不含任何 WSL 条目；`scripts/install-wt-profiles.ps1` 枚举本机 WSL 发行版（注册表 Lxss），按实际名称/ID/图标路径生成 fragment（`…\LocalState\fragments\wdc-wsl.json`，机器本地文件），每次 bootstrap 重渲染、发行版增减自动跟随，GUID 用名字哈希派生保证稳定。验收断言检查 fragment 在位。已知残余限制：用户在 WT 设置 UI 里做任何保存，WT 会把全量状态（含机器值）重写进被符号链接的 settings.json——verify 的「dotfiles 与 HEAD 一致」断言负责暴露，守则是改终端设置改仓库模板而非 UI。

拒绝的替代：把发行版名写死进模板（名字/ID 因机而异，正是本决策要消除的）；放弃 settings.json 符号链接改为复制（失去「仓库是唯一主人」的漂移可见性）。

# WT 的 WSL profile 静态声明进模板（片段渲染机制退役）

settings.json 模板的 `profiles.list` 直接声明 Ubuntu WSL 条目（`wsl.exe -d Ubuntu`、名字哈希稳定 GUID、省略图标），删除 `install-wt-profiles.ps1` 渲染机制与其产物断言，残留 fragment 文件由移除清单清理。

理由：WT 1.24 实测 **fragment 层不可依赖**——官方路径（`%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\`）上的片段短暂出现后消失，原子写入、路径修正、触发重载均救不回；且 **WSL 自带的官方片段（Microsoft.WSL）在同一台机器上从未物化**（state.json 跟踪了其 GUID 而界面始终不显示）——机制层的毛病，不是渲染姿势问题。settings.json 本体是 WT 最可靠的加载路径，改动即时生效。

ADR-0004 当初把 WSL profile 抽出模板，是因为旧写法含机器派生值（发行版 GUID、本机图标路径）跨机必错。静态条目不含任何机器派生值——发行版名 `Ubuntu` 本就是仓库声明的一部分（install-wsl.ps1 装的就是它），图标是唯一的派生值、直接省略——该担忧不适用。「机器派生值不入库」原则本身不变，继续适用于真正的派生值（身份文件、`~/.wdc` 指针等）。

代价与边界：本条目只覆盖声明的 Ubuntu；机器上额外的发行版归 WSL 自带机制与机器自留地，正是分层本意。

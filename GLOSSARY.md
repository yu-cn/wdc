# WDC — 个人 Windows 开发环境

把「我的 Windows 开发环境」变成可重放、可迁移的声明式仓库：新机器 clone 后跑一条命令即得完整环境。基于 microsoft/WindowsDeveloperConfig 的做法自建，不 fork（ADR-0001）。

## Language

**环境配置**:
声明「一台机器应当处于什么状态」的幂等配置——装哪些软件、开哪些系统设置。
_Avoid_: settings、安装脚本

**dotfiles**:
声明「我这个人偏好什么」的个人配置文件（shell profile、编辑器与终端设置等），与环境配置相对：机器 vs 人。
_Avoid_: 配置文件（在本仓库语境下歧义）

**bootstrap**:
把一台新机器带到目标状态的唯一入口：clone 后运行的一条命令，应用全部环境配置并安装 dotfiles。
_Avoid_: setup.sh、装机脚本

## 分层

**Windows 侧**:
运行在 Windows 本体上的那一半环境（软件、系统设置、Windows 下的 dotfiles）。

**WSL 侧**:
运行在 WSL/Ubuntu 里的另一半环境（apt 包、Linux 下的 dotfiles），与 Windows 侧同仓库管理、各自的安装机制独立。
_Avoid_: Linux 环境（指代不清）

**通用核心**:
配置中每台开发机都需要的那部分；某项只要存在「某台机器不需要」的情形即出局，归机器自留地。
_Avoid_: 默认配置

**机器自留地**:
不进仓库、由各台机器自行安装维护的个性化工具（如本机的 JetBrains 套件）；bootstrap 对其一概不碰。
_Avoid_: 可选模块

**机器对等**:
所有开发机地位平等、无主从：每台 clone 后 bootstrap 即得完整环境，工单与决策经仓库（`.scratch/` + git）流转，由环境主人定夺、任一机器会话可执行。
_Avoid_: 主机、主开发机、第二台机

**身份文件**:
每台机器本地保存 git user.name/email 的文件（`~/.gitidentity`），bootstrap 首次生成占位、永不入仓库；gitconfig 模板通过 include 引用它。
_Avoid_: git 凭据（指代不同的东西）

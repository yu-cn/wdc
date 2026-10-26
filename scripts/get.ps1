# get.ps1 - 远程一键引导（运行时仓库尚不存在，故不依赖本仓库任何脚本）
# 用法（裸机任一 shell 粘贴，Windows 10/11 自带的 winget + Windows PowerShell 即够）：
#   powershell -c "iex ((irm https://raw.githubusercontent.com/yu-cn/wdc/main/scripts/get.ps1).Trim([char]0xFEFF))"
# 职责：确保 winget 在位 → 缺 Git 则 winget 安装（弹一次 UAC，bootstrap 本也要提权）
#       → 定位或 clone 仓库 → 转发 bootstrap.ps1（PowerShell 7 装配在其内，本文件保持 5.1 可解析）
# fork 用户：本文件写死上游地址——fork 后走 README 的手动 clone 路径，或把地址改成你的仓库
# 约束：禁用三元/??/&& 等 PS7 语法；含中文字符串，需 UTF-8 BOM（与 bootstrap.ps1 同）
#       不可加 [CmdletBinding()]/param()，且用法命令必须 Trim([char]0xFEFF)——raw 按原样返回带 BOM 的字节，
#       irm 不剥 BOM：5.1 对带 \uFEFF 前缀的字符串会把首部 attribute 判「意外的属性」、把首行注释粘成
#       \uFEFF# 命令调用（注释失效）；Trim 去 BOM 后 AST 才干净。文件执行不受此影响（读文件剥 BOM）
$ErrorActionPreference = 'Stop'
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch { }
$repoUrl = 'https://github.com/yu-cn/wdc.git'
$defaultDir = Join-Path $HOME 'wdc'

function Write-Log { param([string]$Message) Write-Host "[get] $Message" }

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Log '未找到 winget（App Installer）——请先从微软商店安装「应用安装程序」后重试'
    exit 1
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Log '未检测到 Git —— winget 安装 Git.Git（弹一次 UAC，约 1-2 分钟）…'
    & winget install -e --id Git.Git --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Git 安装失败（winget 退出码 $LASTEXITCODE）——可手动安装后重跑：winget install Git.Git"
        exit 1
    }
    # winget 装完不刷新本进程 PATH：从注册表重组 Machine+User PATH 再探测，兜底补 Git\cmd
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machinePath;$userPath"
    if (-not (Get-Command git -ErrorAction SilentlyContinue) -and $env:ProgramFiles) {
        $gitCmd = Join-Path $env:ProgramFiles 'Git\cmd'
        if (Test-Path (Join-Path $gitCmd 'git.exe')) { $env:Path = "$gitCmd;$env:Path" }
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Log '安装完成但仍未定位到 git.exe —— 请重开终端后重试'
        exit 1
    }
    Write-Log 'Git 就位'
}

# 仓库定位：~/.wdc 指针有效则复用（已有机器重跑 = 收敛语义，ADR-0004 模式）；缺省 clone 到 ~\wdc
$repo = $null
$ptr = Join-Path $HOME '.wdc'
if (Test-Path $ptr) {
    $candidate = (Get-Content $ptr -Raw -ErrorAction SilentlyContinue)
    if ($candidate) { $candidate = $candidate.Trim() }
    if ($candidate -and (Test-Path (Join-Path $candidate '.git'))) { $repo = $candidate }
}
if (-not $repo) {
    if (Test-Path $defaultDir) {
        if (Test-Path (Join-Path $defaultDir '.git')) { $repo = $defaultDir }
        else {
            Write-Log "$defaultDir 已存在但不是 WDC 仓库 —— 不代删，请改名或移除后重试"
            exit 1
        }
    } else {
        Write-Log "clone 仓库 → $defaultDir"
        & git clone $repoUrl $defaultDir
        if ($LASTEXITCODE -ne 0) {
            Write-Log "clone 失败（git 退出码 $LASTEXITCODE）——检查网络后重跑"
            exit 1
        }
        $repo = $defaultDir
    }
}

Write-Log "仓库就位：$repo —— 转发 bootstrap（提权与 PowerShell 7 装配在其内）"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'bootstrap.ps1')
exit $LASTEXITCODE

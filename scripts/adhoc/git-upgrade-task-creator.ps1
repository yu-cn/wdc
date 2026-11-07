# 一次性创建器（坑14①）：以 HIGHEST 计划任务跑 Git 升级剧本——脱离 agent 会话进程树
# （Start-Process 分离的后台进程活不过工具调用回收，只有计划任务真脱钩；弹 UAC 由机主放行）。
# 动作必须用 pwsh 绝对路径：计划任务环境不解析 PATH，裸 pwsh.exe 报 0x80070002（2026-10-25 LETH 实录）。
# 用法：pwsh scripts/adhoc/git-upgrade-task-creator.ps1 [-TaskName 自定义名] [-ViaSudo]  ——登记后 2 分钟起跑
# -ViaSudo（工单43）：非提权 shell 建 /RL HIGHEST 任务报「拒绝访问」（2026-11-01 LETH 实录）——
#   sudo schtasks 内联提权（弹一次 UAC 交机主）；sudo 缺席时如实报错并给管理员终端指引。
param([string]$TaskName = ('WDC-GitUpgrade-' + (Get-Date -Format 'yyyyMMdd-HHmm')), [switch]$ViaSudo)
$target = Join-Path $PSScriptRoot 'git-upgrade-task.ps1'
$pwsh = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'
$start = (Get-Date).AddMinutes(2).ToString('HH:mm')
$tr = '"' + $pwsh + '" -NoProfile -ExecutionPolicy Bypass -File "' + $target + '"'
if ($ViaSudo) {
    if (-not (Get-Command sudo -ErrorAction SilentlyContinue)) {
        "TASK CREATE FAILED: sudo 未安装——管理员终端直接跑本创建器（不带 -ViaSudo），或在 设置>系统>开发者选项 开启 sudo 后重试"
        exit 1
    }
    sudo schtasks /Create /F /TN $TaskName /SC ONCE /ST $start /RL HIGHEST /TR $tr
} else {
    schtasks /Create /F /TN $TaskName /SC ONCE /ST $start /RL HIGHEST /TR $tr
}
if ($LASTEXITCODE -eq 0) { "TASK CREATED ($TaskName), start $start"; exit 0 } else { "TASK CREATE FAILED exit=$LASTEXITCODE"; exit 1 }

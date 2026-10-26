# 一次性创建器（坑14①）：以 HIGHEST 计划任务跑 Git 升级剧本——脱离 agent 会话进程树
# （Start-Process 分离的后台进程活不过工具调用回收，只有计划任务真脱钩；弹 UAC 由机主放行）。
# 动作必须用 pwsh 绝对路径：计划任务环境不解析 PATH，裸 pwsh.exe 报 0x80070002（2026-10-25 LETH 实录）。
# 用法：pwsh scripts/adhoc/git-upgrade-task-creator.ps1 [-TaskName 自定义名]  ——登记后 2 分钟起跑
param([string]$TaskName = ('WDC-GitUpgrade-' + (Get-Date -Format 'yyyyMMdd-HHmm')))
$target = Join-Path $PSScriptRoot 'git-upgrade-task.ps1'
$pwsh = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'
$start = (Get-Date).AddMinutes(2).ToString('HH:mm')
$tr = '"' + $pwsh + '" -NoProfile -ExecutionPolicy Bypass -File "' + $target + '"'
schtasks /Create /F /TN $TaskName /SC ONCE /ST $start /RL HIGHEST /TR $tr
if ($LASTEXITCODE -eq 0) { "TASK CREATED ($TaskName), start $start" } else { "TASK CREATE FAILED exit=$LASTEXITCODE" }

#Requires -Version 7
# inventory-machine.ps1 — 开发机只读盘点（用于接入验证与反向吸收分析）
# 严格只读：不安装、不修改任何东西。在任何一台开发机的仓库根目录运行：
#   pwsh scripts/inventory-machine.ps1 > .scratch/inventory-<机器名>-<日期>.md
# 然后把报告带回主仓库，由环境主人决定吸收哪些有益配置（ADR-0003 通用核心判据）。
[CmdletBinding()]
param()
$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

function Section { param([string]$T) "`n## $T`n" }
function KV { param([string]$K, [string]$V) "- ${K}: $V" }
. (Join-Path $PSScriptRoot 'lib/dotfiles-map.ps1')   # dotfiles 落点单一来源（与 install/verify 同面）

"# 开发机盘点报告 — $env:COMPUTERNAME — $(Get-Date -Format 'yyyy-MM-dd HH:mm')"

Section '系统'
KV 'OS' (Get-CimInstance Win32_OperatingSystem | ForEach-Object Caption)
KV 'winget' (winget --version 2>$null)
KV 'pwsh' $PSVersionTable.PSVersion.ToString()

Section '开发工具（winget 中的开发相关项）'
winget list --accept-source-agreements 2>$null | ForEach-Object { $_ -replace "`0", '' } |
    Where-Object { $_ -match '(?i)git|code|jetbrains|visual studio|python|node|dotnet|rust|go |jdk|java|docker|terminal|starship|posh|uv|fzf|ripgrep|fd|bat |zoxide|delta|power Toys|powertoys|everything|chrome|gh ' } |
    ForEach-Object { "- $_".TrimEnd() }

Section '命令行工具版本'
foreach ($t in 'git','node','npm','pnpm','python','uv','go','rustc','docker','gh','starship','fzf','zoxide','mise') {
    $c = Get-Command $t -ErrorAction SilentlyContinue
    if ($c) {
        $v = (& $t --version 2>$null | Select-Object -First 1)
        KV $t "$v  [$($c.Source)]"
    } else { KV $t '未安装' }
}

Section '版本管理器痕迹'
foreach ($m in 'nvm','fnm','volta','scoop','choco','mise','asdf') {
    KV $m "$(if (Get-Command $m -ErrorAction SilentlyContinue) { '存在' } else { '无' })"
}
KV 'NVM_HOME(env)' $([Environment]::GetEnvironmentVariable('NVM_HOME', 'User') ?? '无')

Section 'WSL'
(& wsl.exe -l -v) 2>$null | ForEach-Object { $_ -replace "`0", '' } | Where-Object { $_.Trim() }

Section 'dotfiles 存在性（只报有无与大小/状态，不读内容）'
# 落点清单来自 Get-DotfilesMap 单一来源；身份文件另加（机器数据，ADR-0003）
# 安装形态自 ADR-0015 起为渲染拷贝——盘点读内容状态（ok/absent/drift，Test-DotfileInSync 同源），不再报链接形态
$repo = Split-Path $PSScriptRoot -Parent
$probes = @(Get-DotfilesMap) + @(@{ Name = '~/.gitidentity'; Source = ''; Target = (Join-Path $HOME '.gitidentity') })
foreach ($f in $probes) {
    if (Test-Path -LiteralPath $f.Target) {
        $item = Get-Item -LiteralPath $f.Target
        $state = ''
        if ($f.Source) {
            $state = " [$(Test-DotfileInSync -Source (Join-Path (Join-Path $repo 'dotfiles') $f.Source) -Target $f.Target)]"
        }
        KV $f.Name "$([math]::Round($item.Length / 1KB, 1))KB$state"
    } else { KV $f.Name '不存在' }
}

Section 'VSCode 扩展'
if (Get-Command code -ErrorAction SilentlyContinue) { & code --list-extensions 2>$null } else { 'code CLI 不可用' }

Section 'WT profiles（仅名称与默认项）'
$wt = Join-Path (Get-WtLocalStateDir) 'settings.json'
if (Test-Path $wt) {
    try {
        $j = Get-Content $wt -Raw | ConvertFrom-Json
        KV 'defaultProfile' $j.defaultProfile
        $j.profiles.list | ForEach-Object { "- $($_.name)$(if ($_.hidden) { ' (hidden)' })" }
    } catch { 'settings.json 解析失败' }
} else { '未找到 WT settings' }

Section 'git 身份（本机当前，只报有无不报值——红线）'
# 全栈查询才展开 include（--global 按设计不展开，会假阴性，见工单14）
KV 'user.name' ([bool](git config user.name) ? '已设置' : '未设置')
KV 'user.email' ([bool](git config user.email) ? '已设置' : '未设置')

"`n## 盘点结束`n"

# pwsh-init-cache.ps1 — pwsh init 产物缓存（pwsh-startup 工单01）
# profile 每次开终端对三份静态产物重复 spawn + 求值（starship 双层 spawn / gh / zoxide，ASUS 真机合计 ~1s，
# 分步基准见 .scratch/pwsh-startup/spec.md）——bootstrap 渲染时生成到机器本地缓存，profile 侧命中即
# dot-source、缺失回退原样 spawn（存在性守卫原则不变，未 bootstrap 机器零报错）。
# 缓存是机器本地派生资产（ADR-0004 模式）：不入 dotfiles map、不参与漂移比对；失效=工具升级后重跑
# bootstrap（profile 内刻意不做版本校验——校验即 spawn，抵消收益）。
# 纯函数不依赖 common.ps1（与 dotfiles-map.ps1 同立意）：状态行返回给调用方，Write-Step 报告归安装器。

function Get-WdcInitCacheDir {
    # 缓存目录：与渲染账本/收敛账本同区（%LOCALAPPDATA%\wdc\）——机器本地状态集中地。
    # profile 模板按同一路径独立声明（模板必须自足，不入仓库引本库）；两处常量由工单验收清单守护。
    Join-Path $env:LOCALAPPDATA 'wdc\cache'
}

function Install-WdcInitCache {
    # 生成三份 init 产物缓存，幂等（同内容跳过写，对齐渲染拷贝语义）。
    # 返回状态行数组 @{ Tool; State; Detail }，State 口径对齐 Write-Step 词表（OK/CHANGED/SKIP）：
    # SKIP=工具缺席或生成失败——缓存是优化项，失败不拦安装（旧缓存保留，profile 回退路径兜底）。
    # starship 用 --print-full-init 单层直取全量 init——绕 profile 旧写法「init 产物是 117 字节壳、
    # 求值时再嵌套 spawn 一次」的双层 spawn（真机 ~700-820ms 的主因）。
    param([Parameter(Mandatory)][string]$CacheDir)

    # $LASTEXITCODE 预置 0：StrictMode 下首次引用未定义变量会炸；且本函数前的安装流程可能没跑过任何原生命令
    $global:LASTEXITCODE = 0
    $items = @(
        @{ Tool = 'starship'; File = 'starship-init.ps1'; ArgList = @('init', 'powershell', '--print-full-init') }
        @{ Tool = 'gh';       File = 'gh-completion.ps1';  ArgList = @('completion', '-s', 'powershell') }
        @{ Tool = 'zoxide';   File = 'zoxide-init.ps1';    ArgList = @('init', 'powershell') }
    )
    $out = @()
    if (-not (Test-Path -LiteralPath $CacheDir)) { New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null }
    foreach ($it in $items) {
        if (-not (Get-Command $it.Tool -ErrorAction SilentlyContinue)) {
            $out += [pscustomobject]@{ Tool = $it.Tool; State = 'SKIP'; Detail = '工具缺席——profile 走 spawn 回退（存在性守卫）' }
            continue
        }
        try {
            $argList = $it.ArgList
            $content = (& $it.Tool @argList | Out-String)
            if ($LASTEXITCODE -ne 0 -or -not $content.Trim()) { throw "退出码 $LASTEXITCODE 或输出为空" }
            $dst = Join-Path $CacheDir $it.File
            if (Test-Path -LiteralPath $dst) {
                # 幂等判定按「读回原文比对」：Set-Content 落盘会追加行尾致内容漂移（首轮实测踩中），故写入亦走
                # WriteAllText 原样落盘不追加——读回与内存串严格相等才算幂等
                if ((Get-Content -LiteralPath $dst -Raw) -eq $content) {
                    $out += [pscustomobject]@{ Tool = $it.Tool; State = 'OK'; Detail = '缓存已与产物一致（幂等跳过）' }
                    continue
                }
            }
            # WriteAllText + utf8NoBOM 显式声明：产物是工具英文输出纯 ASCII，5.1/pwsh7 双侧读取无歧义（坑16 口径）；
            # 不用 Set-Content——它追加行尾，破坏幂等比对
            [IO.File]::WriteAllText($dst, $content, [Text.UTF8Encoding]::new($false))
            $out += [pscustomobject]@{ Tool = $it.Tool; State = 'CHANGED'; Detail = "已生成 <- $($it.Tool) $($it.ArgList -join ' ')" }
        } catch {
            $out += [pscustomobject]@{ Tool = $it.Tool; State = 'SKIP'; Detail = "生成失败（旧缓存保留）：$($_.Exception.Message)" }
        }
    }
    return $out
}

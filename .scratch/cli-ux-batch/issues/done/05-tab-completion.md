# 工单05：wdc Tab 补全（pwsh + Git Bash）

Status: done

## 背景

无任何补全注册：pwsh 侧无 Register-ArgumentCompleter；Git Bash 侧无 complete。Tab 只会做
文件名补全。子命令表在脚本里有单一来源——补全注册从那里取，绝不在 profile 抄列表
（工单20「单一来源防漂移」立意的延伸）。

## 内容

- pwsh profile（dotfiles/windows/pwsh-profile.ps1）：`Register-ArgumentCompleter -CommandName wdc`
  （函数用非 -Native 形态），ScriptBlock 读 `~/.wdc` 指针 → 正则解析 wdc.ps1 的
  `$wdcCommands = '...'` 行取词表——纯文本解析零子进程（每次 Tab 不付 pwsh 启动成本）
- Git Bash bashrc（dotfiles/windows/bashrc）：`complete -F _wdc_completions wdc`，
  sed 解析同一行——同款单一来源
- 解析失败（指针缺失/格式漂移）静默返回空列表，不干扰补全框架
- 渲染拷贝模型：改模板不即时生效，须 bootstrap/wdc sync 重渲染——票内注明收口后重渲染验证

## 验收清单

- [ ] pwsh：`wdc <Tab>` 出全部子命令、`wdc sy<Tab>` 前缀过滤
- [ ] Git Bash：同上
- [ ] 解析路径零硬编码列表（删词测试：临时改 wdc.ps1 词表，补全跟随）
- [ ] validate 全绿 + 落点重渲染后真机验证

## 实录

- 真机（install-dotfiles.ps1 重渲染后）：pwsh TabExpansion2 'wdc up' → upgrade-git；Git Bash `wdc sy<Tab>` → sync、`wdc <Tab>` → 全部 10 词；词表解析自 $wdcCommands 行零硬编码；validate 全绿（cceb6b0）

# undo 表——退出与手工撤销对照

> [exit-mechanism 工单01](../.scratch/exit-mechanism/issues/01-presnapshot-undo-table.md) 的文档半边。对照上游 microsoft/WindowsDeveloperConfig 的「每项设置文档化 how to undo」做法。
>
> **还原基准优先级**：pre-install 快照（bootstrap 首次 apply 前导出，工单01 代码半边）> 本表 Windows 默认值。存量机（快照机制落地前已收敛）没有快照，只能按本表恢复到 **Windows 默认值而非你的原始值**——`wdc exit`（工单03）会明示这一降级。

## 注册表 opinion（base-windows 域，27 项）

动作两式：**删值**（Windows 缺省即目标状态，策略键连空键一并删）/ **置 N**（Windows 默认为在位值，删值行为未定义故显式写回）。

### 开发域核心

| 单元 | 位置 | WDC 值 | undo | 备注 |
|---|---|---|---|---|
| Sudo | `HKLM\...\Sudo` → `Enabled` | 3 | 删值 | 无值=未启用 sudo |
| DeveloperMode | `HKLM\...\AppModelUnlock` → `AllowDevelopmentWithoutDevLicense` | 1 | 删值 | 无值=开发者模式关 |
| LongPaths | `HKLM\...\FileSystem` → `LongPathsEnabled` | 1 | **置 0** | Windows 默认在位值 0 |

### 反转项

| 单元 | 位置 | WDC 值 | undo | 备注 |
|---|---|---|---|---|
| RemoteDesktopOff | `HKLM\...\Terminal Server` → `fDenyTSConnections` | 1 | **置 1** | 客户端版默认即 1；你先前手动开过 RDP 的话以快照还原为 0 |
| NotificationsOn | `HKCU\...\Notifications\Settings` → `NOC_GLOBAL_SETTING_TOASTS_ENABLED` | 1 | 删值 | 无值=通知开 |

### 主题

| 单元 | 位置 | WDC 值 | undo | 备注 |
|---|---|---|---|---|
| DarkThemeApps | `HKCU\...\Themes\Personalize` → `AppsUseLightTheme` | 0 | **置 1** | 浅色默认 |
| DarkThemeSystem | `HKCU\...\Themes\Personalize` → `SystemUsesLightTheme` | 0 | **置 1** | 浅色默认 |

### 资源管理器

| 单元 | 位置 | WDC 值 | undo | 备注 |
|---|---|---|---|---|
| ShowFileExtensions | `HKCU\...\Explorer\Advanced` → `HideFileExt` | 0 | **置 1** | 默认隐藏扩展名 |
| ShowHiddenFiles | `HKCU\...\Explorer\Advanced` → `Hidden` | 1 | **置 2** | 默认不显示隐藏文件 |
| FullPathTitlebar | `…Advanced` → `FullPathAddress` | 1 | 删值 | |
| OpenThisPC | `…Advanced` → `LaunchTo` | 1 | 删值 | 无值=默认打开 Home/快速访问 |
| FrequentFolders | `…Advanced` → `ShowFrequent` | 0 | 删值 | |
| FrequentFiles | `HKCU\...\Explorer` → `ShowRecent` | 0 | 删值 | |
| RecommendedFiles | `HKCU\...\Explorer` → `ShowCloudFilesInQuickAccess` | 0 | 删值 | |
| GitCodeFolders | `…Advanced` → `NavPaneShowVersionControl` | 1 | 删值 | |
| TipsOff | `…Advanced` → `ShowSyncProviderNotifications` | 0 | **置 1** | 默认显示（含广告）——退出后嫌吵再手动关 |
| AccountInsights | `HKCU\...\SystemSettings\AccountNotifications` → `EnableAccountNotifications` | 0 | 删值 | 回缺省 |

### 任务栏

| 单元 | 位置 | WDC 值 | undo | 备注 |
|---|---|---|---|---|
| TaskbarHideWidgets | `…Advanced` → `TaskbarDa` | 0 | 删值 | 无值=显示小组件按钮（服务级策略见下） |
| BluetoothOff | `HKCU\Control Panel\Bluetooth` → `Notification Area Icon` | 0 | 删值 | |
| EndTask | `…Advanced` → `TaskbarEndTask` | 1 | 删值 | 无值=End Task 关 |

### 开始菜单与搜索 · 隐私 · Edge（策略键）

| 单元 | 位置 | WDC 值 | undo | 备注 |
|---|---|---|---|---|
| WebSearchOff | `HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer` → `DisableSearchBoxSuggestions` | 1 | 删值+空键 | 策略键 |
| StartRecommendations | `…Advanced` → `Start_Layout` | 1 | 删值 | |
| ClickToDo | `HKCU\...\ClickToDoAndScreenCapture` → `Enabled` | 0 | 删值 | 无值=默认姿态 |
| RecallOff | `HKCU\...\Recall` → `Enabled` | 0 | 删值 | 无值=默认姿态 |
| WidgetServiceOff | `HKLM\SOFTWARE\Policies\Microsoft\Dsh` → `AllowNewsAndInterests` | 0 | 删值+空键 | 策略键 |
| EdgeNewTab | `HKLM\SOFTWARE\Policies\Microsoft\Edge` → `NewTabPageLocation` | about:blank | 删值+空键 | 策略键——退出即消除 Edge「由组织管理」标识（与上游同款副作用，一并退场） |
| EdgeOOBE | `…Policies\Microsoft\Edge` → `HideFirstRunExperience` | 1 | 删值+空键 | 同上 |

## 非注册表面的 undo 指针

- **包**（cli-tools / editors 两域；chrome 域已除名退役——存量机 Chrome 属机器自留地，不在退出面内；**VCRedist 基础设施运行库不卸**——公共依赖，退出后照常服务其他软件）：`winget uninstall --id <Id>`，同 ID 多版本并存须逐版本显式（坑7）；Id 清单即 `configs/*.winget`。
- **VSCode 扩展**（32 个）：`code --uninstall-extension <id>`，清单 `configs/vscode-extensions.txt`。
- **dotfiles 落点**：`wdc exit` 处置——有 `.bak`（首次渲染前原文件，永不清理）还原之；无 `.bak` 即 WDC 创建，删除。
- **WSL 侧**（.wslconfig / wsl.conf / LDC）：归 `wdc exit` T3 档（工单03），LDC 侧卸载器在姊妹仓另议。

# 02 声明面工具审视——Chrome 除名（通用核心第二轴）

Status: done
Type: task

## 定夺

主人 2026-11-21（sync/verify 收口后的产品反思）：wdc 面向开发环境配置与优化，通用软件除非不可或缺不管；Chrome 有 Edge 预装等价 → 除名。审视表三裁决：**只除 Chrome**（Everything / PowerToys 保留——系统级开发提效，无预装等价物）。

## 内容

- chrome 域退役：删 `configs/chrome.winget`、`Get-WdcDomains` / `Test-WdcDomainNeedsElevation` 摘除 chrome、cli-tools 尾注改史档
- 判据落档：GLOSSARY「通用核心」补第二轴 + ADR-0003 修订标注
- README CLI 清单行 / undo-table 包指针同步
- LDC 侧同镜头审视并入 Phase 3 批（其清单预判偏纯开发面，动面待扫）

## 验收

- [x] 除名≠卸载确认：存量机 Chrome 原样在装（自留地），audit 自装 +1 属预期
- [x] validate 全绿（域一致性校验过）
- [x] 变更后 `wdc verify -Quick` 全绿（chrome 域不再断言）
- [x] CHANGELOG 记账

## Comments

- 2026-11-21 开票即收。除名≠卸载实证：LETH Chrome 158.0.8127.37 原样在装且已自更新超 winget 源版本（自留地自管活证据）。附带发现：`.zcode/`（ZCode plan 模式会话产物）按 `.v2c/` 先例（70899ea）收编 .gitignore。审视全表 21 包：17 纯开发面保留 + Everything/PowerToys 保留（定夺）+ Chrome 除名。

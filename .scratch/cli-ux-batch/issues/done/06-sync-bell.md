# 工单06：wdc sync 完成 BEL 通知

Status: done

## 背景

wdc sync 全量分钟级（bootstrap 含 UAC）——切走窗口不盯梢，结束无感知。

## 内容

- sync 收尾（OK 与 FAIL 两路）汇总行后输出 BEL（`[char]7`，WT/Git Bash 均响应：响铃+任务栏闪烁）
- 不加开关：BEL 是终端原生提示非弹窗，噪声面可忽略；后续有抱怨再收（YAGNI）

## 验收清单

- [ ] sync OK/FAIL 两路都响（WT 真机）
- [ ] 快速路径秒级完成也响（一致口径）
- [ ] validate 全绿

## 实录

- bootstrap 失败与最终汇总两路收尾各 [Console]::Write([char]7)；快速路径秒级经最终汇总路覆盖；WT 真机响铃验收随下次真实 sync（BEL 字节输出已验证）；validate 全绿（cceb6b0）

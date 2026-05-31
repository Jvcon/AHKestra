# ClautoHotkey → opencode 集成设计

> 日期: 2026-05-31
> 状态: 已批准设计

## 概述

ClautoHotkey 是一个面向 Claude Code / Cursor / Cline 的 AHK v2 AI 辅助开发框架，包含模块知识库、AI agents、IDE 规则和实用脚本。本文档定义将其核心能力整合到 AHKestra 项目的 opencode 工作流中的方案。

**目标**: 使 opencode 在 AHKestra 开发中具备与 Claude Code + ClautoHotkey 同等的 AHK v2 开发智能，同时保持 `src/` 项目不受影响。

**方案**: 完全整合 (Full Integration) — 萃取 ClautoHotkey 核心知识到 AGENTS.md，Claude Code agents 转为 `.opencode/agents/` subagent 模板，ClautoHotkey/ 保留为参考资料库。

## 架构

```
User Request
    │
    ▼
AGENTS.md (根目录)
  ├─ AHKestra 项目信息（现有内容）
  ├─ AHK v2 编码规范（从 ClautoHotkey 萃取）
  │    ├─ 命名与代码风格
  │    ├─ 类模式（构造、继承、meta-functions）
  │    ├─ GUI 开发规范
  │    ├─ 热键与文本引擎规范
  │    ├─ 错误处理模式
  │    └─ 常见反模式表
  ├─ Subagent 路由表
  └─ 引用指引 → ClautoHotkey/ 参考资料库
        │
        ▼
.opencode/agents/  (6 subagent prompt 模板)
  ├─ ahk-version-detector.md
  ├─ ahk-converter-runner.md
  ├─ v1-to-v2-migrator.md
  ├─ gui-builder.md
  ├─ ahk-gui-layout-enforcer.md
  └─ layout.md
```

### 组件职责

| 组件 | 位置 | 职责 |
|------|------|------|
| AGENTS.md | `./AGENTS.md` | 核心规范 + subagent 路由 + 引用指引 |
| Subagent 模板 | `.opencode/agents/*.md` | 可复用的 `task(general)` 调用 prompt |
| ClautoHotkey 参考库 | `ClautoHotkey/` | 完整原始知识库，AGENTS.md 引用至此 |
| opencode 配置 | `opencode.json` | 已有 superpowers 插件配置，无需更改 |

## AGENTS.md 内容规划

### 现有内容（保留）
- AHKestra 项目概述与目录结构
- 构建/运行/测试命令
- 基础代码风格（来自当前 AGENTS.md）

### 新增内容（约 200-300 行）
- **AHK v2 核心原则**: KISS, YAGNI, SRP, SoC
- **命名规范**: PascalCase 类, camelCase 变量, UPPER_SNAKE_CASE 常量, `_` 前缀私有方法
- **类模式**: `Class() → instance` 无 new, `.Bind(this)` 回调, `__New`/`__Delete`, 静态成员
- **GUI 规范**: 数学 Y 定位, 控件生命周期, 暗色主题 (DwmSetWindowAttribute + WM_CTLCOLOR)
- **热键/文本引擎**: `^!+#` 修饰符语法, XHotstring 规则
- **错误处理**: 自定义错误类, try/catch 模式, 链式异常
- **反模式表**: 常见 LLM 陷阱 (避免 JS 污染, 不用 `const/let`, 禁止 `{}` 箭头函数体)
- **Subagent 路由表**: 按任务类型映射到 `.opencode/agents/` 中的模板

## Subagent 转换

| Agent | 用途 | 触发条件 |
|-------|------|----------|
| ahk-version-detector | 扫描 AHK v1 语法 | 处理未知来源的 .ahk 文件时 |
| ahk-converter-runner | 自动化 v1→v2 转换 | 需要批量转换 v1 文件时 |
| v1-to-v2-migrator | 手动迁移辅助 | 复杂迁移需要逐步指导时 |
| gui-builder | GUI 创建 | 创建新 GUI 或修改复杂 GUI 时 |
| ahk-gui-layout-enforcer | 布局数学验证 | GUI 布局出现重叠或错位时 |
| layout | 通用布局执行 | 一般性布局约束实施 |

每个 `.opencode/agents/*.md` 包含:
- **Purpose**: 一句话用途
- **When to use**: 触发条件说明
- **Prompt template**: 可直接用于 `task(general)` 的描述文本
- **Example**: 调用示例

## ClautoHotkey/ 保留策略

- **保持完全原样**，不加 deprecated 标记
- 所有 IDE 特定配置（`.claude/`, `.cursor/`, `.clinerules`, `Cline/`）保留不动，确保与 Claude Code / Cursor 生态兼容
- AGENTS.md 将 ClautoHotkey/ 引用为"深度参考资料库"

## 与 src/ 隔离

| 操作 | 影响 |
|------|------|
| 修改 AGENTS.md | 根目录，不影响 src/ |
| 创建 .opencode/agents/ | 根目录，不影响 src/ |
| ClautoHotkey/ 原样保留 | 已有独立 .git/，不受影响 |
| AHKestra 代码 | **完全不修改** `src/AHKestra/` 及其子目录 |

## 后续步骤

1. 实现方案：增强 AGENTS.md + 创建 `.opencode/agents/` subagent 模板
2. 验证：启动 opencode 会话，测试 AHK v2 开发场景（编写类、GUI、热键等）是否获得正确的规范指导
3. 迭代：根据使用反馈调整 AGENTS.md 的内容深度和 subagent 路由准确性

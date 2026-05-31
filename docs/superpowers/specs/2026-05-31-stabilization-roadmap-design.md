# AHKestra 稳定化与迭代路线图设计

> 日期: 2026-05-31
> 状态: 已批准设计

## 概述

AHKestra 是一个 AutoHotkey v2 上下文感知自动化框架。当前代码库存在约 25+ 个已知问题（其中 12 个阻止启动），同时有一些计划中的功能尚未实现。本文档定义了四阶段渐进式迭代路线图。

## Phase 1: 稳定核心

**目标**: 修复所有阻止启动的 Bug，使应用能正常加载、显示托盘图标并响应配置。

### 1.1 修复 Include 路径 (AHKestra.ahk)

| 行 | 当前（错误） | 改为 |
|---|---|---|
| 27 | `Core\Services\ConfigService.ahk` | `Core\Common\ConfigService.ahk` |
| 28 | `Core\Services\GuiService.ahk` | `Core\Views\GuiService.ahk` |
| 29 | `Core\Services\PluginService.ahk` | `Core\Plugins\PluginService.ahk` |

### 1.2 修复启动流程错误名称

- `ConfigService.RegisterDefaults()` → 移除该调用（配置已有 `_initializeConfigs`）
- `EventService.Init()` → `EventBus.Init()`（或通过 `Events` API 门面）
- `ConditionService.Init()` → `Conditions.Init()`（或直接初始化引擎）
- `MonitorManager.Init()` → `MonitorService._EnsureInitialized()`

### 1.3 修复 API 层

- `Conditions.ahk:1`: `#Include ..\Services\ConditionEngine.ahk` → `#Include ..\Conditions\ConditionEngine.ahk`
- `Events.ahk`: 确认路径正确，添加 `Init()` 静态方法桥接到 EventBus
- `Contexts.ahk`: 确认路径正确，添加 `Init()` 桥接到 ContextService

### 1.4 修复缺失类和变量

- 新建 `Core\Conditions\ICondition.ahk` — 定义条件基类
- `ConditionLoaderService.ahk:42,50`: `_g_CurrentProviderClass` → `_g_CurrentConditionProviderClass`
- `ConditionRegistry.ahk:5`: `providerInstance` → `ProviderClass`

### 1.5 修复插件系统

- `PluginService.ahk:73`: `Api` → `PluginApi`
- `Plugin.ahk`: `EventService.Trigger` → `EventBus.Trigger`
- 全局修复 `Error("msg")` → `throw Error("msg")` 模式（约 10 处）

### 1.6 修复 GUI 和视图

- `TrayMenu.ahk:5`: `SettingsView` → `SettingsGui`
- `GuiService.ahk:34`: 参数顺序 `(options := "", title)` → `(title, options := "")`
- `PluginConfigGuiFactory.ahk`: `GetSchema()` → `GetConfigSchema()`、`EventService` → `EventBus`

### 1.7 修复 TextContextProvider

添加 `GetContextDefinitions()` 方法覆写，返回 `selection` 和 `clipboard` 上下文定义。

### 1.8 文件清单

被修改的文件（约 15 个）:
- `src/AHKestra/AHKestra.ahk`
- `src/AHKestra/Core/Api/Conditions.ahk`
- `src/AHKestra/Core/Api/Events.ahk`
- `src/AHKestra/Core/Api/Contexts.ahk`
- `src/AHKestra/Core/Conditions/ICondition.ahk` (新建)
- `src/AHKestra/Core/Conditions/ConditionLoaderService.ahk`
- `src/AHKestra/Core/Conditions/ConditionRegistry.ahk`
- `src/AHKestra/Core/Plugins/Plugin.ahk`
- `src/AHKestra/Core/Plugins/PluginService.ahk`
- `src/AHKestra/Core/Views/TrayMenu.ahk`
- `src/AHKestra/Core/Views/GuiService.ahk`
- `src/AHKestra/Core/Views/PluginConfigGuiFactory.ahk`
- `src/AHKestra/Core/Contexts/Providers/TextContextProvider.ahk`
- `src/AHKestra/Core/Common/ConfigService.ahk`
- `src/AHKestra/Core/Common/Utils/PersistenceHelper.ahk`
- `src/AHKestra/Core/Managers/HotkeyManager.ahk`

## Phase 2: 完善插件集成

**目标**: 让插件系统能完整注册 event/context/condition provider，补充 OR/NOT 条件，修复条件引擎和菜单逻辑。

### 2.1 补全 PluginService._registerContributions()

当前只处理 `hotkeys`、`menuItems`、`espansions`。需要补充:
- 读取 `pluginDef.providers.events` → 调用 `EventLoaderService.RegisterProvider()`
- 读取 `pluginDef.providers.contexts` → 调用 `ContextLoaderService.RegisterProvider()`
- 读取 `pluginDef.providers.conditions` → 调用 `ConditionLoaderService.RegisterProvider()`

### 2.2 修复 ContextMenuManager 条件逻辑

`BuildAndShowMenu()` 中条件和显隐性逻辑需简化:
- 移除重复的 `Conditions.Check()` 调用（第 55-62 行）
- 通过 `Conditions.Check()` 统一评估入口
- 确保 `ShowItem` 变量正确控制菜单项显隐

### 2.3 创建 ICondition 基类

```ahk
class ICondition {
    static Evaluate(context) {
        throw NotImplementedError("此条件未实现 Evaluate 方法")
    }
}
```

### 2.4 实现 OrCondition 和 NotCondition

- `OrCondition.ahk`: 短路求值，任一条件为真即返回真
- `NotCondition.ahk`: 单子条件求反

### 2.5 文件清单

- `src/AHKestra/Core/Plugins/PluginService.ahk`
- `src/AHKestra/Core/Managers/ContextMenuManager.ahk`
- `src/AHKestra/Core/Conditions/ICondition.ahk` (已在 Phase 1 新建)
- `src/AHKestra/Core/Conditions/Providers/OrCondition.ahk` (新建)
- `src/AHKestra/Core/Conditions/Providers/NotCondition.ahk` (新建)

## Phase 3: 功能补完

**目标**: 实现结构化日志服务、创建样本插件、补全 TextEngineManager 默认加载。

### 3.1 结构化日志服务

按 `docs/superpowers/plans/2026-03-22-structured-logging.md` 实现。

核心接口:
- `LogService.Info(tag, message)`
- `LogService.Warn(tag, message)`
- `LogService.Error(tag, message)`
- `LogService.Debug(tag, message)`
- `LogService.SetLevel(level)` — 支持过滤
- 文件输出到 `%TEMP%\AHKestra\logs\`
- 替换所有 `OutputDebug()` 调用
- `PluginService.Log()` 接入 `LogService`

### 3.2 TextEngineManager.Init() 默认加载

从 `config.json` 读取 `textExpansion` 段，加载 `%A_ScriptDir%\expansion\*.yml` 文件。

### 3.3 样本插件

- **HelloPanel**: 注册 `^!H` 热键、右键菜单项、文本扩展
- **WindowHelper** (可选): 演示 Provider 注册

### 3.4 文件清单

- `src/AHKestra/Core/Common/LogService.ahk` (新建)
- `src/AHKestra/Core/Managers/TextEngineManager.ahk`
- `src/AHKestra/Core/Plugins/PluginService.ahk`
- `src/AHKestra/Plugins/HelloPanel/` (新建目录)
- `src/AHKestra/Plugins/WindowHelper/` (新建目录，可选)

## Phase 4: 质量基建

**目标**: 建立测试框架、API 文档生成、CI/CD 和贡献指南。

### 4.1 测试框架

按 `docs/superpowers/plans/2026-03-22-test-framework.md` 实现。

目录结构:
```
tests/
  TestRunner.ahk       # 测试发现和执行
  Assert.ahk           # 断言工具
  Core/
    ConfigService.test.ahk
    ConditionEngine.test.ahk
    ContextService.test.ahk
    EventBus.test.ahk
```

### 4.2 API 文档生成器

`docs/GenerateAPI.ahk` — 扫描 `Core/Api/` 下各门面类和 Provider 定义，输出 Markdown 到 `docs/api/`。

### 4.3 CI/CD

- `.github/workflows/test.yml`: PR 触发测试
- `.github/workflows/build.yml`: Tag 触发 Ahk2Exe 和 `dotnet build`

### 4.4 CONTRIBUTING.md

开发环境、代码风格、PR 流程、本地验证命令。

### 4.5 文件清单

- `docs/GenerateAPI.ahk`
- `tests/` (新建目录，多个文件)
- `.github/workflows/test.yml` (新建)
- `.github/workflows/build.yml` (新建)
- `CONTRIBUTING.md` (新建)

## 依赖关系

```
Phase 1 (稳定核心)
  └── Phase 2 (插件集成) — 依赖 Phase 1 可运行
       └── Phase 3 (功能补完) — 依赖 Phase 2 可注册插件
            └── Phase 4 (质量基建) — 可与其他阶段部分并行
```

各阶段之间有一定重叠空间，但建议按顺序执行以降低风险。

## 验收标准

- Phase 1: 应用启动无错误，托盘图标显示，设置窗口可打开，主题加载正常
- Phase 2: 插件的 event/context/condition provider 正常注册，条件引擎支持 AND/OR/NOT
- Phase 3: 日志写入文件，样本插件可加载并工作，文本扩展正常
- Phase 4: `dotnet build` 通过，测试运行器可执行，API 文档生成，CI 配置就绪

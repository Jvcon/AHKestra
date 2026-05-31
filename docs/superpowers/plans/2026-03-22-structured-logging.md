# 结构化日志服务实现计划 (修订版)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 `Core/Common/` 下实现 LogService，替换现有 `OutputDebug` 调用和 `PluginService.Log()` 的 TODO，提供统一的结构化日志接口。

**Architecture:** 单文件静态类 LogService 放在 `Core/Common/`，与 ConfigService 同级。LogLevel 枚举、Formatter、Target 作为内部类全部内聚于单文件。遵循 Common/ 模块设计风格（静态类、Init 方法、私有方法 camelCase 前缀下划线）。

**Tech Stack:** AutoHotkey v2, JSON (配置), 文件 I/O

---

## 设计决策

### 为什么放在 `Core/Common/`

- `Common/` 定位是**共享工具/基础设施**，ConfigService、Errors 都在此
- LogService 是横切关注点，所有模块都需要，与 ConfigService 性质相同
- `Infrastructure/` 定位是**系统级底层硬件/OS 交互**（如 MonitorService），日志不属于此类
- 不创建 `Services/`——该目录在框架中不存在，原计划基于已废弃的目录结构

### 单文件 vs 多文件

原计划拆为 4 个文件（LogLevel、LogFormatters、LogTargets、LogService），放在不存在的 `Services/` 目录。修订后合并为单文件 `LogService.ahk`：
- LogLevel 作为 LogService 前置类定义
- Formatter 和 Target 作为独立类定义（同文件内）
- 与 `ConfigService.ahk`（199 行单文件）风格一致
- 后续扩展时再拆分到 `Common/Utils/` 子目录

---

## 文件结构

```
Core/Common/
├── ConfigService.ahk     (已有)
├── Errors.ahk            (已有)
├── LogService.ahk        (新建 - 日志服务)
└── Utils/                (已有)
    ├── JsonTools.ahk
    ├── ManifestsMigration.ahk
    └── PersistenceHelper.ahk
```

### 包含方式

`AHKestra.ahk:21` 已有 `#Include "%A_ScriptDir%\Core\Common"`，该指令自动包含 `Common/` 目录下所有 `.ahk` 文件。**无需在 AHKestra.ahk 中添加额外 #Include。**

---

## 现有 OutputDebug 调用清单

| 文件 | 行号 | 当前代码 | 替换为 |
|------|------|----------|--------|
| `PluginService.ahk` | 172 | `OutputDebug("[" pluginName "][" level "] " message)` | LogService 分发 |
| `ConditionEngine.ahk` | 17 | `OutputDebug("条件评估错误: " e.Message)` | `LogService.Error` |
| `ConditionRegistry.ahk` | 9 | `OutputDebug("警告: 条件 '" name "' 被重复注册。")` | `LogService.Warn` |
| `ConditionLoaderService.ahk` | 47 | `OutputDebug("错误: 加载条件判断提供者...")` | `LogService.Error` |
| `EventLoaderService.ahk` | 62 | `OutputDebug("错误: 加载事件提供者...")` | `LogService.Error` |
| `ContextLoaderService.ahk` | 75 | `OutputDebug("警告: 文件 ... 不是一个有效的上下文提供者。")` | `LogService.Warn` |
| `ContextLoaderService.ahk` | 79 | `OutputDebug("错误: 加载上下文提供者...")` | `LogService.Error` |

**不需要修改的文件：**
- `ConfigService.ahk:136,140` — 其中 `Error()` 是**抛异常**，不是日志输出，语义正确，保持不变
- `PersistenceHelper.ahk:19` — 同理，`Error()` 是抛异常

---

## Task 1: 创建 LogService 核心文件

**Files:**
- Create: `src/AHKestra/Core/Common/LogService.ahk`

- [ ] **Step 1: 创建 LogService.ahk**

单文件包含以下类（按顺序）：

1. **LogLevel** — 日志级别枚举（TRACE=0 ~ FATAL=5），含 `GetName()` 和 `Parse()`
2. **LogFormatter** — 格式化器基类（`NotImplementedError`）
3. **SimpleFormatter** — `[时间] [级别] [来源] 消息`
4. **DetailedFormatter** — 含文件、行号、异常信息
5. **LogTarget** — 输出目标基类，含 `levelThreshold` 和 `ShouldWrite()`
6. **OutputDebugTarget** — 输出到调试器
7. **FileTarget** — 输出到文件，含轮转逻辑
8. **LogService** — 主类：`Init()`, `AddTarget()`, `ClearTargets()`, `Trace/Debug/Info/Warn/Error/Fatal`, 私有 `_log()`, `_applyConfig()`

完整代码见附录 A。

- [ ] **Step 2: 验证包含**

运行: `autohotkey.exe src\AHKestra\AHKestra.ahk`
预期: 无错误启动，托盘图标出现

---

## Task 2: 在 InitApp 中初始化 LogService

**Files:**
- Modify: `src/AHKestra/AHKestra.ahk:66-67`

- [ ] **Step 1: 插入初始化调用**

在 `ConfigService.Load()` (第66行) 之后、`EventLoaderService.LoadCoreProviders()` (第67行) 之前插入：

```ahk
    LogService.Init()
```

- [ ] **Step 2: 验证启动**

运行: `autohotkey.exe src\AHKestra\AHKestra.ahk`
预期: 无错误启动

---

## Task 3: 替换 PluginService.Log 方法

**Files:**
- Modify: `src/AHKestra/Core/Plugins/PluginService.ahk:167-173`

- [ ] **Step 1: 替换 Log 方法**

将含 TODO 注释的现有方法替换为：

```ahk
    /**
     * [API方法] 为插件提供统一的日志记录接口。
     */
    static Log(pluginName, level, message) {
        local logLevel := LogLevel.Parse(level)
        switch logLevel {
            case LogLevel.TRACE: LogService.Trace(pluginName, message)
            case LogLevel.DEBUG: LogService.Debug(pluginName, message)
            case LogLevel.INFO: LogService.Info(pluginName, message)
            case LogLevel.WARN: LogService.Warn(pluginName, message)
            case LogLevel.ERROR: LogService.Error(pluginName, message)
            case LogLevel.FATAL: LogService.Fatal(pluginName, message)
            default: LogService.Info(pluginName, message)
        }
    }
```

- [ ] **Step 2: 验证插件日志集成**

运行: `autohotkey.exe src\AHKestra\AHKestra.ahk`
预期: 插件通过 `api.Info/Warn/Error()` 的调用经由 LogService 输出

---

## Task 4: 替换散落的 OutputDebug 调用

**Files:**
- Modify: 5 个文件，共 6 处

- [ ] **Step 1: ConditionEngine.ahk:17**

```ahk
; 原: OutputDebug("条件评估错误: " . e.Message)
LogService.Error("ConditionEngine", "条件评估错误", e)
```

- [ ] **Step 2: ConditionRegistry.ahk:9**

```ahk
; 原: OutputDebug("警告: 条件 '" . name . "' 被重复注册。")
LogService.Warn("ConditionRegistry", "条件 '" name "' 被重复注册")
```

- [ ] **Step 3: ConditionLoaderService.ahk:47**

```ahk
; 原: OutputDebug("错误: 加载条件判断提供者 " . providerFullPath . " 失败。`n" . e.Message)
LogService.Error("ConditionLoaderService", "加载条件判断提供者 " providerFullPath " 失败", e)
```

- [ ] **Step 4: EventLoaderService.ahk:62**

```ahk
; 原: OutputDebug("错误: 加载事件提供者 " . providerFullPath . " 失败。`n" . e.Message)
LogService.Error("EventLoaderService", "加载事件提供者 " providerFullPath " 失败", e)
```

- [ ] **Step 5: ContextLoaderService.ahk:75**

```ahk
; 原: OutputDebug("警告: 文件 " . providerFullPath . " 不是一个有效的上下文提供者。")
LogService.Warn("ContextLoaderService", "文件 " providerFullPath " 不是一个有效的上下文提供者")
```

- [ ] **Step 6: ContextLoaderService.ahk:79**

```ahk
; 原: OutputDebug("错误: 加载上下文提供者 " . providerFullPath . " 失败。`n" . e.Message)
LogService.Error("ContextLoaderService", "加载上下文提供者 " providerFullPath " 失败", e)
```

- [ ] **Step 7: 验证集成**

运行: `autohotkey.exe src\AHKestra\AHKestra.ahk`
预期: 所有日志通过 LogService 输出到 OutputDebug，无遗留 OutputDebug 直接调用

---

## 完成检查清单

- [ ] `Core/Common/LogService.ahk` 创建完成
- [ ] `InitApp()` 中 LogService 初始化完成
- [ ] `PluginService.Log()` 方法替换完成
- [ ] 6 处 OutputDebug 调用全部替换
- [ ] 应用程序正常启动，日志输出到调试器
- [ ] 插件 API 日志功能正常工作

---

## 后续扩展方向

完成此计划后，可按需扩展：
1. GUI 日志查看器目标（与 SettingsGui 集成）
2. 网络日志输出目标
3. 日志级别运行时动态调整
4. 从配置文件自动加载日志设置（通过 ConfigService 读取 logging 配置项）

---

## 附录 A: LogService.ahk 完整代码

```ahk
; Core/Common/LogService.ahk - 结构化日志服务

#Requires AutoHotkey v2.0

; ==========================================================================
; 日志级别
; ==========================================================================
class LogLevel {
    static TRACE := 0
    static DEBUG := 1
    static INFO := 2
    static WARN := 3
    static ERROR := 4
    static FATAL := 5

    static GetName(level) {
        switch level {
            case this.TRACE: return "TRACE"
            case this.DEBUG: return "DEBUG"
            case this.INFO: return "INFO"
            case this.WARN: return "WARN"
            case this.ERROR: return "ERROR"
            case this.FATAL: return "FATAL"
            default: return "UNKNOWN"
        }
    }

    static Parse(name) {
        switch name {
            case "TRACE": return this.TRACE
            case "DEBUG": return this.DEBUG
            case "INFO": return this.INFO
            case "WARN": return this.WARN
            case "ERROR": return this.ERROR
            case "FATAL": return this.FATAL
            default: return this.INFO
        }
    }
}

; ==========================================================================
; 日志格式化器
; ==========================================================================
class LogFormatter {
    static Format(entry) {
        throw NotImplementedError("LogFormatter.Format 必须由子类实现")
    }
}

class SimpleFormatter extends LogFormatter {
    static Format(entry) {
        return "[" entry.timestamp "] [" entry.level "] [" entry.source "] " entry.message
    }
}

class DetailedFormatter extends LogFormatter {
    static Format(entry) {
        local result := "[" entry.timestamp "] [" entry.level "] [" entry.source "] " entry.message
        if (entry.Has("file") && entry.file != "") {
            result .= " (" entry.file ":" entry.line ")"
        }
        if (entry.Has("exception") && entry.exception != "") {
            result .= "`n异常: " entry.exception
        }
        return result
    }
}

; ==========================================================================
; 日志输出目标
; ==========================================================================
class LogTarget {
    static levelThreshold := LogLevel.TRACE

    static Write(entry) {
        throw NotImplementedError("LogTarget.Write 必须由子类实现")
    }

    static ShouldWrite(entry) {
        return entry.levelValue >= this.levelThreshold
    }
}

class OutputDebugTarget extends LogTarget {
    static Write(entry) {
        if (this.ShouldWrite(entry)) {
            OutputDebug(SimpleFormatter.Format(entry))
        }
    }
}

class FileTarget extends LogTarget {
    static filePath := ""
    static maxFileSize := 10 * 1024 * 1024
    static maxFiles := 5

    static Init(path) {
        this.filePath := path
    }

    static Write(entry) {
        if (this.ShouldWrite(entry) && this.filePath != "") {
            try {
                local logLine := DetailedFormatter.Format(entry) "`n"
                FileAppend(logLine, this.filePath)
                this._rotateIfNeeded()
            } catch Error as e {
                OutputDebug("写入日志文件失败: " e.Message)
            }
        }
    }

    static _rotateIfNeeded() {
        if (!FileExist(this.filePath)) {
            return
        }
        if (FileGetSize(this.filePath) < this.maxFileSize) {
            return
        }
        local oldestFile := this.filePath "." this.maxFiles
        if (FileExist(oldestFile)) {
            FileDelete(oldestFile)
        }
        Loop this.maxFiles - 1 {
            local i := this.maxFiles - A_Index
            local oldFile := this.filePath "." i
            local newFile := this.filePath "." (i + 1)
            if (FileExist(oldFile)) {
                FileMove(oldFile, newFile)
            }
        }
        FileMove(this.filePath, this.filePath ".1")
    }
}

; ==========================================================================
; LogService - 核心日志服务
; ==========================================================================
/**
 * 结构化日志服务 (核心共享工具)
 * 提供统一的日志接口，支持多级别、多目标输出。
 * 替代散落各处的 OutputDebug 调用。
 */
class LogService {
    static _targets := []
    static _initialized := false

    /**
     * 初始化日志服务
     * @param config {Map} [可选] 日志配置，包含 logLevel、logFile 等键
     */
    static Init(config := "") {
        if (this._initialized) {
            return
        }
        this._targets.Push(OutputDebugTarget)
        if (IsObject(config)) {
            this._applyConfig(config)
        }
        this._initialized := true
    }

    /**
     * 添加日志目标
     * @param target {LogTarget} 日志目标
     */
    static AddTarget(target) {
        this._targets.Push(target)
    }

    /**
     * 移除所有目标
     */
    static ClearTargets() {
        this._targets := []
    }

    /**
     * @param source {String} 日志来源
     * @param message {String} 日志消息
     * @param extra {Map} [可选] 额外数据
     */
    static Trace(source, message, extra := "") {
        this._log(LogLevel.TRACE, source, message, extra)
    }

    static Debug(source, message, extra := "") {
        this._log(LogLevel.DEBUG, source, message, extra)
    }

    static Info(source, message, extra := "") {
        this._log(LogLevel.INFO, source, message, extra)
    }

    static Warn(source, message, extra := "") {
        this._log(LogLevel.WARN, source, message, extra)
    }

    /**
     * @param exception {Error} [可选] 异常对象
     */
    static Error(source, message, exception := "", extra := "") {
        local logExtra := extra = "" ? Map() : extra.Clone()
        if (exception != "") {
            logExtra["exception"] := exception.Message
            logExtra["stackTrace"] := exception.Stack
        }
        this._log(LogLevel.ERROR, source, message, logExtra)
    }

    static Fatal(source, message, exception := "", extra := "") {
        local logExtra := extra = "" ? Map() : extra.Clone()
        if (exception != "") {
            logExtra["exception"] := exception.Message
            logExtra["stackTrace"] := exception.Stack
        }
        this._log(LogLevel.FATAL, source, message, logExtra)
    }

    static _log(levelValue, source, message, extra := "") {
        local entry := Map(
            "timestamp", FormatTime(, "yyyy-MM-dd HH:mm:ss"),
            "level", LogLevel.GetName(levelValue),
            "levelValue", levelValue,
            "source", source,
            "message", message
        )
        if (extra != "" && IsObject(extra)) {
            for key, value in extra {
                entry[key] := value
            }
        }
        for target in this._targets {
            try {
                target.Write(entry)
            } catch Error as e {
                OutputDebug("日志目标写入失败: " e.Message)
            }
        }
    }

    static _applyConfig(config) {
        if (config.Has("logLevel")) {
            local level := LogLevel.Parse(config.logLevel)
            for target in this._targets {
                target.levelThreshold := level
            }
        }
        if (config.Has("logFile")) {
            local fileTarget := FileTarget
            fileTarget.Init(config.logFile)
            this.AddTarget(fileTarget)
        }
    }
}
```

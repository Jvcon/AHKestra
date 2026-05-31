# Phase 1: 稳定核心 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all ~12 blocking bugs in AHKestra so the application can start, display tray icon, and respond to configuration.

**Approach:** Fix include paths → fix startup flow → fix condition system → fix plugin system → fix GUI → fix error handling. Each task produces independently testable changes.

**Core files modified:** 15 files, 1 new file (`ICondition.ahk`)

---

### Task 1: Fix include paths in AHKestra.ahk

**Files:**
- Modify: `src/AHKestra/AHKestra.ahk:27-29`

- [ ] **Step 1: Fix the three wrong include paths**

Current lines 27-29:
```ahk
#Include %A_ScriptDir%\Core\Services\ConfigService.ahk
#Include %A_ScriptDir%\Core\Services\GuiService.ahk
#Include %A_ScriptDir%\Core\Services\PluginService.ahk
```

Replace with correct paths:
```ahk
#Include %A_ScriptDir%\Core\Common\ConfigService.ahk
#Include %A_ScriptDir%\Core\Views\GuiService.ahk
#Include %A_ScriptDir%\Core\Plugins\PluginService.ahk
```

Also fix line 18 (typo):
Current: `global APP_THEMES_DIR := A_ScriptDir . "\Assests\Themes"`
Replace: `global APP_THEMES_DIR := A_ScriptDir . "\Assets\Themes"`

Also add missing `#Include` for three utility classes used by ConfigService at runtime (currently in `Core\Common\Utils\` subdirectory, not reached by directory include):

After line 29 (or after the PluginService include), add:
```ahk
#Include %A_ScriptDir%\Core\Common\Utils\PersistenceHelper.ahk
#Include %A_ScriptDir%\Core\Common\Utils\JsonTools.ahk
#Include %A_ScriptDir%\Core\Common\Utils\ManifestsMigration.ahk
```

- [ ] **Step 2: Review the changes**

```bash
git diff src/AHKestra/AHKestra.ahk
```
Expected: Three corrected paths + one Assets path fix.

---

### Task 2: Fix InitApp() references and add RegisterDefaults to ConfigService

**Files:**
- Modify: `src/AHKestra/AHKestra.ahk:61-74`
- Modify: `src/AHKestra/Core/Common/ConfigService.ahk:22-28` (Init method)

- [ ] **Step 1: Replace broken InitApp() flow**

Replace lines 65-82 in `AHKestra.ahk` (from `ConfigService.Load()` through `TextEngineManager.Init()`):

```ahk
    ; 加载配置
    ConfigService.Load()
    EventLoaderService.LoadCoreProviders()


    EventService.Init()
    ConditionService.Init()
    GuiService.Init()

    MonitorManager.Init()

    ; 加载插件
    PluginService.LoadPlugins()


    HotkeyManager.Init()
    ContextMenuManager.Init()
    TextEngineManager.Init()
```

With:

```ahk
    ; 加载配置
    ConfigService.Init()

    ; 加载核心事件提供者
    EventLoaderService.LoadCoreProviders()

    ; 初始化各模块
    Events.Init()
    Conditions.Init()
    GuiService.Init()

    ; 初始化硬件服务（惰性初始化入口）
    MonitorService._EnsureInitialized()

    ; 加载插件
    PluginService.Init()

    ; 初始化管理器
    HotkeyManager.Init()
    ContextMenuManager.Init()
    TextEngineManager.Init()
```

- [ ] **Step 2: Add RegisterDefaults method to ConfigService**

`_initializeConfigs()` builds defaults by iterating `_configSchemas[name].properties`. So `RegisterDefaults` must populate `_configSchemas` in that format.

After the `Init()` method in `ConfigService.ahk`, add:

```ahk
    static RegisterDefaults(scope, defaults) {
        local props := Map()
        for key, value in defaults {
            props[key] := Map("default", value)
        }
        this._configSchemas[scope] := Map("properties", props)
    }
```

Then in `InitApp()`, replace the three broken `RegisterDefaults` calls with:

```ahk
    ; 注册框架模块默认配置 (must be before ConfigService.Init() to feed _initializeConfigs)
    ConfigService.RegisterDefaults("GuiService", Map("activeTheme", defaultThemeName))
    ConfigService.RegisterDefaults("HotkeyManager", Map("leaderKey", defaultLeaderKey, "timeout", 1000))
    ConfigService.RegisterDefaults("ContextMenuManager", Map("menuKey", defaultMenuKey))
```

- [ ] **Step 3: Fix ConfigService._loadAllPluginManifests() Error calls**

Replace `Error("插件 Manifest 无效...")` on line 136 with `throw Error("插件 Manifest 无效...")`
Replace `Error("加载插件时发生严重错误...")` on line 140 with `throw Error("加载插件时发生严重错误...")`

- [ ] **Step 4: Fix ConfigService.SetPluginStatus() Error call**

Replace `Error("保存插件状态失败...")` on line 88 with `throw Error("保存插件状态失败...")`

---

### Task 3: Fix API facades (Conditions.ahk, Events.ahk, Contexts.ahk)

**Files:**
- Modify: `src/AHKestra/Core/Api/Conditions.ahk:1`
- Modify: `src/AHKestra/Core/Api/Events.ahk` (add Init)
- Modify: `src/AHKestra/Core/Api/Contexts.ahk` (add Init)

- [ ] **Step 1: Fix Conditions.ahk include path**

Line 1: `#Include %A_ScriptDir%\..\Services\ConditionEngine.ahk`
Replace with: `#Include %A_ScriptDir%\..\Conditions\ConditionEngine.ahk`

Add `Init()` method:
```ahk
    static Init() {
        ConditionLoaderService.LoadCoreProviders()
    }
```

- [ ] **Step 2: Add Init() to Events.ahk**

After `class Events {`, add:
```ahk
    static Init() {
        ; EventBus requires no explicit init; core providers loaded by EventLoaderService
    }
```

- [ ] **Step 3: Add Init() to Contexts.ahk**

After `class Contexts {`, add:
```ahk
    static Init() {
        ContextLoaderService.LoadCoreProviders()
    }
```

---

### Task 4: Create ICondition.ahk and fix condition system bugs

**Files:**
- Create: `src/AHKestra/Core/Conditions/ICondition.ahk`
- Modify: `src/AHKestra/Core/Conditions/ConditionLoaderService.ahk:42,50`
- Modify: `src/AHKestra/Core/Conditions/ConditionRegistry.ahk:5`

- [ ] **Step 1: Create ICondition.ahk**

New file `src/AHKestra/Core/Conditions/ICondition.ahk`:

```ahk
class ICondition {
    static Evaluate(context) {
        throw NotImplementedError("此条件未实现 Evaluate 方法")
    }
}
```

- [ ] **Step 2: Fix ConditionLoaderService.ahk variable name**

Line 42: `local providerInstance := _g_CurrentProviderClass()`
Replace with: `local providerInstance := _g_CurrentConditionProviderClass()`

Line 50: `_g_CurrentProviderClass := ""`
Replace with: `_g_CurrentConditionProviderClass := ""`

- [ ] **Step 3: Fix ConditionRegistry.ahk parameter usage**

Line 5: `local definitions := providerInstance.GetConditionDefinitions()`

The parameter is `ProviderClass` but the code uses `providerInstance`. Fix:
```ahk
    static Register(ProviderClass) {
        local definitions := ProviderClass.GetConditionDefinitions()
```

And line 13: `def.providerInstance := providerInstance`
Replace with: `def.providerInstance := ProviderClass`

---

### Task 5: Fix Plugin system (Plugin.ahk, PluginService.ahk)

**Files:**
- Modify: `src/AHKestra/Core/Plugins/Plugin.ahk`
- Modify: `src/AHKestra/Core/Plugins/PluginService.ahk`

- [ ] **Step 1: Fix Plugin.ahk**

Line 23: `EventService.Trigger("Plugin.Enabled", this.info.name)`
Replace with: `EventBus.Trigger("Plugin.Enabled", this.info.name)`

Line 26: `Error("启用插件 " . this.info.name . " 失败: " . Error.Message)`
Replace with: `throw Error("启用插件 " . this.info.name . " 失败: " . Error.Message)`

Line 41: `EventService.Trigger("Plugin.Disabled", this.info.name)`
Replace with: `EventBus.Trigger("Plugin.Disabled", this.info.name)`

Line 44: `Error("停用插件 " . this.info.name . " 失败: " . Error.Message)`
Replace with: `throw Error("停用插件 " . this.info.name . " 失败: " . Error.Message)`

- [ ] **Step 2: Fix PluginService.ahk**

Line 73: `local api := Api(pluginDef.info)`
Replace with: `local api := PluginApi(pluginDef.info)`

Line 80: `Error("加载插件 '" . pluginName . "' 失败: " . e.Message)`
Replace with: `throw Error("加载插件 '" . pluginName . "' 失败: " . e.Message)`

Line 112: `throw Error(...)` — already correct (has `throw`)

Line 128: `throw Error(...)` — already correct

Line 135: `throw Error(...)` — already correct

Line 150: `Error("插件 '" . pluginName . "' 中声明的Espanso配置文件未找到: " . fullPath)`
Replace with: `throw Error("插件 '" . pluginName . "' 中声明的Espanso配置文件未找到: " . fullPath)`

---

### Task 6: Fix GUI files

**Files:**
- Modify: `src/AHKestra/Core/Views/TrayMenu.ahk:5`
- Modify: `src/AHKestra/Core/Views/GuiService.ahk:34`
- Modify: `src/AHKestra/Core/Views/PluginConfigGuiFactory.ahk:19,24,104,107`

- [ ] **Step 1: Fix TrayMenu.ahk**

Line 5: `tray.Add("Settings...", (*) => SettingsView.Show())`
Replace with: `tray.Add("Settings...", (*) => SettingsGui.Show())`

- [ ] **Step 2: Fix GuiService.ahk parameter order**

Line 34: `static CreateThemedWindow(options := "", title) {`
Replace with: `static CreateThemedWindow(title, options := "") {`

Line 36: `local activeThemeName := ConfigService.Get("GuiService.settings.activeTheme")`
This is a dotted-string key. ConfigService.Get() expects (pluginName, key) as two args. Fix:
```
local activeThemeName := ConfigService.GetConfig("GuiService", "activeTheme")
if !activeThemeName
    activeThemeName := this._defaultThemeName
```

- [ ] **Step 3: Update all CreateThemedWindow callers (parameter order swap)**

All 4 callers pass `(options, title)` — need to swap to `(title, options)`:

**SettingsGui.ahk:21**
Current: `GuiService.CreateThemedWindow("+Resize", "AHKestra - Settings")`
Replace: `GuiService.CreateThemedWindow("AHKestra - Settings", "+Resize")`

**KeystrokeDisplayGUI.ahk:11**
Current: `GuiService.CreateThemedWindow("+AlwaysOnTop -Caption +ToolWindow", "KeystrokeDisplay")`
Replace: `GuiService.CreateThemedWindow("KeystrokeDisplay", "+AlwaysOnTop -Caption +ToolWindow")`

**ModeIndicatorGUI.ahk:13**
Current: `GuiService.CreateThemedWindow("+AlwaysOnTop -Caption +ToolWindow", "ModeIndicator")`
Replace: `GuiService.CreateThemedWindow("ModeIndicator", "+AlwaysOnTop -Caption +ToolWindow")`

**PluginConfigGuiFactory.ahk:29**
Current: `GuiService.CreateThemedWindow(options, pluginName . " - Configuration")`
Replace: `GuiService.CreateThemedWindow(pluginName . " - Configuration", options)`

- [ ] **Step 4: Fix PluginConfigGuiFactory.ahk**

Line 19: `local schema := ConfigService.GetSchema()[pluginName].settings`
Replace with: `local schema := ConfigService.GetConfigSchema(pluginName)`
Then update the check below: `if (!IsObject(schema) || schema.Count = 0)`

Line 24: `local currentConfig := ConfigService.GetCurrentConfig()[pluginName].settings`
Replace with:
```
local currentConfig := Map()
for key, item in schema {
    currentConfig[key] := ConfigService.GetConfig(pluginName, key)
}
```

Line 104: `ConfigService.Set(pluginName . ".settings." . key, newValue)`
Replace with: `ConfigService.SetConfig(pluginName, key, newValue)`

Line 107: `EventService.Trigger("Config.Changed", { plugin: pluginName })`
Replace with: `EventBus.Trigger("Config.Changed", { plugin: pluginName })`

---

### Task 7: Fix TextContextProvider.ahk — add GetContextDefinitions()

**Files:**
- Modify: `src/AHKestra/Core/Contexts/Providers/TextContextProvider.ahk`

- [ ] **Step 1: Add GetContextDefinitions() override**

Before the class-ending line, add:
```ahk
    static GetContextDefinitions() {
        local defs := Map()
        defs["selection"] := { desc: "当前选中的文本", return_type: "String", layer: "active" }
        defs["clipboard"] := { desc: "剪贴板内容", return_type: "String", layer: "active" }
        return defs
    }
```

---

### Task 8: Fix bare Error() calls across the codebase

**Files:**
- Modify: `src/AHKestra/Core/Common/Utils/PersistenceHelper.ahk:19,36`

- [ ] **Step 1: Fix PersistenceHelper.ahk**

Line 19: `Error("读取或解析JSON文件失败...")`
Replace with: `throw Error("读取或解析JSON文件失败: " . filePath . "`n" . e.Message)`
(Note: move the Return Map() after the throw; since throw exits, this is fine)

Line 36: `Error("写入JSON文件失败...")`
Replace with: `throw Error("写入JSON文件失败: " . filePath . "`n" . e.Message)`

- [ ] **Step 2: Fix HotkeyManager.ahk**

Let me check line 317:
```ahk
Error("执行回调时出错: " . e.Message, -1, e)
```
Replace with:
```ahk
throw Error("执行回调时出错: " . e.Message, -1, e)
```

- [ ] **Step 3: Verify no remaining bare Error() calls**

Search for standalone `Error(` that isn't `throw Error(` or `NotImplementedError`:
```bash
rg "(?<!throw\s|NotImplemented)Error\(" --type-add "ahk:*.ahk" -t ahk
```
Expected: No results (or only valid NotImplementedError patterns).

---

## Verification

After all tasks complete:

- [ ] Run the application: `autohotkey.exe src\AHKestra\AHKestra.ahk`
  - Expected: No script errors. Tray icon appears.
- [ ] Click tray "Settings..." — SettingsGui window opens with correct theming
- [ ] Verify Plugins directory loading (even if no plugins exist)
- [ ] Verify C# DLL compilation: `dotnet build src\AHKestra.Tools.Json -c Release`
  - Expected: Build succeeds

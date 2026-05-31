# Phase 2: 完善插件集成 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete plugin provider registration (events/contexts/conditions), add OR/NOT condition operators, fix ContextMenuManager condition logic, fix ConditionEngine operator resolution.

**Architecture changes:**
- `ConditionRegistry` gains operator registration (`RegisterOperator`, `GetOperator`) separate from provider definitions
- `ConditionEngine.BuildTree()` uses `GetOperator()` for AND/OR/NOT instead of `Get()` (which doesn't exist)
- `PluginService._registerContributions()` registers event/context/condition providers from manifests
- `ContextMenuManager.BuildAndShowMenu()` condition check simplified

**Files modified:** 7 files, 2 new files

---

### Task 1: Fix ContextMenuManager condition logic

**Files:**
- Modify: `src/AHKestra/Core/Managers/ContextMenuManager.ahk:55-62`

**Problem:** Lines 55-62 have redundant and inverted condition logic:
```ahk
local showItem := true
if Conditions.Check(itemDef.condition, context) {  ; Checks via ConditionEngine
    try {
        showItem := itemDef.condition(context)       ; Then checks AGAIN via direct function call
    } catch {
        showItem := false
    }
}
```

Additionally, `itemDef.condition` is a function reference passed during `Register()`. When no condition is set, it's `""`. Calling a non-function as a function would crash.

- [ ] **Step 1: Simplify condition check**

Replace lines 55-62 with:
```ahk
            local showItem := false
            if (IsObject(itemDef.condition)) {
                try {
                    showItem := itemDef.condition(context)
                } catch {
                    showItem := false
                }
            } else {
                showItem := true
            }
```

Logic: If no condition function is set, the item is always visible. If a condition function is set, evaluate it safely with try/catch.

---

### Task 2: Add operator registration to ConditionRegistry

**Files:**
- Modify: `src/AHKestra/Core/Conditions/ConditionRegistry.ahk`

**Problem:** `ConditionEngine.BuildTree()` calls `ConditionRegistry.Get(type)` for AND/OR/NOT, but this method doesn't exist. Also, `AndCondition` extends `ICondition` (not `IConditionProvider`), so it's never registered through the provider loader.

- [ ] **Step 1: Add operator registration methods**

Add to `ConditionRegistry` class:
```ahk
    static _operators := Map()

    static RegisterOperator(type, ConditionClass) {
        this._operators[type] := ConditionClass
    }

    static GetOperator(type) {
        return this._operators.Has(type) ? this._operators[type] : ""
    }
```

---

### Task 3: Fix ConditionEngine.BuildTree() operator lookup

**Files:**
- Modify: `src/AHKestra/Core/Conditions/ConditionEngine.ahk:36,47`

**Problem:** Lines 36 and 47 call `ConditionRegistry.Get(type)` which doesn't exist. Should use `ConditionRegistry.GetOperator(type)`.

- [ ] **Step 1: Fix AND/OR lookup**

Line 36: `local ConditionClass := ConditionRegistry.Get(type)`
Replace with: `local ConditionClass := ConditionRegistry.GetOperator(type)`

- [ ] **Step 2: Fix NOT lookup**

Line 47: `local ConditionClass := ConditionRegistry.Get(type)`
Replace with: `local ConditionClass := ConditionRegistry.GetOperator(type)`

---

### Task 4: Create OrCondition.ahk

**Files:**
- Create: `src/AHKestra/Core/Conditions/Providers/OrCondition.ahk`

- [ ] **Step 1: Create OrCondition file**

```ahk
#Include %A_ScriptDir%\..\ICondition.ahk

class OrCondition extends ICondition {
    _conditions := []

    __New(conditionObjects) {
        this._conditions := conditionObjects
    }

    Evaluate(context) {
        for condition in this._conditions {
            if (condition.Evaluate(context)) {
                return true
            }
        }
        return false
    }
}
```

Note: No `global _g_CurrentConditionProviderClass` because OrCondition is a logical operator (ICondition), not a provider (IConditionProvider). It's registered via `ConditionRegistry.RegisterOperator()`.

---

### Task 5: Create NotCondition.ahk

**Files:**
- Create: `src/AHKestra/Core/Conditions/Providers/NotCondition.ahk`

- [ ] **Step 1: Create NotCondition file**

```ahk
#Include %A_ScriptDir%\..\ICondition.ahk

class NotCondition extends ICondition {
    _condition := ""

    __New(conditionObject) {
        this._condition := conditionObject
    }

    Evaluate(context) {
        return !this._condition.Evaluate(context)
    }
}
```

---

### Task 6: Register AND/OR/NOT operators

**Files:**
- Modify: `src/AHKestra/Core/Api/Conditions.ahk`

- [ ] **Step 1: Register operators in Conditions.Init()**

Update `Conditions.Init()` to register logical operators:
```ahk
    static Init() {
        ConditionLoaderService.LoadCoreProviders()
        ConditionRegistry.RegisterOperator("AND", AndCondition)
        ConditionRegistry.RegisterOperator("OR", OrCondition)
        ConditionRegistry.RegisterOperator("NOT", NotCondition)
    }
```

---

### Task 7: Complete PluginService provider registration

**Files:**
- Modify: `src/AHKestra/Core/Plugins/PluginService.ahk:102-154`

**Problem:** `_registerContributions()` handles `hotkeys`, `menuItems`, and `espansions` but skips `events`, `contexts`, and `conditions` providers.

- [ ] **Step 1: Add event provider registration**

After the espansions block, add:
```ahk
        ; --- 注册事件提供者 ---
        if (pluginDef.Has("events")) {
            for _, eventDef in pluginDef.events {
                local fullPath := pluginInfo.dir . "\" . eventDef.path
                if (FileExist(fullPath)) {
                    EventLoaderService.LoadProviderFile(fullPath, pluginName)
                }
            }
        }
```

- [ ] **Step 2: Add context provider registration**

```ahk
        ; --- 注册上下文提供者 ---
        if (pluginDef.Has("contexts")) {
            for _, ctxDef in pluginDef.contexts {
                local fullPath := pluginInfo.dir . "\" . ctxDef.path
                if (FileExist(fullPath)) {
                    ContextLoaderService._LoadProviderFile(fullPath)
                }
            }
        }
```

- [ ] **Step 3: Add condition provider registration**

```ahk
        ; --- 注册条件提供者 ---
        if (pluginDef.Has("conditions")) {
            for _, condDef in pluginDef.conditions {
                local fullPath := pluginInfo.dir . "\" . condDef.path
                if (FileExist(fullPath)) {
                    ConditionLoaderService.LoadProviderFile(fullPath, pluginName)
                }
            }
        }
```

---

## Verification

- [ ] Review all changes for AHK v2 syntax correctness
- [ ] Check that `ContextMenuManager` no longer double-evaluates conditions
- [ ] Verify `ConditionRegistry` has both `GetOperator()` and `GetDefinition()` working independently
- [ ] Confirm `ConditionEngine.BuildTree()` resolves AND/OR/NOT via operators, terminal conditions via definitions

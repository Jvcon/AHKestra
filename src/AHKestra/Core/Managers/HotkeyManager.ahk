#Requires AutoHotkey v2.0
#Include %A_ScriptDir%\Core\Views\ModeIndicatorGUI.ahk
#Include %A_ScriptDir%\Core\Views\KeystrokeDisplayGUI.ahk

/**
 * HotkeyManager (核心服务)
 * 负责注册、管理和分发所有类型的热键（常规、分层、序列）。
 * 它封装了复杂的InputHook和状态管理逻辑，为框架提供统一的热键功能。
 */
class HotkeyManager {

    ; ======================================================================
    ; I. 静态属性 (Static Properties)
    ; ======================================================================
    static Hotkeys := Map()          ; 'keys' => [def, ...]
    static LayeredHotkeys := Map()   ; 'activator' => {'action' => [def, ...]}
    static HotkeyTree := Map()       ; 用于序列热键的树形结构
    static Modes := Map()            ; 'modeName' => {options}

    static leaderKey := ""
    static CurrentMode := "NORMAL"
    static ActiveLayers := Map()

    static SequenceHook := ""
    static SequenceBuffer := ""
    static _isSequenceTimeoutActive := false
    static _boundSequenceTimeoutFunc := "" 


    ; ======================================================================
    ; II. 公共API - 生命周期 (Public API - Lifecycle)
    ; ======================================================================

    /**
     * 初始化管理器，设置钩子和 Leader 键。由框架在启动时调用。
     */
    static Init() {
        this.leaderKey := ConfigService.Get("HotkeyManager.settings.leaderKey")
        ModeIndicatorGUI.Init()
        KeystrokeDisplayGUI.Init()
        this.SequenceHook := InputHook("V T5", "{All}")
        this.SequenceHook.OnEnd := this._onSequenceEnd.Bind(this)
        this.SequenceHook.OnChar := this._onSequenceChar.Bind(this)
        this.SequenceHook.KeyOpt("{All}", "N")

        this._boundSequenceTimeoutFunc := this._sequenceTimeout.Bind(this)

        try {
            Hotkey this.leaderKey, (*) => this._startSequence()
        } catch Error as e {
            MsgBox "无法注册 Leader 键: " this.leaderKey ".`n请检查按键名称是否有效。`n" e.Message
        }
    }

    /**
     * 注册一个热键定义。由 PluginService 调用。
     * @param pluginName {String} 提供此热键的插件名称。
     * @param hotkeyDef {Map} 完整的热键定义对象。
     */
    static Register(pluginName, hotkeyDef) {
        hotkeyDef.plugin := pluginName
        try {
            switch hotkeyDef.type {
                case "regular":
                    local keyStr := hotkeyDef.keys
                    if !this.Hotkeys.Has(keyStr) {
                        this.Hotkeys[keyStr] := []
                        Hotkey keyStr, (*) => this._handleHotkeyDispatch(keyStr)
                    }
                    this.Hotkeys[keyStr].Push(hotkeyDef)
                case "layer":
                    local activator := hotkeyDef.keys[1], actionKey := hotkeyDef.keys[2]
                    if !this.LayeredHotkeys.Has(activator) {
                        this.LayeredHotkeys[activator] := Map()
                        Hotkey "~" . activator, (*) => this._onLayerDown(activator), "On"
                        Hotkey activator . " Up", (*) => this._onLayerUp(activator), "On"
                    }
                    if !this.LayeredHotkeys[activator].Has(actionKey) {
                        this.LayeredHotkeys[activator][actionKey] := []
                    }
                    this.LayeredHotkeys[activator][actionKey].Push(hotkeyDef)
                case "sequence":
                    if (hotkeyDef.keys[1] != this.leaderKey) {
                        throw ValueError("序列热键必须以配置的 Leader 键 (" . this.leaderKey . ") 开头。")
                    }
                    this._addSequenceToTree(hotkeyDef)
            }
        } catch Error as e {
            throw Error("热键注册失败: " . (hotkeyDef.keys.Join ? hotkeyDef.keys.Join("") : hotkeyDef.keys), -1, e)
        }
    }

    /**
     * 注销一个插件贡献的所有热键。由 PluginService 调用。
     * @param pluginName {String} 要注销其热键的插件名称。
     */
    static Unregister(pluginName) {
        this._unregisterRegular(pluginName)
        this._unregisterLayered(pluginName)
        this._unregisterSequence(pluginName)
    }


    ; ======================================================================
    ; III. 公共API - 功能 (Public API - Features)
    ; ======================================================================

    /**
     * 定义一个可用的模式及其UI表现。
     * @param name {String} 模式的名称 (e.g., "INSERT", "COMMAND")。
     * @param options {Map} 模式的选项，如 {text, bgColor, textColor, timeout}。
     */
    static DefineMode(name, options) {
        this.Modes[name] := options
    }

    /**
     * 设置并显示当前的活动模式。
     * @param name {String} 要设置的模式名称。
     * @param position {Map} (可选) {x, y} 显示位置。
     */
    static SetMode(name, position := unset) {
        this.CurrentMode := name
        if this.Modes.Has(name) {
            ModeIndicatorGUI.Show(this.Modes[name], position)
        }
    }


    ; ======================================================================
    ; IV. 公共API - 数据查询 (Public API - Data Access)
    ; ======================================================================

    /** 获取所有已注册的【常规】热键。供 SettingsGui 使用。 */
    static GetRegularHotkeys() {
        local results := []
        for _, defs in this.Hotkeys {
            for def in defs {
                results.Push(def.Clone())
            }
        }
        return results
    }

    /** 获取所有已注册的【分层】热键。供 SettingsGui 使用。 */
    static GetLayeredHotkeys() {
        local results := []
        for _, activatorMap in this.LayeredHotkeys {
            for _, defs in activatorMap {
                for def in defs {
                    results.Push(def.Clone())
                }
            }
        }
        return results
    }

    /** 获取所有已注册的【序列】热键。供 SettingsGui 使用。 */
    static GetSequenceHotkeys() {
        local results := []
        local allDefs := this._getAllSequenceDefs()
        for def in allDefs {
            local displayDef := def.Clone()
            displayDef.keys.RemoveAt(1)
            results.Push(displayDef)
        }
        return results
    }


    ; ======================================================================
    ; V. 内部实现 - 事件处理与分发 (Internal Implementation)
    ; ======================================================================

    static _handleHotkeyDispatch(keyStr) {
        local context := ContextService.GetContext()
        if this.Hotkeys.Has(keyStr) {
            for def in this.Hotkeys[keyStr] {
                if Conditions.Check(def.condition, context) {
                    this._executeCallback(def, context)
                    return
                }
            }
        }
    }

    static _handleLayeredDispatch(keyPath) {
        local parts := StrSplit(keyPath, ">"), activator := parts[1], actionKey := parts[2]
        local context := ContextService.GetContext()
        if this.LayeredHotkeys.Has(activator) && this.LayeredHotkeys[activator].Has(actionKey) {
            for def in this.LayeredHotkeys[activator][actionKey] {
                if Conditions.Check(def.condition, context) {
                    this._executeCallback(def, context)
                    return
                }
            }
        }
    }

    static _onLayerDown(activator) {
        this.ActiveLayers[activator] := true
        this.SetMode("WINDOW")
        KeystrokeDisplayGUI.Show(activator . "+")
        if this.LayeredHotkeys.Has(activator) {
            for actionKey, defList in this.LayeredHotkeys[activator] {
                local keyPath := activator . ">" . actionKey
                Hotkey actionKey, (*) => this._handleLayeredDispatch(keyPath), "On"
            }
        }
    }

    static _onLayerUp(activator) {
        this.ActiveLayers[activator] := false
        this.SetMode("NORMAL")
        KeystrokeDisplayGUI.Show("")
        if this.LayeredHotkeys.Has(activator) {
            for actionKey, def in this.LayeredHotkeys[activator] {
                Hotkey actionKey, , "Off"
            }
        }
    }

    static _startSequence() {
        this.SequenceBuffer := this.leaderKey
        this.SequenceHook.Start()
        SetTimer(this._boundSequenceTimeoutFunc, -5000)
        this._isSequenceTimeoutActive := true
        this._updateSequenceDisplay()
    }

    static _onSequenceChar(hook, char) {
        this.SequenceBuffer .= char
        if (this._isSequenceTimeoutActive) {
            SetTimer(this._boundSequenceTimeoutFunc, -5000)
        }
        this._updateSequenceDisplay()
    }

    static _onSequenceEnd(hook, endReason) {
        if (this._isSequenceTimeoutActive) {
            SetTimer(this._boundSequenceTimeoutFunc, "Off")
            this._isSequenceTimeoutActive := false
        }
        this.SequenceBuffer := ""
        KeystrokeDisplayGUI.Hide()
    }

    static _sequenceTimeout() {
        this._isSequenceTimeoutActive := false
        this.SequenceHook.Stop()
    }


    ; ======================================================================
    ; VI. 内部实现 - 核心逻辑 (Internal Implementation)
    ; ======================================================================

    static _updateSequenceDisplay() {
        local context := ContextService.GetContext()
        local currentNode := this.HotkeyTree
        try {
            for key in StrSplit(this.SequenceBuffer) {
                currentNode := currentNode[key]
            }
        } catch {
            this.SequenceHook.Stop()
            return
        }

        if (currentNode.Has("_def")) {
            for def in currentNode["_def"] {
                if Conditions.Check(def, context) {
                    this.SequenceHook.Stop()
                    this._executeCallback(def, context)
                    return
                }
            }
        }

        local possibleNext := []
        for key, node in currentNode {
            if (key != "_def") {
                local hint := "", isActionable := false
                if (node.Has("_def")) {
                    for def in node["_def"] {
                        if Conditions.Check(def, context) {
                            hint := def.hint
                            isActionable := true
                            break
                        }
                    }
                }
                if (isActionable) {
                    possibleNext.Push({ key: key, hint: hint })
                }
            }
        }
        if (possibleNext.Length > 0) {
            KeystrokeDisplayGUI.Show(this.SequenceBuffer, possibleNext)
        } else {
            this.SequenceHook.Stop()
        }
    }

    static _executeCallback(hotkeyInfo, context) {
        if !IsObject(hotkeyInfo) {
            return
        }
        try {
            if (hotkeyInfo.type != "sequence") {
                local text := this._formatKeystroke(hotkeyInfo)
                KeystrokeDisplayGUI.Show(text)
                SetTimer () => KeystrokeDisplayGUI.Hide(""), -1000
            }
            hotkeyInfo.callback(context)
        } catch Error as e {
            Error("执行回调时出错: " . e.Message, -1, e)
        }
    }


    ; ======================================================================
    ; VII. 内部实现 - 数据结构操作 (Internal Implementation)
    ; ======================================================================

    static _addSequenceToTree(def) {
        local currentNode := this.HotkeyTree
        for key in def.keys {
            if !currentNode.Has(key) {
                currentNode[key] := Map()
            }
            currentNode := currentNode[key]
        }
        if !currentNode.Has("_def") {
            currentNode["_def"] := []
        }
        currentNode["_def"].Push(def)
    }

    static _getAllSequenceDefs() {
        local allDefs := []
        _traverse(node) {
            if (node.Has("_def"))
                allDefs.Push(node["_def"]*)
            for key, subNode in node {
                if (key != "_def")
                    _traverse(subNode)
            }
        }
        _traverse(this.HotkeyTree)
        return allDefs
    }

    static _unregisterRegular(pluginName) {
        local keysToReEvaluate := Map()
        for keyStr, definitions in this.Hotkeys {
            loop definitions.Length {
                local index := definitions.Length - A_Index + 1
                if (definitions[index].plugin == pluginName) {
                    definitions.RemoveAt(index)
                    keysToReEvaluate.Push(keyStr)
                }
            }
        }
        for keyStr in keysToReEvaluate {
            if (this.Hotkeys.Has(keyStr) && this.Hotkeys[keyStr].Length == 0) {
                Hotkey keyStr, , "Off"
                this.Hotkeys.Delete(keyStr)
            }
        }
    }

    static _unregisterLayered(pluginName) {
        local activatorsToReEvaluate := Map()
        for activator, actionMap in this.LayeredHotkeys {
            for actionKey, definitions in actionMap {
                loop definitions.Length {
                    local index := definitions.Length - A_Index + 1
                    if (definitions[index].plugin == pluginName) {
                        definitions.RemoveAt(index)
                        activatorsToReEvaluate.Push(activator)
                    }
                }
                if (definitions.Length == 0) actionMap.Delete(actionKey)
            }
            if (actionMap.Count == 0) this.LayeredHotkeys.Delete(activator)
        }
        for activator in activatorsToReEvaluate {
            if (!this.LayeredHotkeys.Has(activator)) {
                Hotkey "~" . activator, , "Off"
                Hotkey activator . " Up", , "Off"
            }
        }
    }

    static _unregisterSequence(pluginName) {
        local allDefs := this._getAllSequenceDefs(), remainingDefs := []
        for def in allDefs {
            if (def.plugin != pluginName) remainingDefs.Push(def)
        }
        if (remainingDefs.Length < allDefs.Length) {
            this.HotkeyTree := Map()
            for def in remainingDefs {
                this._addSequenceToTree(def)
            }
        }
    }


    ; ======================================================================
    ; VIII. 内部实现 - 辅助工具 (Internal Implementation)
    ; ======================================================================

    static _formatKeystroke(def) {
        switch def.type {
            case "regular":
                local k := def.keys
                k := StrReplace(k, "^", "Ctrl+"), k := StrReplace(k, "!", "Alt+"), k := StrReplace(k, "+", "Shift+"), k := StrReplace(k, "#", "Win+")
                if SubStr(k, -1) == "+" k := SubStr(k, 1, -1)
                    return k
            case "layer": return def.keys[1] . " + " . def.keys[2]
            case "sequence": return "<Leader> " . def.keys.Join(" ")
        }
        return ""
    }
}
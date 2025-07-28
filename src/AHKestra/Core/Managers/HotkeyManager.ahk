#Requires AutoHotkey v2.0
#Include %A_ScriptDir%\Core\Views\ModeIndicatorGUI.ahk
#Include %A_ScriptDir%\Core\Views\KeystrokeDisplayGUI.ahk

class HotkeyManager {
    static Hotkeys := Map()
    static LayeredHotkeys := Map()
    static HotkeyTree := Map()
    static SequenceHook := ""
    static SequenceBuffer := ""
    static SequenceTimer := ""
    static ActiveLayers := Map()
    static CurrentMode := "NORMAL"
    static Modes := Map()
    static leaderKey := ""

    static Init() {
        leaderKey := ConfigService.Get("HotkeyManager.settings.leaderKey")
        ModeIndicatorGUI.Init()
        KeystrokeDisplayGUI.Init()
        this.SequenceHook := InputHook("V T5", "{All}")
        this.SequenceHook.OnEnd := this.OnSequenceEnd.Bind(this)
        this.SequenceHook.OnChar := this.OnSequenceChar.Bind(this)
        this.SequenceHook.KeyOpt("{All}", "N")

        try {
            Hotkey this.leaderKey, (*) => this.StartSequence()
        } catch Error as e {
            MsgBox "无法注册 Leader 键: " this.leaderKey ".`n请检查按键名称是否有效。`n" e.Message
        }
    }

    static DefineMode(name, options) {
        this.Modes[name] := options
    }

    static SetMode(name, position := unset) {
        this.CurrentMode := name
        if this.Modes.Has(name) {
            ModeIndicatorGUI.Show(this.Modes[name], position)
        }
    }

    static Register(pluginName, hotkeyDef) {
        hotkeyDef.plugin := pluginName

        try {
            switch hotkeyDef.type {
                case "regular":
                    local keyStr := hotkeyDef.keys
                    if !this.Hotkeys.Has(keyStr) {
                        this.Hotkeys[keyStr] := []
                        Hotkey keyStr, (*) => this.HandleHotkeyDispatch(keyStr)
                    }
                    this.Hotkeys[keyStr].Push(hotkeyDef)
                case "layer":
                    local activator := hotkeyDef.keys[1], actionKey := hotkeyDef.keys[2]
                    if !this.LayeredHotkeys.Has(activator) {
                        this.LayeredHotkeys[activator] := Map()
                        Hotkey "~" . activator, (*) => this.OnLayerDown(activator), "On"
                        Hotkey activator . " Up", (*) => this.OnLayerUp(activator), "On"
                    }
                    if !this.LayeredHotkeys[activator].Has(actionKey) {
                        this.LayeredHotkeys[activator][actionKey] := []
                    }
                    this.LayeredHotkeys[activator][actionKey].Push(hotkeyDef)
                case "sequence":
                    if (hotkeyDef.keys[1] != this.leaderKey) {
                        MsgBox "序列热键注册失败: " . hotkeyDef.keys.Join("") . "`n原因：序列必须以配置的 Leader 键 (" . this.leaderKey . ") 开头。"
                        return
                    }
                    this.BuildHotkeyTree(hotkeyDef)
            }
        } catch Error {
            MsgBox "热键注册失败: " . (hotkeyDef.keys.Join ? hotkeyDef.keys.Join("") : hotkeyDef.keys) . "`n" . Error.Message
        }
    }

    static BuildHotkeyTree(def) {
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

    static HandleHotkeyDispatch(keyStr) {
        local context := ContextService.GetContext()
        if this.Hotkeys.Has(keyStr) {
            for def in this.Hotkeys[keyStr] {
                if Conditions.Check(def.condition, context) {
                    this.HandleCallback(def,context)
                    return ; 执行第一个满足条件的，然后停止
                }
            }
        }
    }

    static HandleLayeredDispatch(keyPath) {
        local parts := StrSplit(keyPath, ">"), activator := parts[1], actionKey := parts[2]
        local context := ContextService.GetContext()
        if this.LayeredHotkeys.Has(activator) && this.LayeredHotkeys[activator].Has(actionKey) {
            for def in this.LayeredHotkeys[activator][actionKey] {
                if Conditions.Check(def.condition, context) {
                    this.HandleCallback(def,context)
                    return ; 执行第一个满足条件的
                }
            }
        }
    }

    static OnLayerDown(activator) {
        this.ActiveLayers[activator] := true
        this.SetMode("WINDOW")
        KeystrokeDisplayGUI.Show(activator . "+")
        if this.LayeredHotkeys.Has(activator) {
            for actionKey, defList in this.LayeredHotkeys[activator] {
                local keyPath := activator . ">" . actionKey ; 创建唯一路径标识
                Hotkey actionKey, (*) => this.HandleLayeredDispatch(keyPath), "On"
            }
        }
    }

    static OnLayerUp(activator) {
        this.ActiveLayers[activator] := false
        this.SetMode("NORMAL")
        KeystrokeDisplayGUI.Show("")
        if this.LayeredHotkeys.Has(activator) {
            for actionKey, def in this.LayeredHotkeys[activator] {
                Hotkey actionKey, , "Off"
            }
        }
    }

    static StartSequence() {
        this.SequenceBuffer := this.leaderKey
        this.SequenceHook.Start()
        this.SequenceTimer := SetTimer(this.SequenceTimeout.Bind(this), -5000)
        this.UpdateSequenceDisplay()
    }

    static OnSequenceChar(hook, char) {
        this.SequenceBuffer .= char
        this.UpdateSequenceDisplay()
    }

    static UpdateSequenceDisplay() {
        local context := ContextService.GetContext()
        local currentNode := this.HotkeyTree
        local keys := StrSplit(this.SequenceBuffer)
        try {
            for key in keys {
                currentNode := currentNode[key]
            }
        } catch Error {
            this.SequenceHook.Stop()
            return
        }

        if (currentNode.Has("_def")) {
            for def in currentNode["_def"] {
                if Conditions.Check(def, context) { ; 找到第一个满足条件的并执行
                    this.SequenceHook.Stop()
                    this.HandleCallback(def,context)
                    return
                }
            }
        }

        local possibleNext := []
        for key, node in currentNode {
            if (key != "_def") {
                local hint := "", isActionable := false
                if (node.Has("_def")) {
                    ; 寻找一个在当前上下文可用的提示
                    for def in node["_def"] {
                        if Conditions.Check(def, context) {
                            hint := def.hint
                            isActionable := true
                            break
                        }
                    }
                }
                if (!isActionable) {
                    ; // (可以添加更深的查找逻辑，这里简化)
                }

                if (isActionable) {
                    ; // 只显示那些可用的后续按键
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

    static OnSequenceEnd(hook, endReason) {
        if (IsObject(this.SequenceTimer)) {
            SetTimer this.SequenceTimer, "Off"
        }
        this.SequenceTimer := ""
        this.SequenceBuffer := ""
        KeystrokeDisplayGUI.Hide()
    }

    static SequenceTimeout() {
        this.SequenceHook.Stop()
    }

    static FormatKeystroke(def, sequencePart := "") {
        switch def.type {
            case "regular":
                local k := def.keys
                k := StrReplace(k, "^", "Ctrl+")
                k := StrReplace(k, "!", "Alt+")
                k := StrReplace(k, "+", "Shift+")
                k := StrReplace(k, "#", "Win+")
                if SubStr(k, -1) == "+"
                    k := SubStr(k, 1, -1)
                return k
            case "layer":
                return def.keys[1] . "+" . def.keys[2]
            case "sequence":
                return "<Leader>" . sequencePart
            case "hyper":
                return "<Caps>" . def.keys
        }
        return ""
    }

    static HandleCallback(hotkeyInfo,context) {
        if !IsObject(hotkeyInfo) {
            return ; 防御性编程
        }
        try {
            if (hotkeyInfo.type != "sequence") {
                local text := this.FormatKeystroke(hotkeyInfo)
                KeystrokeDisplayGUI.Show(text)
                SetTimer () => KeystrokeDisplayGUI.Hide(""), -1000
            }
            hotkeyInfo.callback(context)
        } catch Error as e {
            MsgBox "执行回调时出错: " e.Message "`n所在文件: " e.File "`n所在行: " e.Line
        }
    }

    /**
     * 获取所有已注册的【常规】热键。
     * @returns {Array}
     */
    static GetRegularHotkeys() {
        local results := []
        for _, defs in this.Hotkeys {
            for def in defs {
                results.Push(def.Clone()) ; 返回克隆，防止外部修改原始定义
            }
        }
        return results
    }

    /**
     * 获取所有已注册的【分层】热键。
     * @returns {Array}
     */
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

    /**
     * 获取所有已注册的【序列】热键。
     * @returns {Array}
     */
    static GetSequenceHotkeys() {
        local results := []

        ; 内部递归函数，用于遍历热键树
        _traverseTree(node, sequence := []) {
            if (node.Has("_def")) {
                for def in node["_def"] {
                    ; 创建一个副本并移除 leaderKey，因为它对于用户来说是隐式的
                    local displayDef := def.Clone()
                    displayDef.keys.RemoveAt(1)
                    results.Push(displayDef)
                }
            }
            for key, subNode in node {
                if (key != "_def") {
                    _traverseTree(subNode, sequence . key)
                }
            }
        }

        _traverseTree(this.HotkeyTree)
        return results
    }

}
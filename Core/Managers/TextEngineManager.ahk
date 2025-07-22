#Requires AutoHotkey v2.0
#Include %A_ScriptDir%\Lib\YAML.ahk
#Include %A_ScriptDir%\Lib\XHotstring.ahk

class TextEngineManager {
    static Expansions := Map() ; 存储从YAML解析的扩展规则: "trigger" => [def1, def2, ...]

    static Init() {
    }

    ; =============================================================
    ; I. 文本扩展引擎 (Text Expansion Engine)
    ; =============================================================

    /**
     * 由 PluginManager 调用，从 YAML 文件中解析并注册文本扩展。
     * @param yamlPath {String} YAML 文件的完整路径。
     */
    static RegisterExpansionFromYaml(yamlPath) {
        try {
            local yamlContent := FileRead(yamlPath)
            local parsed := Yaml.Load(yamlContent)

            if parsed.HasProp("matches") {
                for match in parsed.matches {
                    local options := ":*?:"
                    local trigger := match.trigger

                    XHotstring(trigger, this._expansionCallback.Bind(this))

                    if !this.Expansions.Has(trigger) {
                        this.Expansions[trigger] := []
                    }

                    local condition := Map()
                    if match.HasProp("filter_title") {
                        condition["filter_title"] := match.filter_title
                    }
                    if match.HasProp("filter_class") {
                        condition["filter_class"] := match.filter_class
                    }
                    if match.HasProp("filter_exec") {
                        condition["filter_exec"] := match.filter_exec
                    }

                    this.Expansions[trigger].Push({
                        replace: match.replace,
                        condition: condition
                    })
                }
            }
        } catch Error as e {
            MsgBox "解析或注册 Espanso 配置文件失败: " . yamlPath . "`n" . e.Message
        }
    }

    /**
     * 统一的回调函数，但现在由 XHotstring 引擎调用。
     * @param TriggerMatch {Match} XHotstring 传递的正则匹配对象。
     * @param EndChar {String} 结尾字符。
     * @param HS {Object} XHotstring 对象本身。
     */
    static _expansionCallback(TriggerMatch, EndChar, HS) {
        local context := ContextService.GetContext()
        local triggerKey := HS.TriggerWithOptions

        if this.Expansions.Has(triggerKey) {
            for expansion in this.Expansions[triggerKey] {
                if this._isExpansionConditionMet(expansion.condition, context) {
                    local finalReplacement := RegExReplace(TriggerMatch.Value, HS.Trigger, expansion.replace)
                    SendInput finalReplacement
                    return ; 执行第一个满足条件的就停止
                }
            }
        }
    }

    /**
     * 专用于文本扩展的私有条件检查函数。
     * @param condition {Map} 从YAML解析的条件Map对象。
     * @param context {Object} 当前的上下文信息。
     * @returns {Boolean}
     */
    static _isExpansionConditionMet(condition, context) {
        if !IsObject(condition) || condition.Count = 0 {
            return true ; 如果没有定义条件，则默认满足
        }

        local checks := [] ; 存储所有存在的检查项的结果

        if condition.Has("filter_title") {
            local titleMatch := false
            local filterValue := condition.filter_title
            local filters := IsObject(filterValue) ? filterValue : [filterValue]
            for filter in filters {
                ; 例如: "Chrome|Firefox"
                if RegExMatch(context.ActiveWindow.title, filter) {
                    titleMatch := true
                    break
                }
            }
            checks.Push(titleMatch)
        }

        if condition.Has("filter_class") {
            local classMatch := false
            local filterValue := condition.filter_class
            local filters := IsObject(filterValue) ? filterValue : [filterValue]
            for filter in filters {
                if RegExMatch(context.ActiveWindow.class, filter) {
                    classMatch := true
                    break
                }
            }
            checks.Push(classMatch)
        }

        if condition.Has("filter_exec") {
            local execMatch := false
            local filterValue := condition.filter_exec
            local filters := IsObject(filterValue) ? filterValue : [filterValue]
            local processPath := context.ActiveWindow.processPath
            for filter in filters {
                if RegExMatch(processPath, filter) {
                    execMatch := true
                    break
                }
            }
            checks.Push(execMatch)
        }

        if (checks.Length = 0) {
            return true
        }

        for result in checks {
            if (!result) {
                return false
            }
        }

        return true
    }
}
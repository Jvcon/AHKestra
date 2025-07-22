#Requires AutoHotkey v2.0
#Include %A_ScriptDir%\Lib\yaml.ahk ; 引入YAML解析库

class TextEngineManager {
    static Expansions := Map() ; 存储从YAML解析的扩展规则: "trigger" => [def1, def2, ...]

    static Init() {
    }

    ; =============================================================
    ; I. 文本扩展引擎 (Text Expansion Engine)
    ; =============================================================

    /**
     * 由 PluginService 调用，从 YAML 文件中解析并注册文本扩展。
     * @param yamlPath {String} YAML 文件的完整路径。
     */
    static RegisterExpansionFromYaml(yamlPath) {
        try {
            local yamlContent := FileRead(yamlPath)
            local parsed := Yaml.Load(yamlContent)

            if parsed.HasProp("matches") {
                for match in parsed.matches {
                    local trigger := match.trigger

                    if !this.Expansions.Has(trigger) {
                        this.Expansions[trigger] := []
                        ; 核心：为每个唯一的trigger注册一次原生的Hotstring函数，并绑定回调
                        Hotstring(trigger, this._expansionCallback.Bind(this))
                    }

                    local condition := Map()
                    if match.HasProp("filter_title") {
                        condition["filter_title"] := match.filter_title
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
     * 统一的热字符串回调函数，由 AHK 原生引擎在触发时调用。
     * @param trigger {String} 被触发的热字符串 (e.g., ":date")
     */
    static _expansionCallback(trigger) {
        local context := ContextService.GetContext()

        if this.Expansions.Has(trigger) {
            for expansion in this.Expansions[trigger] {
                if this._isExpansionConditionMet(expansion.condition, context) {
                    SendInput expansion.replace
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

        if condition.Has("filter_title") {
            for filter in condition.filter_title {
                if InStr(context.ActiveWindow.title, filter) {
                    return true ; 只要匹配一个标题过滤器即可
                }
            }
            return false ; 如果定义了filter_title但一个都没匹配上，则不满足
        }

        return true ; 对于未知的条件类型，暂时默认为满足
    }
}
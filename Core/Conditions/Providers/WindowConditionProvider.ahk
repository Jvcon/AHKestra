#Include %A_ScriptDir%\..\IConditionProvider.ahk

/**
 * 一个多合一的条件提供者，如同一个功能模块（Module），负责提供所有与窗口状态相关的条件。
 * 这种模式允许将高度内聚的逻辑组织在单个文件中，便于维护和管理。
 */
class WindowConditionsProvider extends IConditionProvider {
    /**
     * 【核心变化】Evaluate 方法现在需要知道具体要评估哪个条件。
     * 我们增加一个 conditionType 参数，用于内部的逻辑分发（Dispatch）。
     * @param context {Map} 当前的上下文。
     * @param conditionType {String} 要评估的条件名称，如 "WindowIsActive"。
     * @param params {Map} 用户为该条件提供的参数。
     * @returns {Boolean}
     */
    Evaluate(context, conditionType, params) {
        ; 防御性检查：如果连 ActiveWindow 的上下文都没有，大多数窗口相关的条件都无法满足。
        if (!context.Has("ActiveWindow") && (conditionType == "WindowIsActive" || conditionType == "WindowIsMaximized")) {
            return false
        }

        local activeWindow := context.Has("ActiveWindow") ? context.ActiveWindow : ""

        Switch conditionType {
            Case "WindowIsActive":
                if (params.Has("process") && activeWindow.process != params.process) return false
                    if (params.Has("title_contains") && !InStr(activeWindow.title, params.title_contains)) return false
                        return true

            Case "WindowExists":
                local winTitle := "ahk_exe " (params.Has("process") ? params.process : "")
                if (params.Has("title_contains")) {
                    SetTitleMatchMode(2) ; 确保是子字符串匹配
                    winTitle .= " " params.title_contains
                }
                return WinExist(winTitle)

            Case "WindowIsMaximized":
                return WinGetMinMax("ahk_id " . activeWindow.hwnd) == 1

            Default:
                ; 如果一个未知的 conditionType 被传入，安全地失败。
                return false
        }
    }

    /**
     * 【核心变化】此方法现在返回一个包含多个顶级键的 Map。
     * 每一个键都代表一个独立的、可被调用的条件。
     */
    GetConditionDefinitions() {
        return Map(
            "WindowIsActive", {
                desc: "检查当前激活的窗口是否满足特定属性。",
                params: Map(
                    "process", { type: "String", desc: "窗口所属进程的名称。", required: false },
                    "title_contains", { type: "String", desc: "窗口标题必须包含的子字符串。", required: false }
                ),
                example: '{ type: "WindowIsActive", process: "explorer.exe" }'
            },
            "WindowExists", {
                desc: "检查是否存在至少一个满足条件的窗口（不一定是激活的）。",
                params: Map(
                    "process", { type: "String", desc: "进程名称。", required: false },
                    "title_contains", { type: "String", desc: "标题子字符串。", required: false }
                ),
                example: '{ type: "WindowExists", class: "Notepad" }'
            },
            "WindowIsMaximized", {
                desc: "检查当前激活的窗口是否处于最大化状态。",
                params: Map(),
                example: '{ type: "WindowIsMaximized" }'
            }
        )
    }

}

global _g_CurrentConditionProviderClass := WindowConditionsProvider
#Include %A_ScriptDir%\..\IContextProvider.ahk

/**
 * @ProviderName Mouse Target Provider
 * @ProviderDescription 提供鼠标指针当前悬停目标的信息。
 */
class MouseTargetProvider extends IContextProvider {
    GetValue(currentContext := "") {
        local mouseX, mouseY, mouseHwnd, mouseControl
        MouseGetPos(&mouseX, &mouseY, &mouseHwnd, &mouseControl)
        return Map(
            "MouseTarget", Map(
                "hwnd", mouseHwnd,
                "title", WinGetTitle("ahk_id " mouseHwnd),
                "class", WinGetClass("ahk_id " mouseHwnd),
                "control", mouseControl
            ),
            "MouseMonitor", MonitorManager.GetFromPoint(mouseX, mouseY)
        )
    }

    GetContextDefinitions() {
        return Map(
            "MouseTarget", {
                desc: "获取鼠标下的窗口和控件信息。",
                layer: "volatile",
                return_type: "Map",
                return_schema: Map("hwnd", "当前窗口",
                    "title", "窗口标题",
                    "class", "窗口Class",
                    "control", "当前控件")
            },
            "MouseMonitor", {
                desc: "获取鼠标所在的显示器信息。",
                layer: "volatile",
                return_type: "String",
                return_schema: "当前显示器"
            }
        )
    }
}
global _g_CurrentContextProviderClass := MouseTargetProvider
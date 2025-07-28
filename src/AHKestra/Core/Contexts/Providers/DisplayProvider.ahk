/**
 * @ProviderName Display Info Provider
 * @ProviderDescription 提供关于显示器的静态信息。
 */
class DisplayInfoProvider extends IContextProvider {
    GetValue(currentContext := "") {
        local monitorsInfo := Map()
        monitorsInfo["Monitors"] := Map(
            "count", MonitorService._InternalGetAll().Length,
            "all", MonitorService._InternalGetAll(),
            "primary", MonitorService._InternalGetPrimary()
        )
        ; 如果上层上下文提供了窗口或鼠标信息，则可以动态计算它们所在的显示器
        if (IsObject(currentContext)) {
            if (currentContext.Has("ActiveWindow")) {
                monitorsInfo.Monitors["activeMonitor"] := MonitorService._InternalGetFromWindow(currentContext.ActiveWindow.hwnd)
            }
            if (currentContext.Has("MouseTarget")) {
                WinGetPos(&x, &y, , , "ahk_id " . currentContext.MouseTarget.hwnd)
                monitorsInfo.Monitors["mouseMonitor"] := MonitorService._InternalGetFromPoint(x, y)
            }
        }
        return monitorsInfo
    }

    GetContextDefinitions() {
        return Map(
            "Displays", {
                desc: "获取所有显示器的信息集合。",
                layer: "stable",
                return_type: "Map",
                return_schema: Map("count", "显示器数量", "all", "所有显示器信息", "primary", "主屏幕","activeMonitor","当前激活显示器","mouseMonitor","指针所在显示器")
            }
        )
    }
}
global _g_CurrentContextProviderClass := DisplayInfoProvider
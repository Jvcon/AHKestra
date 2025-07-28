#Include %A_ScriptDir%\..\IContextProvider.ahk

/**
 * @ProviderName Virtual Desktop Provider
 * @ProviderDescription 提供Windows虚拟桌面的相关信息。
 */
class VirtualDesktopProvider extends IContextProvider {
    static VDA := ""
    
    __New() {
        ; 在实例化时加载DLL，确保只加载一次
        if (this.VDA = "" && FileExist(APP_LIB_DIR . "\VirtualDesktopAccessor.dll")) {
            try {
                VirtualDesktopProvider.VDA := DllCall("LoadLibrary", "Str", APP_LIB_DIR . "\VirtualDesktopAccessor.dll", "Ptr")
            } catch {
                VirtualDesktopProvider.VDA := 0
            }
        }
    }
    
    GetValue(currentContext) {
        if (!IsObject(currentContext) || !currentContext.Has("ActiveWindow")) {
            return Map("VirtualDesktop", "")
        }
        local hwnd := currentContext.ActiveWindow.hwnd
        if (this.VDA) {
            return Map(
                "VirtualDesktop", Map(
                    "current", DllCall(this.VDA . "\GetCurrentDesktopNumber", "Int"),
                    "isWinOnCurrent", DllCall(this.VDA . "\IsWindowOnCurrentVirtualDesktop", "Ptr", hwnd, "Int")
                )
            )
        }
        return Map("VirtualDesktop", Map("current", 1, "isWinOnCurrent", true))
    }

    GetContextDefinitions() {
        return Map(
            "VirtualDesktop", {
                desc: "获取当前虚拟桌面信息。",
                layer: "stable",
                return_type: "Map",
                return_schema: Map("current", "当前桌面编号", "isWinOnCurrent", "激活窗口是否在当前桌面")
            }
        )
    }
}
global _g_CurrentContextProviderClass := VirtualDesktopProvider

; Core/Services/ContextService.ahk - 上下文感知服务
#Requires AutoHotkey v2.0

; 推荐：为了支持虚拟桌面功能, 请从以下地址下载 VirtualDesktopAccessor.dll
; 并将其放置在 Lib 目录下。
; https://github.com/Ciantic/VirtualDesktopAccessor

class ContextService {
    static VDA := ""
    static Providers := Map()

    static Init() {
        try {
            if FileExist(APP_LIB_DIR . "\VirtualDesktopAccessor.dll") {
                this.VDA := DllCall("LoadLibrary", "Str", APP_LIB_DIR . "\VirtualDesktopAccessor.dll", "Ptr")
            }
        } catch Error {
            this.VDA := ""
        }
    }

    static RegisterProvider(processName, providerFunc) {
        this.Providers[processName] := providerFunc
    }

    static GetContext() {
        local context := Map()

        ; 活动窗口信息
        local hwnd := WinActive("A")
        context['ActiveWindow'] := Map(
            "hwnd", hwnd,
            "title", WinGetTitle("ahk_id " hwnd),
            "class", WinGetClass("ahk_id " hwnd),
            "processPath", WinGetProcessPath("ahk_id " hwnd),
            "processName", WinGetProcessName("ahk_id " hwnd)
        )

        ; 鼠标对象信息
        local mouseX, mouseY, mouseHwnd, mouseControl
        MouseGetPos(&mouseX, &mouseY, &mouseHwnd, &mouseControl)
        context['MouseTarget'] := Map(
            "hwnd", mouseHwnd,
            "title", WinGetTitle("ahk_id " mouseHwnd),
            "class", WinGetClass("ahk_id " mouseHwnd),
            "control", mouseControl
        )

        ; 焦点控件信息
        local focusedControl := ControlGetFocus("A")
        context['FocusedControl'] := Map(
            "classNN", focusedControl,
            "text", ControlGetText(focusedControl, "A")
        )

        ; 显示器信息
        context['Displays'] := Map(
            "count", MonitorManager.GetAll().Length,
            "all", MonitorManager.GetAll(),
            "primary", , MonitorManager.GetPrimary()
            "windowMonitor", MonitorManager.GetFromWindow(hwnd),
            "mouseMonitor", MonitorManager.GetFromPoint(mouseX, mouseY)
        )

        ; 虚拟桌面信息
        if (this.VDA) {
            local currentDesktop := DllCall(this.VDA . "\GetCurrentDesktopNumber", "Int")
            local isWindowOnCurrent := DllCall(this.VDA . "\IsWindowOnCurrentVirtualDesktop", "Ptr", hwnd, "Int")
            context['VirtualDesktop'] := Map(
                "current", currentDesktop,
                "isWinOnCurrent", isWindowOnCurrent
            )
        } else {
            context['VirtualDesktop'] := Map("current", 1, "isWinOnCurrent", true)
        }

        ; 文本信息
        context["TextSources"] := TextEngineManager.GetTextSources()

        ; 插件注册的上下文信息
        local processName := context.ActiveWindow.processName
        if (this.Providers.Has(processName)) {
            try {
                local specificContext := this.Providers[processName](context)
                for key, value in specificContext {
                    context[key] := value
                }
            } catch {
                ; 错误处理
            }
        }

        return context
    }
}
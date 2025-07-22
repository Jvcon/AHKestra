; Core/Services/ContextService.ahk - 上下文感知服务
#Requires AutoHotkey v2.0

; 推荐：为了支持虚拟桌面功能, 请从以下地址下载 VirtualDesktopAccessor.dll
; 并将其放置在 Lib 目录下。
; https://github.com/Ciantic/VirtualDesktopAccessor

class ContextService {
    static VDA := ""
    static Providers := Map()

    static _cachedContext := Map(
        "stable", "",
        "active", "",
        "volatile", ""
    )
    static _cacheTimestamps := Map(
        "stable", 0,
        "active", 0
    )
    static _cacheDurations := Map(
        "stable", -1, ; -1 表示只通过事件失效
        "active", 250 ; 活动层缓存有效期为 250ms
    )

    static _winEventHook := 0
    static EVENT_SYSTEM_FOREGROUND := 0x0003

    static Init() {
        try {
            if FileExist(APP_LIB_DIR . "\VirtualDesktopAccessor.dll") {
                this.VDA := DllCall("LoadLibrary", "Str", APP_LIB_DIR . "\VirtualDesktopAccessor.dll", "Ptr")
            }
        } catch Error {
            this.VDA := ""
        }
        this._winEventHook := DllCall("User32\SetWinEventHook",
            "UInt", this.EVENT_SYSTEM_FOREGROUND,  ; eventMin
            "UInt", this.EVENT_SYSTEM_FOREGROUND,  ; eventMax
            "Ptr", 0,                             ; hmodWinEventProc
            "Ptr", CallbackCreate(this._onForegroundChange.Bind(this), "F"), ; lpfnWinEventProc
            "UInt", 0,                            ; idProcess
            "UInt", 0,                            ; idThread
            "UInt", 0)                            ; dwFlags (WINEVENT_OUTOFCONTEXT)
    }

    static Unhook() {
        if (this._winEventHook) {
            DllCall("User32\UnhookWinEvent", "Ptr", this._winEventHook)
            this._winEventHook := 0
        }
    }

    static _onForegroundChange(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime) {
        this.InvalidateContext("all")
    }

    /**
     * 公共接口：允许外部模块（特别是插件）按需失效缓存。
     * @param scope {String} 要失效的范围, "all", "active", "volatile"。
     */
    static InvalidateContext(scope := "active") {
        Switch scope {
            Case "all":
                this._cachedContext.stable := ""
                this._cacheTimestamps.stable := 0
            Case "active":
                this._cachedContext.active := ""
                this._cacheTimestamps.active := 0
            Case "volatile":
                ; 通常 volatile 层是即时生成的，但这里也提供一个接口
                this._cachedContext.volatile := ""
        }
    }

    static RegisterProvider(processName, providerFunc) {
        this.Providers[processName] := providerFunc
    }

    static GetContext() {
        local now := A_TickCount
        local context := Map()
        ; 稳定层上下文
        if (this._cachedContext.stable && (this._cacheDurations.stable < 0 || now - this._cacheTimestamps.stable < this._cacheDurations.stable)) {
            finalContext := this._cachedContext.stable.Clone()
        } else {
            local stable := Map()
            local hwnd := WinActive("A")
            stable['ActiveWindow'] := Map(
                "hwnd", hwnd,
                "class", WinGetClass("ahk_id " hwnd),
                "processPath", WinGetProcessPath("ahk_id " hwnd),
                "processName", WinGetProcessName("ahk_id " hwnd),
                "monitor", MonitorManager.GetFromWindow(hwnd)
            )
            if (this.VDA) {
                stable['VirtualDesktop'] := Map(
                    "current", DllCall(this.VDA . "\GetCurrentDesktopNumber", "Int"),
                    "isWinOnCurrent", DllCall(this.VDA . "\IsWindowOnCurrentVirtualDesktop", "Ptr", hwnd, "Int")
                )
            } else {
                stable['VirtualDesktop'] := Map("current", 1, "isWinOnCurrent", true)
            }
            stable['Displays'] := Map(
                "count", MonitorManager.GetAll().Length,
                "all", MonitorManager.GetAll(),
                "primary", MonitorManager.GetPrimary()
            )

            this._cachedContext.stable := stable
            this._cacheTimestamps.stable := now
            this.InvalidateContext("active")
            finalContext := stable.Clone()
        }
        ; 活动层上下文
        if (this._cachedContext.active && now - this._cacheTimestamps.active < this._cacheDurations.active) {
            for k, v in this._cachedContext.active {
                finalContext[k] := v
            }
        } else {
            local active := Map()
            active.ActiveWindow.title := WinGetTitle("ahk_id " . finalContext.ActiveWindow.hwnd)
            active['FocusedControl'] := Map(
                "classNN", ControlGetFocus("A"),
                "text", ControlGetText(ControlGetFocus("A"), "A"))

            active["TextSources"] := this.GetTextSources()

            ; 插件提供的上下文属于活动层
            local processName := finalContext.ActiveWindow.processName
            if (this.Providers.Has(processName)) {
                try {
                    local specificContext := this.Providers[processName](finalContext)
                    for key, value in specificContext {
                        active[key] := value
                    }
                } catch {
                }
            }

            this._cachedContext.active := active
            this._cacheTimestamps.active := now
            this.InvalidateContext("volatile")
            for k, v in active {
                finalContext[k] := v
            }
        }
        ; 实时层上下文
        local mouseX, mouseY, mouseHwnd, mouseControl
        MouseGetPos(&mouseX, &mouseY, &mouseHwnd, &mouseControl)
        finalContext['MouseTarget'] := Map(
            "hwnd", mouseHwnd,
            "title", WinGetTitle("ahk_id " mouseHwnd),
            "class", WinGetClass("ahk_id " mouseHwnd),
            "control", mouseControl
        )
        finalContext.Displays["mouseMonitor"] := MonitorManager.GetFromPoint(mouseX, mouseY)

        return finalContext
    }

    /**
     * 获取所有可能的文本源
     * @returns {Map} 一个包含所有文本源的 Map 对象。
     */
    static GetTextSources() {
        local sources := Map()

        local oldClipboard := ClipboardAll(), selectedText := ""
        A_Clipboard := ""
        SendInput "^c"
        if ClipWait(0.2, true) {
            selectedText := A_Clipboard
        }
        A_Clipboard := oldClipboard

        if (selectedText != "") {
            sources["selection"] := selectedText
        }

        ; b. 获取剪贴板内容
        if (A_Clipboard != "") {
            sources["clipboard"] := A_Clipboard
        }

        return sources
    }
}

/**
 * @ProviderName Window Events Provider
 * @ProviderDescription 提供了与操作系统窗口相关的核心事件，如窗口的激活、移动和大小调整。
 * @Version 1.1.0
 */
class WindowEventsProvider extends IEventProvider {
    
    RegisterEvents(producerName) {
        local definitions := this.GetEventDefinitions()
        for name, def in definitions {
            local provider := (def.type == "dynamic") ? this : A_LineFile
            EventRegistry.Register(name, def.type, def.desc, provider, producerName)
        }
        
        global g_WindowEvents_hook := WinEvent.Foreground(this._GlobalWindowActivatedHandler)
    }

    CreateHook(eventName, target, handler) {
        try {
            local eventType := StrSplit(eventName, ".")[2]
            return WinEvent[eventType](handler, target)
        } catch e {
            throw Error("WindowEventsProvider failed to create hook for " . eventName, -1, e)
        }
    }
    
    GetEventDefinitions() {
        return Map(
            "Window.Activated", {
                type: "global",
                desc: "当一个新窗口被激活时触发。",
                data_schema: Map(
                    "hWnd", "激活窗口的句柄 (HWND)。"
                ),
                example: 'Events.On("Window.Activated", (data) => MsgBox("新窗口激活: " . data.hWnd))'
            },

            "Window.Moved", {
                type: "dynamic",
                desc: "当一个目标窗口被移动时触发。",
                data_schema: Map(
                    "hWnd", "被移动窗口的句柄 (HWND)。",
                    "time", "事件发生时的毫秒时间戳。"
                ),
                example: 'Events.On("Window.Moved", (data) => OutputDebug("窗口移动"), "ahk_exe notepad.exe")'
            },

            "Window.Resized", {
                type: "dynamic",
                desc: "当一个目标窗口大小被改变时触发。",
                data_schema: Map(
                    "hWnd", "大小被改变的窗口的句柄 (HWND)。",
                    "time", "事件发生时的毫秒时间戳。"
                ),
                example: 'Events.On("Window.Resized", (data) => OutputDebug("窗口大小改变"), "ahk_class #32770")'
            }
        )
    }

    _GlobalWindowActivatedHandler(hWnd, eventObj, dwmsEventTime) {
        EventBus.Trigger("Window.Activated", {hWnd: hWnd})
    }
}

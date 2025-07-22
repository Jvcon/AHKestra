; Core/EventBridge/SystemEventBridge.ahk
#Requires AutoHotkey v2

#Include %A_ScriptDir%\Lib\WinEvent.ahk

class SystemEventBridge {
    static _hiddenGui := ""

    /**
     * 初始化系统事件桥
     * 这个方法会注册所有我们关心的系统级事件，并将它们连接到 EventService。
     */
    static Init() {
        ; --- 1. 使用 WinEvent.ahk 监听窗口事件 ---

        ; 监听所有窗口的创建事件
        WinEvent.Create(this._OnWindowCreated.Bind(this))

        ; 监听所有窗口的关闭事件
        WinEvent.Close(this._OnWindowClosed.Bind(this))

        ; 监听所有窗口的激活事件
        WinEvent.Active(this._OnWindowActivated.Bind(this))

        ; 监听所有窗口的失活事件
        WinEvent.NotActive(this._OnWindowDeactivated.Bind(this))

        ; ... 在这里可以根据需要添加更多 WinEvent 监听器 ...
        ; WinEvent.Move(this._OnWindowMoved.Bind(this))
        ; WinEvent.Minimize(this._OnWindowMinimized.Bind(this))
        ; WinEvent.Restore(this._OnWindowRestored.Bind(this))


        ; --- 2. 补充监听 WinEvent.ahk 不支持的系统消息 ---
        ; 例如显示器配置变更 (WM_DISPLAYCHANGE)

        if (this._hiddenGui) {
            return
        }
        this._hiddenGui := Gui("+E0x08000000 -Caption", "SystemMessageListener")
        GuiService.RegisterGui("SystemMessageListener", this._hiddenGui)

        OnMessage(0x007E, this._OnDisplayChange.Bind(this))
    }

    ; --- WinEvent 事件处理器 ---
    ; 这些处理器将低级事件转换为 EventService 事件

    static _OnWindowCreated(hWnd, eventObj, dwmsEventTime) {
        EventService.Trigger("Window:Created", { hWnd: hWnd, time: dwmsEventTime })
    }

    static _OnWindowClosed(hWnd, eventObj, dwmsEventTime, properties) {
        EventService.Trigger("Window:Closed", { hWnd: hWnd, time: dwmsEventTime })
    }

    static _OnWindowActivated(hWnd, eventObj, dwmsEventTime) {
        EventService.Trigger("Window:Activated", { hWnd: hWnd, time: dwmsEventTime })
    }

    static _OnWindowDeactivated(hWnd, eventObj, dwmsEventTime) {
        EventService.Trigger("Window:Deactivated", { hWnd: hWnd, time: dwmsEventTime })
    }

    ; --- OnMessage 事件处理器 ---

    static _OnDisplayChange(wParam, lParam, msg, hwnd) {
        if (hwnd != this._hiddenGui.Hwnd) {
            return
        }
        ; 延迟触发以确保系统状态稳定
        SetTimer(() => EventService.Trigger("System:DisplayChanged"), -500)
    }
}

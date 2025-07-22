#Requires AutoHotkey v2.0
#Include %A_ScriptDir%\..\..\Lib\Monitor.ahk

/**
 * 显示器底层服务 - 框架内部单例服务。
 * 负责管理 Monitors 库的实例和相关系统资源的生命周期，
 * 为上层的 Context 和 Action 提供者提供统一、唯一的交互入口。
 * 这种将复杂硬件交互封装在管理器中的模式在社区中很常见。
 * @see [garyng/ahk-utilities: Collection of AutoHotKey scripts that I ... - GitHub](https://github.com/garyng/ahk-utilities){target="_blank" class="gpt-web-url"}
 */
class MonitorService {
    static _isInitialized := false
    static _MonitorsInstance := ""
    static _hiddenGui := ""
    static _cachedAll := []
    static _cachedPrimary := ""

    /**
     * 惰性初始化，确保资源仅在首次需要时创建一次。
     */
    static _EnsureInitialized() {
        if (this._isInitialized) {
            return
        }

        this._MonitorsInstance := Monitor()
        this._hiddenGui := Gui("+E0x08000000 -Caption", "InternalMonitorListener")
        OnMessage(0x007E, this.OnDisplayChange.Bind(this))
        this.RefreshCache()
        this._isInitialized := true
    }
    
    static OnDisplayChange(wParam, lParam, msg, hwnd) {
        if (hwnd != this._hiddenGui.Hwnd) {
            return
        }
        SetTimer(this._HandleDisplayChange.Bind(this), -500)
    }

    static _HandleDisplayChange(){
        this.RefreshCache()
        local eventData := {
            newConfiguration: this._cachedAll,
            primary: this._cachedPrimary
        }
        EventBus.Trigger("Display.ConfigChanged", eventData)
    }

    /**
     * 刷新缓存，这是唯一的写缓存入口。
     */
    static RefreshCache() {
        this._EnsureInitialized() ; 确保在刷新时也已初始化
        this._cachedAll := this._MonitorsInstance.GetInfo()
        this._cachedPrimary := ""
        for index, monitor in this._cachedAll {
            monitor.index := index
            if (monitor.Primary) {
                this._cachedPrimary := monitor
            }
        }
        if (!this._cachedPrimary && this._cachedAll.Length > 0) {
            this._cachedPrimary := this._cachedAll[1]
        }
        ; 注意：这里可以触发一个内部事件，但为了简化，暂时省略
    }

    ; --- 内部查询接口 (供 Context Providers 使用) ---
    static _InternalGetAll() {
        this._EnsureInitialized()
        return this._cachedAll
    }

    static _InternalGetPrimary() {
        this._EnsureInitialized()
        return this._cachedPrimary
    }
    
    static _InternalGetByIndex(index) {
        local allMonitors := this._InternalGetAll()
        return (index > 0 && index <= allMonitors.Length) ? allMonitors[index] : ""
    }

    static _InternalGetFromPoint(x, y) {
        for monitor in this._InternalGetAll() {
            if (x >= monitor.Left && x < monitor.Right && y >= monitor.Top && y < monitor.Bottom) {
                return monitor
            }
        }
        return this._InternalGetPrimary()
    }

    static _InternalGetFromWindow(hwnd) {
        if !WinExist("ahk_id " . hwnd) return ""
        WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " . hwnd)
        return this._InternalGetFromPoint(winX + winW / 2, winY + winH / 2)
    }

    ; --- 内部命令接口 (供 Action Providers 使用) ---
    /**
     * 设置显示器亮度。这个功能通常依赖DDC/CI协议。
     */
    static _InternalSetBrightness(monitorIndex, brightnessValue) {
        this._EnsureInitialized()
        local monitor := this._InternalGetByIndex(monitorIndex)
        if (monitor) {
            this._MonitorsInstance.SetBrightness(brightnessValue, monitor.Handle)
        }
    }

    static _InternalSetContrast(monitorIndex, contrastValue) {
        this._EnsureInitialized()
        local monitor := this._InternalGetByIndex(monitorIndex)
        if (monitor) {
            this._MonitorsInstance.SetContrast(contrastValue, monitor.Handle)
        }
    }
}

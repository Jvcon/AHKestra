#Requires AutoHotkey v2.0
#Include %A_ScriptDir%\Lib\Monitors.ahk

class MonitorManager {
    ; --- 缓存层：存储稳定的显示器配置信息 ---
    static _isInitialized := false
    static _cachedAll := []
    static _cachedPrimary := ""

    ; --- 内部资源 ---
    static _MonitorsInstance := "" ; 持有第三方库的实例

    /**
     * 初始化管理器：创建资源并设置事件监听。
     * 此方法完全独立，不依赖任何外部模块。
     */
    static Init() {
        this._MonitorsInstance := Monitor()
        EventService.On("System:DisplayChanged", this.OnDisplayChange.Bind(this))
    }
    
    /**
     * 事件处理器：当显示配置改变时，自动触发缓存刷新。
     */
    static OnDisplayChange(wParam, lParam, msg, hwnd) {
         if (hwnd != this._hiddenGui.Hwnd) {
            return
        }
        ; 延迟刷新以确保系统状态稳定
        SetTimer(this.Refresh.Bind(this), -500)
    }

    /**
     * 刷新并缓存所有稳定的显示器信息。这是唯一的“写缓存”入口。
     */
    static Refresh() {
        try {
            this._cachedAll := this._MonitorsInstance.GetInfo()
            this._cachedPrimary := ""
            for index, monitor in this._cachedAll {
                monitor.index := index
                if (monitor.Primary) {
                    this._cachedPrimary := monitor
                }
            }
            ; 如果没有找到主显示器（罕见情况），则将第一个作为备用
            if (!this._cachedPrimary && this._cachedAll.Length > 0) {
                this._cachedPrimary := this._cachedAll[1]
            }
            this._isInitialized := true
        } catch Error {
            ; 在获取显示器信息失败时进行降级处理
            this._isInitialized := false
        }
    }

    ; =============================================================
    ; 公开 API (Public API) - 供框架其他部分调用
    ; =============================================================

    /**
     * 获取所有显示器的详细信息数组 (使用懒加载和缓存)。
     * @returns {Array}
     */
    static GetAll() {
        if (!this._isInitialized) {
            this.Refresh()
        }
        return this._cachedAll
    }

    /**
     * 获取主显示器的信息 (使用懒加载和缓存)。
     * @returns {Map | Null}
     */
    static GetPrimary() {
        if (!this._isInitialized) {
            this.Refresh()
        }
        return this._cachedPrimary
    }
    
    /**
     * 根据索引号获取指定显示器的信息 (从缓存中读取)。
     * @param index {Integer} 显示器的索引号 (从 1 开始)。
     * @returns {Map | Null}
     */
    static GetByIndex(index) {
        local allMonitors := this.GetAll()
        if (index > 0 && index <= allMonitors.Length) {
            return allMonitors[index]
        }
        return
    }

    /**
     * 根据一个点 (x, y) 的坐标，动态计算它所在的显示器。
     * @returns {Map | Null}
     */
    static GetFromPoint(x, y) {
        for monitor in this.GetAll() {
            if (x >= monitor.Left && x < monitor.Right && y >= monitor.Top && y < monitor.Bottom) {
                return monitor
            }
        }
        return this.GetPrimary() ; 如果点不在任何显示器内，则返回主显示器
    }

    /**
     * 根据一个窗口句柄，动态计算其主要部分所在的显示器。
     * @returns {Map | Null}
     */
    static GetFromWindow(hwnd) {
        if !WinExist("ahk_id " . hwnd) {
            return
        }
        WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " . hwnd)
        return this.GetFromPoint(winX + winW / 2, winY + winH / 2)
    }

    static SetBrightness(monitorIndex, brightnessValue) {
        try {
            local monitor := this.GetByIndex(monitorIndex)
            if (monitor) {
                this._MonitorsInstance.SetBrightness(brightnessValue, monitor.Handle)
            }
        }
    }

        static SetContrast(monitorIndex, contrastValue) {
        try {
            local monitor := this.GetByIndex(monitorIndex)
            if (monitor) {
                this._MonitorsInstance.SetContrast(contrastValue, monitor.Handle)
            }
        }
    }
}

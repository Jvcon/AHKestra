; Core/Services/GuiService.ahk - 用户界面管理服务

class GuiService {
    static Themes := Map()
    ; **名称变更**：从 ActiveWindows 改为 _managedGuis，以更准确地反映其职责
    static _managedGuis := Map()

    static Init() {
        local NordDark := Map(
            "bg", "2E3440",         ; 背景色
            "text", "E5E9F0",       ; 主要文本颜色
            "accent", "88C0D0",     ; 强调色/标题色
            "border", "4C566A",     ; 边框/分隔线颜色
            "success", "A3BE8C",    ; 成功/绿色调
            "warning", "EBCB8B",    ; 警告/黄色调
            "error", "BF616A",      ; 错误/红色调
            "fontFamily", "Segoe UI",
            "fontSize", 10,
            "fontTitleSize", 14
        )
        this.Themes["NordDark"] := NordDark
    }

    static CreateThemedWindow(options := "", title, themeName := "NordDark") {
        if (!this.Themes.Has(themeName)) {
            throw Error("Theme not found: " . themeName)
        }
        local theme := this.Themes[themeName]

        local gui := Gui("-DPIScale " . options, title)
        gui.Opt("-Theme")

        gui.BackColor := theme.bg
        gui.SetFont("s" . theme.fontSize, theme.fontFamily)
        gui.Theme := theme

        return gui
    }

    /**
     * @param name {String} GUI的唯一名称，如 "ModeIndicator", "KeystrokeDisplay"
     * @param guiObj {Gui} 要注册的Gui对象
     */
    static RegisterGui(name, guiObj) {
        if (this._managedGuis.Has(name)) {
            try {
                this._managedGuis[name].Destroy()
            }
        }
        this._managedGuis[name] := guiObj
    }

    static ShowSingletonWindow(name, creationFunc) {
        ; 检查时使用 _managedGuis
        if (this._managedGuis.Has(name) && WinExist("ahk_id " . this._managedGuis[name].Hwnd)) {
            WinActivate("ahk_id " . this._managedGuis[name].Hwnd)
        } else {
            local gui := creationFunc()
            gui.OnEvent("Close", (*) => this._managedGuis.Delete(name))
            gui.Show()
        }
    }

    /**
     * 在应用退出时，销毁所有已注册的窗口。
     */
    static Cleanup() {
        for name, gui in this._managedGuis {
            if (IsObject(gui) && gui.Hwnd) {
                try {
                    gui.Destroy()
                }
            }
        }
    }
}
; Core/Services/GuiService.ahk - 用户界面管理服务
#Requires AutoHotkey v2.0

class GuiService {
    static Themes := Map()
    static _managedGuis := Map()
    static _defaultThemeName := "NordDark" ; 定义一个硬编码的最终备用主题
    static _themesDir := A_ScriptDir . "\..\..\Themes" ; 相对于Core/Services/的路径

    static Init() {
        this.LoadAllThemes()
    }

    /**
     * 加载所有位于 Themes 目录下的 .json 主题文件。
     */
    static LoadAllThemes() {
        if (!DirExist(this._themesDir)) {
            return ; 如果主题目录不存在，则跳过
        }

        Loop Files, this._themesDir . "\*.json" {
            try {
                local themeContent := FileRead(A_LoopFileFullPath)
                local themeData := jsongo.Parse(themeContent)
                local themeName := StrReplace(A_LoopFileName, ".json", "")
                this.Themes[themeName] := themeData
            } catch Error as e {
                MsgBox "主题文件解析失败: " . A_LoopFileName . "`n错误: " . e.Message . "`n该主题将被忽略。"
            }
        }
    }

    static CreateThemedWindow(options := "", title) {
        ; 1. 从配置服务获取当前激活的主题名称
        local activeThemeName := ConfigService.Get("GuiService.settings.activeTheme")

        ; 2. 获取主题对象，并实现备用逻辑
        local theme := ""
        if (this.Themes.Has(activeThemeName)) {
            theme := this.Themes[activeThemeName]
        } else if (this.Themes.Count > 0) {
            for name, themeObj in this.Themes {
                theme := themeObj
                activeThemeName := name
                break
            }
            MsgBox "警告：配置的主题 '" . ConfigService.Get("GuiService.settings.activeTheme") . "' 未找到。`n已自动回退到主题: '" . activeThemeName . "'",, "48"
        } else {
            throw Error("无法创建窗口，因为没有任何主题被成功加载。请检查 'Themes' 目录。")
        }

        ; 3. 创建并设置GUI样式
        local gui := Gui("-DPIScale " . options, title)
        gui.Opt("-Theme")

        gui.BackColor := theme.colors.bg
        gui.SetFont("s" . theme.fonts.size, theme.fonts.family)
        
        gui.Theme := theme 

        return gui
    }

    static RegisterGui(name, guiObj) {
        if (this._managedGuis.Has(name)) {
            try {
                this._managedGuis[name].Destroy()
            }
        }
        this._managedGuis[name] := guiObj
    }

    static ShowSingletonWindow(name, creationFunc) {
        if (this._managedGuis.Has(name) && WinExist("ahk_id " . this._managedGuis[name].Hwnd)) {
            WinActivate("ahk_id " . this._managedGuis[name].Hwnd)
        } else {
            local gui := creationFunc()
            gui.OnEvent("Close", (*) => this._managedGuis.Delete(name))
            gui.Show()
        }
    }

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

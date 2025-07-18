; Core/Views/ModeIndicatorGUI.ahk

#Requires AutoHotkey v2.0

class ModeIndicatorGUI {
    static IndicatorGui := ""
    static DefaultPosition := { x: 100, y: A_ScreenHeight - 150 }

    /**
     * 创建一个用于显示模式的GUI窗口。
     */
    static Init() {
        this.IndicatorGui := GuiService.CreateThemedWindow("+AlwaysOnTop -Caption +ToolWindow", "ModeIndicator")
        GuiService.RegisterGui("ModeIndicator", this.IndicatorGui)
        this.IndicatorGui.BackColor := this.IndicatorGui.Theme.bg
        this.IndicatorGui.SetFont("s12 Bold", this.IndicatorGui.Theme.fontFamily)
        this.IndicatorGui.Add("Text", "vModeText cFFFFFF Center", "")
    }

    /**
     * 显示或更新模式指示器。
     * @param modeInfo {Object} 模式信息，来自 HotkeyManager.Modes
     * @param position {Object} (可选) {x, y} 显示位置
     */
    static Show(modeInfo, position := unset) {
        if !IsObject(this.IndicatorGui)
            return

        ; 更新内容和样式
        this.IndicatorGui["ModeText"].Value := " " . modeInfo.text . " "
        this.IndicatorGui.BackColor := modeInfo.bgColor
        this.IndicatorGui["ModeText"].Opt("c" . modeInfo.textColor)

        ; 调整大小以适应文本
        this.IndicatorGui.Show("AutoSize NA")

        ; 计算位置
        local pos := IsSet(position) ? position : this.DefaultPosition
        this.IndicatorGui.Show("X" . pos.x . " Y" . pos.y . " NA")

        ; 设置超时隐藏
        if (modeInfo.timeout > 0) {
            SetTimer () => this.Hide(), -Abs(modeInfo.timeout)
        }
    }

    /**
     * 隐藏模式指示器。
     */
    static Hide() {
        if IsObject(this.IndicatorGui)
            this.IndicatorGui.Hide()
    }
}
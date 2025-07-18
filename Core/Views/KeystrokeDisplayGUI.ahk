; Core/Views/KeystrokeDisplayGUI.ahk

#Requires AutoHotkey v2.0

class KeystrokeDisplayGUI {
    static DisplayGui := ""
    static DefaultPosition := { x: A_ScreenWidth / 2 - 200, y: A_ScreenHeight - 300 }
    static MaxItems := 10

    static Init() {
        this.DisplayGui := GuiService.CreateThemedWindow("+AlwaysOnTop -Caption +ToolWindow", "KeystrokeDisplay")
        GuiService.RegisterGui("KeystrokeDisplay", this.DisplayGui)

        this.DisplayGui.BackColor := this.DisplayGui.Theme.bg
    }

    /**
     * 显示或更新按键提示窗口，支持两种模式。
     * 模式1 (简单模式): Show(text) - 显示单个格式化热键字符串。
     * 模式2 (列表模式): Show(currentSeq, mappings) - 显示序列引导列表。
     */
    static Show(param1, param2 := unset) {
        if !IsObject(this.DisplayGui)
            return

        ; 清理上一次的动态控件
        this.ClearDynamicControls()

        if (param1 == "") {
            this.DisplayGui.Hide()
            return
        }

        if (IsSet(param2)) {
            ; --- 模式2: 列表模式 (which-key) ---
            this.BuildListView(param1, param2)
        } else {
            ; --- 模式1: 简单模式 (单个热键) ---
            this.BuildSimpleView(param1)
        }

        this.DisplayGui.Show("AutoSize NA")
        this.DisplayGui.Show("X" . this.DefaultPosition.x . " Y" . this.DefaultPosition.y . " NA")
    }

    /**
     * 内部方法：构建简单视图，用于显示 "Ctrl+X" 等
     */
    static BuildSimpleView(text) {
        local theme := this.DisplayGui.Theme
        this.DisplayGui.SetFont("s16 Bold", theme.fontFamily)
        this.DisplayGui.Add("Text", "vSimpleText c" . theme.error . " Center", " " . text . " ") ; 使用主题错误色
    }

    /**
     * 内部方法：构建列表视图，用于 which-key 风格的引导
     */
    static BuildListView(currentSeq, mappings) {
        local theme := this.DisplayGui.Theme
        this.DisplayGui.SetFont("s10", theme.fontFamily)

        ; 添加标题行
        this.DisplayGui.Add("Text", "vCurrentSequence c" . theme.accent, " " . currentSeq)
        this.DisplayGui.Add("Progress", "w400 h1 c" . theme.border . " -Theme", 100)

        local yPos := 40
        for i, mapping in mappings {
            if (i > this.MaxItems) {
                break
            }
            this.DisplayGui.Add("Text", "x10 y" . yPos . " c" . theme.success, mapping.key)
            this.DisplayGui.Add("Text", "x50 y" . yPos . " c" . theme.text, mapping.hint)
            yPos += 20
        }
    }

    /**
     * 清理所有动态添加的控件，以便在不同视图间切换。
     */
    static ClearDynamicControls() {
        While (ctrl := this.DisplayGui[1]) {
            ctrl.Destroy()
        }
    }

    static Hide() {
        if IsObject(this.DisplayGui)
            this.DisplayGui.Hide()
    }
}
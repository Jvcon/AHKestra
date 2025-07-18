; Core/Views/PluginConfigGuiFactory.ahk - 插件独立配置窗口生成器
#Requires AutoHotkey v2.0

class PluginConfigGuiFactory {

    /**
     * 核心公开方法：为指定插件创建并显示一个独立的配置窗口。
     * @param pluginName {String} 插件的名称。
     * @param ownerHwnd {Integer} 父窗口句柄，使其成为一个模态对话框。
     */
    static CreateAndShow(pluginName, ownerHwnd) {
        local guiName := "PluginConfig_" . pluginName
        if (GuiService._managedGuis.Has(guiName) && WinExist("ahk_id " . GuiService._managedGuis[guiName].Hwnd)) {
            WinActivate("ahk_id " . GuiService._managedGuis[guiName].Hwnd)
            return
        }

        ; 获取构建UI所需的数据
        local schema := ConfigService.GetSchema()[pluginName].settings
        if (!IsObject(schema) || schema.Count = 0) {
            MsgBox "Plugin '" . pluginName . "' has no configurable options.", "Info", "64"
            return
        }
        local currentConfig := ConfigService.GetCurrentConfig()[pluginName].settings

        ; 根据 ownerHwnd 是否存在，决定是否添加 +Owner 选项
        local options := (ownerHwnd != 0) ? "+Owner" . ownerHwnd : ""
        ; 使用 GuiService 创建一个带主题的的独立窗口
        local gui := GuiService.CreateThemedWindow(options, pluginName . " - Configuration")
        GuiService.RegisterGui(guiName, gui)

        gui.OnEvent("Close", this._onPluginConfigClose.bind(this, guiName))

        local controls := Map()
        local yPos := 20

        ; --- 动态渲染控件 (逻辑与之前在SettingsGui中类似) ---
        for key, spec in schema {
            if (!spec.HasProp("label")) {
                continue
            }
            local controlId := pluginName . "_" . key
            local currentValue := currentConfig.Has(key) ? currentConfig[key] : spec.default

            gui.Add("Text", "x20 y" . yPos . " w150 r1", spec.label . ":")

            local ctrl
            Switch spec.type {
                Case "boolean":
                    ctrl := gui.Add("CheckBox", "x180 y" . (yPos - 2) . " v" . controlId . " Checked" . currentValue)
                Case "number":
                    ctrl := gui.Add("Edit", "x180 y" . (yPos - 3) . " w100 v" . controlId, currentValue)
                Case "string":
                    ctrl := gui.Add("Edit", "x180 y" . (yPos - 3) . " w300 v" . controlId, currentValue)
                Case "dropdown":
                    ctrl := gui.Add("DropDownList", "x180 y" . (yPos - 3) . " w250 v" . controlId)
                    for item in spec.options {
                        ctrl.Add(item.label)
                        if (item.value == currentValue) {
                            ctrl.Choose(item.label)
                        }
                    }
            }
            controls[key] := { ctrl: ctrl, spec: spec }

            if (spec.HasProp("description")) {
                gui.Add("Text", "x+10 y" . yPos . " c" . gui.Theme.colors.border, "(?)").OnEvent("ToolTip", spec.description)
            }

            yPos += 30
        }

        ; --- 添加通用的保存和取消按钮 ---
        gui.Add("Button", "x" . (gui.GetPos().w - 180) . " y" . (yPos + 10) . " w80 h25 Default", "Save").OnEvent("Click",
            (*) => this._savePluginConfig(pluginName, controls, gui))

        gui.Add("Button", "x+10", "Cancel").OnEvent("Click", (*) => gui.Destroy())

        gui.Show("AutoSize")
        GuiService.RegisterGui("PluginConfig_" . pluginName, gui)
    }

    static _onPluginConfigClose(guiName, guiCtrl) {
        GuiService._managedGuis.Delete(guiName)
    }

    /**
     * 私有辅助方法：通用的插件配置保存逻辑。
     */
    static _savePluginConfig(pluginName, controls, gui) {
        for key, data in controls {
            local ctrl := data.ctrl, spec := data.spec, newValue := ""
            Switch spec.type {
                Case "boolean": newValue := ctrl.Value
                Case "dropdown":
                    for item in spec.options {
                        if (item.label == ctrl.Text) {
                            newValue := item.value
                            break
                        }
                    }
                Default: newValue := ctrl.Value
            }
            ConfigService.Set(pluginName . ".settings." . key, newValue)
        }
        ConfigService.Save()
        EventService.Trigger("Config.Changed", { plugin: pluginName }) ; 触发带插件名的事件
        gui.Destroy()
        MsgBox(pluginName . " settings have been saved.", "Configuration Saved", 64)
    }
}
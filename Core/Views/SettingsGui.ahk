; Core/Views/SettingsGui.ahk - 图形化配置界面
#Requires AutoHotkey v2.0

class SettingsGui {
    static _gui := ""
    static _controls := Map() ; 用于存储关键控件的引用，方便读写数据

    /**
     * 公开方法：显示设置窗口（单例模式）
     */
    static Show() {
        ; 使用 GuiService 确保只有一个设置窗口实例
        GuiService.ShowSingletonWindow("Settings", this._createWindow.Bind(this))
    }

    /**
     * 内部方法：创建并初始化GUI窗口
     * @returns {Gui} 创建的Gui对象
     */
    static _createWindow() {
        this._gui := GuiService.CreateThemedWindow("+Resize", "AHKestra - Settings")
        this._gui.OnEvent("Close", (*) => this._onCancel())

        local theme := this._gui.Theme
        this._gui.SetFont("s" . theme.fonts.size, theme.fonts.family)

        ; 添加Tab控件，这是构建多页面界面的基础
        ; AutoHotkey v2文档和社区帖子中都展示了这种用法
        ; [GuiCreate() - Auto Hotkey Documentation](https://documentation.help/AHK_H-2.0/GuiCreate.htm){target="_blank" class="gpt-web-url"}
        local tab := this._gui.Add("Tab3", "w780 h500", ["General", "Hotkeys", "Plugins"])
        tab.OnEvent("Change", this._onTabChange.Bind(this))

        ; 分别构建每个标签页的内容
        this._buildGeneralTab(tab, theme)
        this._buildHotkeyTab(tab, theme)
        this._buildPluginsTab(tab, theme)

        ; 添加底部的“保存”、“应用”、“取消”按钮
        this._gui.Add("Button", "x530 y520 w80 h25", "Save").OnEvent("Click", this._onSave.Bind(this))
        this._gui.Add("Button", "x620 y520 w80 h25", "Apply").OnEvent("Click", this._onApply.Bind(this))
        this._gui.Add("Button", "x710 y520 w80 h25", "Cancel").OnEvent("Click", this._onCancel.Bind(this))

        this._gui.Show()
        return this._gui
    }

    ; =============================================================
    ; Tab 构建方法
    ; =============================================================

    static _buildGeneralTab(tab, theme) {
        tab.UseTab(1) ; 激活 "General" 标签页

        ; --- 主题设置 ---
        local gbTheme := this._gui.AddGroupBox("x10 y40 w370 h60", "Appearance")
        this._gui.AddText("x20 y65", "Active Theme:")
        local ddlTheme := this._gui.AddDropDownList("x120 y62 w250 vDdlTheme", [])
        for name, themeObj in GuiService.Themes {
            ddlTheme.Add(name)
        }
        ddlTheme.Choose(ConfigService.Get("GuiService.settings.activeTheme"))
        this._controls["ddlTheme"] := ddlTheme

        ; --- 热键管理器设置 ---
        local gbHotkey := this._gui.AddGroupBox("x10 y110 w370 h60", "Hotkey Manager")
        this._gui.AddText("x20 y135", "Leader Key:")
        local editLeader := this._gui.AddEdit("x120 y132 w250", ConfigService.Get("HotkeyManager.settings.leaderKey"))
        this._controls["leaderKey"] := editLeader
    }

    static _buildHotkeyTab(tab, theme) {
        tab.UseTab(2) ; 激活 "Hotkeys" 主标签页

        ; 在主标签页内创建一个新的 Tab 控件，用于分类管理
        local hotkeyTab := this._gui.Add("Tab3", "x10 y40 w760 h450", ["Regular", "Layered", "Sequence"])
        this._controls["hotkeyTab"] := hotkeyTab

        ; --- 构建 "Regular" 子标签页 ---
        hotkeyTab.UseTab(1)
        local lvRegular := this._gui.AddListView("w758 h425 vLvRegularHotkeys", ["Plugin|150", "Hotkey|200", "Description|398"])
        this._controls["lvRegularHotkeys"] := lvRegular
        for def in HotkeyManager.GetRegularHotkeys() {
            lvRegular.Add(, def.plugin, this._formatKeysForDisplay(def), def.hint)
        }

        ; --- 构建 "Layered" 子标签页 ---
        hotkeyTab.UseTab(2)
        local lvLayered := this._gui.AddListView("w758 h425 vLvLayeredHotkeys", ["Plugin|150", "Hotkey|200", "Description|398"])
        this._controls["lvLayeredHotkeys"] := lvLayered
        for def in HotkeyManager.GetLayeredHotkeys() {
            lvLayered.Add(, def.plugin, this._formatKeysForDisplay(def), def.hint)
        }

        ; --- 构建 "Sequence" 子标签页 ---
        hotkeyTab.UseTab(3)
        local lvSequence := this._gui.AddListView("w758 h425 vLvSequenceHotkeys", ["Plugin|150", "Sequence|200", "Description|398"])
        this._controls["lvSequenceHotkeys"] := lvSequence
        for def in HotkeyManager.GetSequenceHotkeys() {
            lvSequence.Add(, def.plugin, this._formatKeysForDisplay(def), def.hint)
        }
    }


    static _buildPluginsTab(tab, theme) {
        tab.UseTab(3)

        local lvPlugins := this._gui.AddListView("x10 y40 w760 h450 r20 vLvPlugins", ["Plugin Name|200", "Version|80", "Author|150", "Description|320"])
        this._controls["lvPlugins"] := lvPlugins
        
        ; 为双击事件添加回调，用于打开插件配置
        lvPlugins.OnEvent("DoubleClick", this._onPluginConfig.Bind(this))

        local loadedPlugins := PluginManager.GetLoadedPlugins()
        for name, instance in loadedPlugins {
            local manifest := instance.context
            local hasConfig := manifest.HasProp("configuration") && manifest.configuration.Count > 0
            
            ; 将插件名称和是否有配置的信息附加到行数据中
            local row := lvPlugins.Add({Name: name, HasConfig: hasConfig}, name, manifest.version, manifest.author, manifest.description)
            
            ; 如果插件没有可配置项，则将其显示为灰色
            if (!hasConfig) {
                lvPlugins.Modify(row, "Gray")
            }
        }
    }

    ; =============================================================
    ; 事件处理方法
    ; =============================================================

    static _onSave() {
        this._onApply()
        ConfigService.Save()
        this._gui.Destroy()
        this._gui := ""
    }

    static _onApply() {
        ; 保存 General 标签页的设置
        ConfigService.Set("GuiService.settings.activeTheme", this._controls.ddlTheme.Text)
        ConfigService.Set("HotkeyManager.settings.leaderKey", this._controls.leaderKey.Value)

        MsgBox "Settings applied. Some changes may require a restart to take effect.", "AHKestra", "4096" ; 4096 = System Modal
    }

    static _onCancel() {
        this._gui.Destroy()
        this._gui := ""
    }


    static _onTabChange(guiCtrl, info) {
        ; 未来可以在这里做一些标签页切换时的动态加载，提升性能
    }

    static _onPluginConfig(lv, rowNum) {
        if (rowNum = 0) {
            return
        } 
        local rowData := lv.Get(rowNum)
        if (!rowData.HasConfig) {
            Tooltip "This plugin has no configurable options.", lv.Hwnd
            SetTimer (*) => Tooltip(), -2000
            return
        }
        
        local pluginName := rowData.Name
        
        ; 委托给工厂类来创建和显示窗口
        PluginConfigGuiFactory.CreateAndShow(pluginName, this._gui.Hwnd)
    }

    ; =============================================================
    ; 辅助方法
    ; =============================================================

    static _formatKeysForDisplay(def) {
        local leaderStr := "<Leader>"
        switch def.type {
            case "regular":
                return def.keys
            case "layer":
                return def.keys[1] . " + " . def.keys[2]
            case "sequence":
                ; 在新的 GetSequenceHotkeys 方法中，我们已经移除了 leader key
                ; 所以这里直接 join 即可
                return def.keys.Join(" ")
            default:
                ; 确保即使有未知类型也能显示
                return IsObject(def.keys) ? def.keys.Join(", ") : def.keys
        }
    }
}
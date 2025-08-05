/**
 * PluginService (核心服务)
 * 负责插件的整个生命周期管理，包括加载、实例化、启用、停用和能力注册。
 * 它作为ConfigService（数据）和实际插件实例（运行时）之间的桥梁。
 */
class PluginService {
    static _pluginInstances := Map()

    static Init() {
        this._loadAllPlugins()
        this._enableInitialPlugins()
    }

    /**
     * [公共API] 启用一个插件。
     * @param pluginName {String} 要启用的插件名称。
     */
    static EnablePlugin(pluginName) {
        if (this._pluginInstances.Has(pluginName)) {
            local pluginInstance := this._pluginInstances[pluginName]
            pluginInstance.Enable()
            if (pluginInstance.status == "enabled") {
                ConfigService.SetPluginStatus(pluginName, "enabled")
            }
            this._registerContributions(pluginInstance)
        }
    }

    /**
     * [公共API] 停用一个插件。
     * @param pluginName {String} 要停用的插件名称。
     */
    static DisablePlugin(pluginName) {
        if (this._pluginInstances.Has(pluginName)) {
            local pluginInstance := this._pluginInstances[pluginName]
            pluginInstance.Disable()
            if (pluginInstance.status != "enabled") {
                ConfigService.SetPluginStatus(pluginName, "disabled")
            }
            this._unregisterContributions(pluginInstance)
        }
    }

    /**
     * [公共API] 获取所有已加载的插件实例。
     * @returns {Map}
     */
    static GetAllPluginInstances() {
        return this._pluginInstances
    }
   
    /**
     * [步骤1] 加载所有在ConfigService中发现的插件。
     * 这一步只负责动态加载代码和创建插件实例，但不启用它们。
     */
    static _loadAllPlugins() {
        local allPluginsInfo := ConfigService.GetAllPlugins()

        for pluginName, pluginDef in allPluginsInfo {
            try {
                local mainScriptPath := pluginDef.info.dir . '\' . pluginDef.info.main
                if (!FileExist(mainScriptPath)) {
                    throw Error("插件主文件未找到: " . mainScriptPath)
                }

                local PluginClass := #Include %mainScriptPath%

                if (!IsObject(PluginClass) || !(PluginClass.Prototype is Plugin)) {
                    throw Error("插件主文件 '" . mainScriptPath . "' 没有返回一个继承自 Plugin 的类。")
                }

                ; 创建API实例并注入
                local api := Api(pluginDef.info)

                ; 创建插件实例
                local pluginInstance := PluginClass(pluginDef.info, api)

                this._pluginInstances[pluginName] := pluginInstance
            } catch Error as e {
                Error("加载插件 '" . pluginName . "' 失败: " . e.Message)
            }
        }
    }

    /**
     * [步骤2] 启用在ConfigService中标记为"enabled"的插件。
     */
    static _enableInitialPlugins() {
        local allPluginsInfo := ConfigService.GetAllPlugins()
        for pluginName, pluginDef in allPluginsInfo {
            if (pluginDef.status == "enabled" && this._pluginInstances.Has(pluginName)) {
                this.EnablePlugin(pluginName)
            }
        }
    }

    /**
     * 核心注册逻辑：根据manifest中的声明，为插件注册其提供的能力。
     * 这个方法在插件被成功启用后调用。
     * @param pluginInstance {Plugin} 已启用的插件实例。
     */
    static _registerContributions(pluginInstance) {
        local pluginInfo := pluginInstance.info
        local pluginName := pluginInfo.name
        ; 从ConfigService获取原始的、未实例化的插件定义
        local pluginDef := ConfigService.GetPlugin(pluginName)

        ; --- 注册热键 ---
        if (pluginDef.Has("hotkeys")) {
            for _, hotkeyDef in pluginDef.hotkeys {
                if (!pluginInstance.HasMethod(hotkeyDef.function)) {
                    throw Error("Manifest中声明的函数 '" . hotkeyDef.function . "' 在插件 '" . pluginName . "' 中未实现。")
                }
                local callback := pluginInstance[hotkeyDef.function].Bind(pluginInstance)
                HotkeyManager.Register(pluginName, {
                    keys: hotkeyDef.keys,
                    type: hotkeyDef.type,
                    callback: callback,
                    hint: hotkeyDef.Has("hint") ? hotkeyDef.hint : ""
                })
            }
        }

        ; --- 注册菜单项 ---
        if (pluginDef.Has("menuItems")) {
            for _, menuItemDef in pluginDef.menuItems {
                if (!pluginInstance.HasMethod(menuItemDef.function)) {
                    throw Error("Manifest中声明的函数 '" . menuItemDef.function . "' 在插件 '" . pluginName . "' 中未实现。")
                }
                local callback := pluginInstance[menuItemDef.function].Bind(pluginInstance)

                local condition := ""
                if (menuItemDef.Has("condition")) {
                    if (!pluginInstance.HasMethod(menuItemDef.condition)) {
                        throw Error("Manifest中声明的条件函数 '" . menuItemDef.condition . "' 在插件 '" . pluginName . "' 中未实现。")
                    }
                    condition := pluginInstance[menuItemDef.condition].Bind(pluginInstance)
                }
                ContextMenuManager.Register(pluginName, menuItemDef.path, condition, callback)
            }
        }

        ; --- 注册文本扩展 ---
        if (pluginDef.Has("espassions")) {
            for _, configPath in pluginDef.espassions {
                local fullPath := pluginInfo.dir . "\" . configPath
                if (FileExist(fullPath)) {
                    TextEngineManager.RegisterExpansionFromYaml(fullPath)
                } else {
                    Error("插件 '" . pluginName . "' 中声明的Espanso配置文件未找到: " . fullPath)
                }
            }
        }
    }

    /**
     * 核心注销逻辑：清理一个插件注册的所有能力。
     * @param pluginInstance {Plugin} 即将被停用的插件实例。
     */
    static _unregisterContributions(pluginInstance) {
        local pluginName := pluginInstance.info.name
        HotkeyManager.Unregister(pluginName)
        ContextMenuManager.Unregister(pluginName)
        TextEngineManager.Unregister(pluginName)
    }

    /**
     * [API方法] 为插件提供统一的日志记录接口。
     */
    static Log(pluginName, level, message) {
        ; TODO: 未来可以接入一个真正的日志服务。
        OutputDebug("[" . pluginName . "][" . level . "] " . message)
    }
}
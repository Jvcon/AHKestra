class PluginService {
    static LoadedPlugins := []
    static LoadPlugins() {
        local pluginsToLoad := ConfigService.GetActivePlugins()
        for pluginInfo in pluginsToLoad {
            try {
                this.LoadPlugin(pluginInfo)
            } catch Error as e {
                MsgBox "加载插件失败: " . pluginInfo.name . "`n`n" . e.Message . "`n文件: " . e.File . "`n行: " . e.Line
            }
        }
    }

    static LoadPlugin(pluginInfo) {
        mainScriptPath := pluginInfo.dir . "\" . pluginInfo.main
        if !FileExist(mainScriptPath)
            throw Error("插件主文件未找到: " . pluginInfo.main)

        ; 2. 动态包含插件代码并创建实例
        #Include %mainScriptPath%
        if !IsObject(Plugin)
            throw Error("插件主文件中未定义 'Plugin' 类。")

       

        local api := PluginApi(pluginInfo.name)
        if (pluginInstance.HasMethod("Init")) {
            pluginInstance.Init(pluginInfo,api) ; 将 API 对象注入插件
        }

        this.LoadedPlugins[pluginInfo.name] := pluginInstance

        local contributions := ConfigService.Get(pluginInfo.name . ".contributes")
        this.ProcessContributions(pluginInstance, pluginInfo, contributions)

        EventService.Trigger("Plugin.Loaded", pluginInfo.name)
    }

    static ProcessContributions(pluginInstance, pluginInfo, contributions) {
        if !IsObject("contributes")
            return

        local leaderKey := ConfigService.Get("HotkeyManager.settings.leaderKey")

        ; 处理快捷键
        if (contributions.Has("hotkeys")) {
            for hotkeyDef in contributions.hotkeys {
                if (!pluginInstance.HasMethod(hotkeyDef.function)) {
                    throw Error("Manifest 中声明的函数 '" . hotkeyDef.function . "' 在插件 " . pluginInfo.name . " 中未实现。")
                }
                local finalKeys := hotkeyDef.keys
                if (hotkeyDef.type == "sequence") {
                    ; 创建一个新的数组，将全局 leaderKey 作为第一个元素
                    finalKeys.InsertAt(1, leaderKey)
                }
                ; 动态创建回调，使其调用插件实例的对应方法
                local callback := (ctx) => pluginInstance[hotkeyDef.function](ctx)

                HotkeyManager.Register(pluginInfo.name, {
                    keys: finalKeys,
                    type: hotkeyDef.type,
                    callback: callback,
                    hint: hotkeyDef.hint
                })
            }
        }

        if (contributions.Has("menuItems")) {
            for menuItemDef in contributions.menuItems {
                if (!pluginInstance.HasMethod(menuItemDef.function))
                    throw Error("Manifest 中声明的函数 '" . menuItemDef.function . "' 在插件 " . pluginInfo.name . " 中未实现。")

                local callback := (ctx) => pluginInstance[menuItemDef.function](ctx)

                local condition := ""
                if (menuItemDef.HasProp("condition")) {
                    if (!pluginInstance.HasMethod(menuItemDef.condition))
                        throw Error("Manifest 中声明的条件函数 '" . menuItemDef.condition . "' 在插件 " . pluginInfo.name . " 中未实现。")
                    condition := (ctx) => pluginInstance[menuItemDef.condition](ctx)
                }

                ContextMenuManager.Register(pluginInfo.name, menuItemDef.path, condition, callback)
            }
        }

        if (contributions.Has("expansions")) {
            for configPath in contributions.expansions {
                local fullPath := pluginInstance.context.dir . "\" . configPath
                if FileExist(fullPath) {
                    TextEngineManager.RegisterExpansionFromYaml(fullPath)
                } else {
                    MsgBox "插件 " . pluginInfo.name . " 中声明的 Espanso 配置文件未找到: " . fullPath
                }
            }
        }

        if (contributions.Has("events")) {
            EventLoaderService.RegisterProvider(pluginInfo.name, pluginInfo.dir, contributions.eventProviders)
        }
    }

    static GetLoadedPlugins() {
        return this.LoadedPlugins
    }

    static GetActivePlugins() {
        local activePlugins := []
        for name, pluginInfo in ConfigServices._plugins {
            if (pluginInfo.enabled) {
                activePlugins.Push(pluginInfo)
            }
        }
        return activePlugins
    }
}
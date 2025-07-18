class PluginManager {
    static LoadedPlugins := []
    static LoadPlugins() {
        Loop Files, APP_PLUGINS_DIR . "\*", "D" {
            try {
                this.LoadPlugin(A_LoopFileFullPath)
            } catch Error as e {
                MsgBox "加载插件失败: " . A_LoopFileName . "`n`n" . e.Message . "`n文件: " . e.File . "`n行: " . e.Line
            }
        }
    }

    static LoadPlugin(pluginDir) {
        manifestPath := pluginDir . "\manifest.json"
        if !FileExist(manifestPath)
            return ; 没有 manifest.json，跳过此目录

        ; 1. 读取并解析 Manifest
        manifest := jsongo.Parse(FileRead(manifestPath))
        this.ValidateManifest(manifest) ; 校验

        mainScriptPath := pluginDir . "\" . manifest.main
        if !FileExist(mainScriptPath)
            throw Error("插件主文件未找到: " . manifest.main)

        ; 2. 动态包含插件代码并创建实例
        #Include %mainScriptPath%
        if !IsObject(Plugin)
            throw Error("插件主文件中未定义 'Plugin' 类。")

        pluginContext := {
            name: manifest.name,
            version: manifest.version,
            dir: pluginDir,
        }

        pluginInstance := Plugin(pluginContext)
        this.LoadedPlugins[manifest.name] := pluginInstance

        ; 3. 处理声明式贡献
        this.ProcessContributions(pluginInstance, manifest)

        ; 4. (可选) 调用插件的程序化初始化方法
        if (pluginInstance.HasMethod("Init")) {
            pluginInstance.Init()
        }

        EventService.Trigger("Plugin.Loaded", manifest.name)
    }

    static ProcessContributions(pluginInstance, manifest) {
        if !manifest.HasProp("contributes")
            return

        local contributions := manifest.contributes
        local leaderKey := ConfigService.Get("HotkeyManager.settings.leaderKey")

        ; 处理快捷键
        if (contributions.HasProp("hotkeys")) {
            for hotkeyDef in contributions.hotkeys {
                if (!pluginInstance.HasMethod(hotkeyDef.function)) {
                    throw Error("Manifest 中声明的函数 '" . hotkeyDef.function . "' 在插件中未实现。")
                }
                local finalKeys := hotkeyDef.keys
                if (hotkeyDef.type == "sequence") {
                    ; 创建一个新的数组，将全局 leaderKey 作为第一个元素
                    finalKeys.InsertAt(1, leaderKey)
                }
                ; 动态创建回调，使其调用插件实例的对应方法
                local funcName := hotkeyDef.function
                local callback := (ctx) => pluginInstance[funcName](ctx)

                HotkeyManager.Register(manifest.name, {
                    keys: finalKeys,
                    type: hotkeyDef.type,
                    callback: callback,
                    hint: hotkeyDef.hint
                })
            }
        }

        if (contributions.HasProp("menuItems")) {
            for menuItemDef in contributions.menuItems {
                if (!pluginInstance.HasMethod(menuItemDef.function))
                    throw Error("Manifest 中声明的函数 '" . menuItemDef.function . "' 在插件中未实现。")

                local funcName := menuItemDef.function
                local callback := (ctx) => pluginInstance[funcName](ctx)

                local condition := ""
                if (menuItemDef.HasProp("condition")) {
                    if (!pluginInstance.HasMethod(menuItemDef.condition))
                        throw Error("Manifest 中声明的条件函数 '" . menuItemDef.condition . "' 在插件中未实现。")

                    local condFuncName := menuItemDef.condition
                    condition := (ctx) => pluginInstance[condFuncName](ctx)
                }

                ContextMenuManager.Register(manifest.name, menuItemDef.path, condition, callback)
            }
        }

        if (contributions.HasProp("expansions")) {
            for configPath in contributions.expansions {
                local fullPath := pluginInstance.context.dir . "\" . configPath
                if FileExist(fullPath) {
                    TextEngineManager.RegisterExpansionFromYaml(fullPath)
                } else {
                    MsgBox "插件 " . manifest.name . " 中声明的 Espanso 配置文件未找到: " . fullPath
                }
            }
        }
    }

    static ValidateManifest(manifest) {
        required := ["name", "version", "main"]
        for field in required {
            if !manifest.HasProp(field) {
                throw Error("Manifest 文件缺少必要字段: " . field)
            }
        }
        return true
    }
}
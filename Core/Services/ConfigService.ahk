; Core/Services/ConfigService.ahk - 配置管理服务

#Requires AutoHotkey v2.0

/**
 * ConfigService (核心服务层)
 * 负责管理整个应用程序的配置。
 * 它处理配置的加载、合并、访问、保存，并为表示层提供渲染UI所需的Schema。
 */
class ConfigService {
    ; --- 私有静态属性 ---
    static _configFilePath := A_ScriptDir . "\..\..\config.json" ; 相对于Core/Services/目录
    static _config := Map()        ; 运行时合并后的最终配置对象
    static _defaults := Map()      ; 所有模块注册的默认配置
    static _schema := Map()        ; 所有模块注册的配置声明 (用于UI生成)
    static _plugins := Map()       ; 新增：存储所有发现的插件信息

    /**
     * [注册接口] 供所有Manager和插件在初始化时调用。
     * @param moduleName {String} 模块或插件的名称，如 "QuickAccess"。
     * @param groupName {String} 配置分组，如 "hotkeys" 或 "settings"。
     * @param groupDefaults {Map} 该分组的默认值。
     * @param groupSchema {Map} (可选) 该分组的完整配置声明。
     */
    static RegisterDefaults(moduleName, groupName, groupDefaults, groupSchema := unset) {
        if (!this._defaults.Has(moduleName)) {
            this._defaults[moduleName] := Map()
            this._schema[moduleName] := Map()
        }
        this._defaults[moduleName][groupName] := groupDefaults
        if (IsSet(groupSchema)) {
            this._schema[moduleName][groupName] := groupSchema
        }
    }

    /**
     * [生命周期方法] 在应用启动时加载配置。
     * 读取磁盘文件，并与所有已注册的默认配置进行深度合并。
     */
    static Load() {
        local diskConfig := Map()
        if (FileExist(this._configFilePath)) {
            try {
                ; 社区帖子证实了这种需求：解析JSON并转换为Map
                ; [Is there a native way to serialize/deseralize a map to/from a file in ...](https://www.autohotkey.com/boards/viewtopic.php?t=121553){target="_blank" class="gpt-web-url"}
                diskConfig := jsongo.Parse(FileRead(this._configFilePath))
            } catch Error as e {
                ; 如果JSON文件损坏，则忽略它，后续将完全使用默认值
                ToolTip "Configuration file is corrupted. Using default settings. Error: " . e.Message
            }
        }
        ; 深度合并，确保用户配置能覆盖默认值，同时所有键都存在
        this._config := this._DeepMerge(this._defaults, diskConfig)
        if (this._config.Has("plugins")) {
            for name, pluginInfo in this._plugins {
                if (this._config.plugins.Has(name)) {
                    pluginInfo.enabled := this._config.plugins[name]
                }
            }
        }
    }

    /**
     * [生命周期方法] 将当前内存中的配置保存到磁盘。
     */
    static Save() {
        try {
            if (!this._config.Has("plugins")) {
                this._config["plugins"] := Map()
            }
            for name, pluginInfo in this._plugins {
                this._config.plugins[name] := pluginInfo.enabled
            }
            FileOpen(this._configFilePath, "w", "UTF-8").Write(jsongo.Stringify(this._config, , 2))
        } catch Error as e {
            Error "Failed to save configuration file: " . e.Message
        }
    }

    /**
     * [访问器] 获取一个配置项的值。
     * @param keyPath {String} 支持点符号的路径，如 "QuickAccess.settings.notepadPath"。
     * @returns {*} 配置项的值，如果不存在则返回 Null。
     */
    static Get(keyPath) {
        local keys := StrSplit(keyPath, ".")
        local current := this._config
        for _, key in keys {
            if (!IsObject(current) || !current.Has(key)) {
                return "" ; 路径不存在，安全返回Null
            }
            current := current[key]
        }
        return current
    }

    /**
     * [修改器] 设置一个配置项的值。
     * @param keyPath {String} 支持点符号的路径。
     * @param value {*} 新的值。
     */
    static Set(keyPath, value) {
        local keys := StrSplit(keyPath, ".")
        if (keys[1] = "plugins" && keys.Length = 1) {
            throw Error("不允许直接覆盖整个 'plugins' 配置节。请使用 SetPluginStatus 方法。")
        }
        local current := this._config
        for i, key in keys {
            if (i == keys.Length) {
                current[key] := value
            } else {
                if (!current.Has(key) || !IsObject(current[key])) {
                    current[key] := Map()
                }
                current := current[key]
            }
        }
    }

    /**
     * [UI支持接口] 获取完整的配置Schema，供SettingsView动态构建界面。
     */
    static GetSchema() {
        return this._schema
    }

    /**
     * [UI支持接口] 获取当前完整的配置对象，供SettingsView填充界面初值。
     */
    static GetCurrentConfig() {
        return this._config
    }

    /**
     * 内部辅助函数，用于递归地合并两个Map对象。
     */
    static _DeepMerge(defaults, overrides) {
        local merged := Map()
        for k, v in defaults {
            if (overrides.Has(k) && IsObject(v) && IsObject(overrides[k])) {
                merged[k] := this._DeepMerge(v, overrides[k])
            } else if (overrides.Has(k)) {
                merged[k] := overrides[k]
            } else {
                merged[k] := v.Clone() ; 克隆以防止修改默认值对象
            }
        }
        for k, v in overrides {
            if (!merged.Has(k)) {
                merged[k] := v.Clone()
            }
        }
        return merged
    }

    /**
     * 扫描插件清单，构建插件信息列表，并注册默认配置。
     */
    static LoadPluginManifests() {
        ; [NEW LOGIC] 确保 _defaults 中有 plugins 这个键，以便 DeepMerge 能正常工作
        this._defaults["plugins"] := Map()

        Loop Files, APP_PLUGINS_DIR . "\*", "D" {
            local manifestPath := A_LoopFileFullPath . "\manifest.json"
            if !FileExist(manifestPath)
                continue
            try {
                local manifest := jsongo.Parse(FileRead(manifestPath))
                this._validateManifest(manifest)
                local pluginName := manifest.name

                this._plugins[pluginName] := Map(
                    "name", pluginName,
                    "version", manifest.version,
                    "main", manifest.main,
                    "dir", A_LoopFileFullPath,
                    "enabled", true ; 这是一个临时的默认值
                )

                this._defaults.plugins[pluginName] := true

                if (manifest.HasProp("settings")) {
                    local defaults := Map()
                    for key, spec in manifest.settings {
                        if (spec.HasProp("default")) {
                            defaults[key] := spec.default
                        }
                    }
                    this.RegisterDefaults(pluginName, "settings", defaults, manifest.settings)
                }

                if manifest.HasProp("contributes") {
                    this.RegisterDefaults(pluginName, "contributes", manifest.contributes)
                }

            } catch {
                MsgBox "解析插件 manifest 文件失败: " . A_LoopFileName
            }
        }
    }

    static _validateManifest(manifest) {
        required := ["name", "version", "main"]
        for field in required {
            if !manifest.HasProp(field) {
                throw Error("Manifest 文件缺少必要字段: " . field)
            }
        }
        return true
    }

}
; Core/Services/ConfigService.ahk - 配置管理服务

#Requires AutoHotkey v2.0

/**
 * ConfigService (核心服务层)
 * 负责管理整个应用程序的配置。
 * 它处理配置的加载、合并、访问、保存，并为表示层提供渲染UI所需的Schema。
 */
class ConfigService {
    ; --- 私有静态属性 ---
    static _configFilePath := A_ScriptDir . "\..\..\config.json"
    static _stateFilePath := A_ScriptDir . "\..\..\state.json"

    static latestSchemaVersion := "1.0"
    static _latestSchemaPath := A_ScriptDir . "\..\..\Assets\Schemas\manifest-v" . this.latestSchemaVersion . ".schema.json"

    static _configs := Map()        ; 运行时合并后的最终配置对象
    static _configSchemas := Map()        ; 所有模块注册的默认配置
    static _plugins := Map()       ; 新增：存储所有发现的插件信息

    static Init() {
        _loadAllPluginManifests() ; 加载所有插件的Manifest
        _loadState()              ; 加载插件状态
        _initializeConfigs()      ; 初始化配置项


    }

    /**
     * [生命周期方法] 将当前内存中的配置保存到磁盘。
     */
    static Save() {
        PersistenceHelper.WriteJson(this._configFilePath, this._configs)
    }

    static GetAllPlugins() {
        return this._plugins
    }

    static GetPlugin(pluginName) {
        return this._plugins.Has(pluginName) ? this._plugins[pluginName] : ""
    }

    static GetConfig(pluginName, key) {
        if (this._configs.Has(pluginName) && this._configs[pluginName].Has(key)) {
            return this._configs[pluginName][key]
        }
        return this._configSchemas[pluginName].Has("default") ? this._configSchemas[pluginName][key].default : ""
    }

    static GetConfigSchema(pluginName) {
        return this._configSchemas.Has(pluginName) ? this._configSchemas[pluginName] : Map()
    }

    static SetConfig(pluginName, key, value) {
        if (!this._configs.Has(pluginName)) {
            this._configs[pluginName] := Map()
        }
        this._configs[pluginName][key] := value
        this.Save() ; 每次修改配置后立即保存
    }

     /**
     * [公共API] 设置一个插件的状态并立即持久化。
     * 这是框架中唯一应该用来改变插件启用/禁用状态的地方。
     * @param pluginName {String} 插件的名称。
     * @param newStatus {String} 新的状态 ("enabled" 或 "disabled")。
     */
    static SetPluginStatus(pluginName, newStatus) {
        if (!this._plugins.Has(pluginName)) {
            return
        }
        this._plugins[pluginName].status := newStatus
        try {
            ; 为了健壮性，我们读取最新的state文件，只修改需要的条目，然后写回
            local stateData := PersistenceHelper.ReadJson(this._stateFilePath)
            if (!IsObject(stateData)) {
                stateData := Map() ; 如果文件为空或损坏，则创建一个新的
            }
            if (!stateData.Has("plugins")) {
                stateData["plugins"] := Map()
            }
            stateData.plugins[pluginName] := Map("status", newStatus)

            PersistenceHelper.WriteJson(this._stateFilePath, stateData)
        } catch e {
            Error("保存插件状态失败: " . e.Message)
        }
    }

    /**
     * 扫描插件清单，构建插件信息列表。
     */
    static _loadAllPluginManifests() {
        local manifestPaths := []
        ; 步骤1: 收集所有待验证的manifest文件路径
        Loop Files, APP_PLUGINS_DIR . "\*", "D" {
            local manifestPath := A_LoopFileFullPath . "\manifest.json"
            if FileExist(manifestPath) {
                manifestPaths.Push(manifestPath)
            }
        }

        if (manifestPaths.Length == 0) {
            return
        }

        try {
            local schemaData := PersistenceHelper.ReadJson(this._latestSchemaPath)
            for _, filePath in manifestPaths {
                local originalManifest := PersistenceHelper.ReadJson(filePath)
                local manifest := ManifestsMigration.Apply(originalManifest, this.latestSchemaVersion)
                local validationResult := JsonTools.Validate(schemaData, manifest)

                if (validationResult.ok) {
                    ; 验证通过，加载插件信息
                    local pluginName := manifest.name
                    local fileDir := StrReplace(filePath, "\manifest.json", "")

                    this._plugins[pluginName] := {
                        info: { name: manifest.name, version: manifest.version, dir: fileDir, main: manifest.main },
                        status: "disabled",
                        menuItems: manifest.contributes.Has("menuItems") ? manifest.contributes.menuItems : Map(),
                        hotkeys: manifest.contributes.Has("hotkeys") ? manifest.contributes.hotkeys : Map(),
                        espassions: manifest.contributes.Has("espassions") ? manifest.contributes.espassions : Map(),
                        events: manifest.providers.Has("events") ? manifest.providers.events : Map(),
                        contexts: manifest.providers.Has("contexts") ? manifest.providers.contexts : Map(),
                        conditions: manifest.providers.Has("conditions") ? manifest.providers.conditions : Map(),
                    }
                    if (manifest.Has("configs")) {
                        this._configSchemas[pluginName] := manifest.configs
                    }
                } else {
                    ; 验证失败，记录详细错误
                    Error("插件 Manifest 无效 (" . filePath . "):`n" . validationResult.errors.Join("`n"))
                }
            }
        } catch Error as e {
            Error("加载插件时发生严重错误: " . e.Message)
        }
    }

    static _loadState() {
        state := PersistenceHelper.ReadJson(this._stateFilePath)
        for pluginName, def in this._plugins {
            if (state.Has(pluginName)) {
                this._plugins[pluginName].status := state[pluginName]
            }
        }
    }

    /*
    * 加载manifest中声明的默认选项，以及加载configs中的配置项格式
    */
    static _initializeConfigs() {
        local defaults := Map()
        for pluginName, configItems in this._configSchemas {
            if (!defaults.Has(pluginName)) {
                defaults[pluginName] := Map()
            }
            for key, schema in configItems.properties {
                if (schema.Has("default")) {
                    defaults[pluginName][key] := schema.default
                } else {
                    defaults[pluginName][key] := ""
                }
            }
        }
        local userConfigs := Map()
        if (FileExist(this._configFilePath)) {
            userConfigs := PersistenceHelper.ReadJson(this._configFilePath)
            this._configs := this._DeepMerge(defaults, userConfigs)
        }
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
}
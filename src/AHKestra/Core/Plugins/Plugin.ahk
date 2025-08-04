class Plugin {
    info := ""          ; 从 manifest.json 加载的元数据 {name, id, version, ...}
    status := "loaded"  ; 插件的运行时状态: loaded, enabled, disabled, error
    _api := ""          ; 框架注入的API实例

    ; 构造函数，由PluginService在加载时调用
    __New(pluginInfo, frameworkApi) {
        this.info := pluginInfo
        this._api := frameworkApi
    }

    /**
     * 【生命周期方法】启用插件，由PluginService调用。
     * 子类不应重写此方法，而应重写 OnEnable。
     */
    Enable() {
        if (this.status == "enabled") {
            return
        }
        try {
            this.OnEnable()
            this.status := "enabled"
            EventService.Trigger("Plugin.Enabled", this.info.name)
        } catch Error {
            this.status := "error"
            Error("启用插件 " . this.info.name . " 失败: " . Error.Message)
        }
    }

    /**
     * 【生命周期方法】停用插件，由PluginService调用。
     * 子类不应重写此方法，而应重写 OnDisable。
     */
    Disable() {
        if (this.status != "enabled") {
            return
        }
        try {
            this.OnDisable()
            this.status := "disabled"
            EventService.Trigger("Plugin.Disabled", this.info.name)
        } catch Error {
            this.status := "error"
            Error("停用插件 " . this.info.name . " 失败: " . Error.Message)
        }
    }

    /**
     * 【安装时】插件作者在此实现其初始化逻辑。
     *  适用于一次性的初始化设置，如创建默认配置文件、检查依赖等。
     */
    OnLoad() {
        ; 插件作者可以在此进行一次性的初始化设置
    }

    /**
     * 【启用时】插件作者在此实现其注册逻辑。
     *  这是插件的核心启动点，用于注册监听器、创建UI、启动后台任务等。
     */
    OnEnable() {
        throw NotImplementedError("插件 " . this.info.name . " 必须实现 OnEnable 方法。")
    }

    /**
     * 【停用时】插件作者在此实现其撤销逻辑。
     */
    OnDisable() {
        throw NotImplementedError("插件 " . this.info.name . " 必须实现 OnDisable 方法。")
    }

    /**
     * 【卸载时】插件作者在此实现被框架卸载前调用。
     *  适用于永久性的清理工作，如删除用户数据、清理注册表项等。
     */
    OnUninstall() {
        ; 默认不做任何事
    }
}
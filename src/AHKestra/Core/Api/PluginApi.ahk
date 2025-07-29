class Api {
    _pluginInfo := ""

    ; 构造函数，名称保持一致
    __New(pluginInfo) {
        this._pluginInfo := pluginInfo
    }

    ; --- 日志模块 ---
    Log := {
        Info: (message) => PluginService.Log(this._pluginInfo.id, "INFO", message),
        Warn: (message) => PluginService.Log(this._pluginInfo.id, "WARN", message),
        Error: (message) => PluginService.Log(this._pluginInfo.id, "ERROR", message)
    }

    ; --- 事件模块 ---
    Events := {
        On: (eventName, callback, target := "") => Events.On(eventName, callback, target),
        Off: (eventName, callback, target := "") => Events.Off(eventName, callback, target),
        Trigger: (eventName, data := "") => Events.Trigger(eventName, data)
    }

    ; --- 配置模块 (隐式上下文) ---
    Config := {
        Get: (key, defaultValue := "") => ConfigService.GetConfigValue(this._pluginInfo.id, key, defaultValue)
    }

    ; --- GUI模块 (隐式上下文) ---
    Gui := {
        ShowNotification: (text) => GuiService.ShowNotification(text),
        ShowConfiguration: (ownerHwnd := 0) => GuiService.ShowPluginConfiguration(this._pluginInfo.id, ownerHwnd)
    }
}
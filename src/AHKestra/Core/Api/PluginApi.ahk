#Include <Core\Api\Events>
#Include <Core\Api\Contexts>
#Include <Core\Api\Conditions>

class PluginApi {
    _pluginInfo := ""

    ; 构造函数，名称保持一致
    __New(pluginInfo) {
        this._pluginInfo := pluginInfo
    }

    ; --- 日志模块 ---
    Log := {
        Info: (message) => PluginService.Log(this._pluginInfo.name, "INFO", message),
        Warn: (message) => PluginService.Log(this._pluginInfo.name, "WARN", message),
        Error: (message) => PluginService.Log(this._pluginInfo.name, "ERROR", message)
    }

    ; --- 事件模块 ---
    Events := {
        On: (eventName, callback, target := "") => Events.On(eventName, callback, target),
        Off: (eventName, callback, target := "") => Events.Off(eventName, callback, target),
        Trigger: (eventName, data := "") => Events.Trigger(eventName, data)
    }

    ; --- 上下文模块 ---
    Contexts := {
        GetCurrent: ()=> Contexts.GetCurrent()
    }

    ; --- 条件模块 ---
    Conditions := {
        Check: (conditionExpression,context) => Conditions.Check(conditionExpression, context)
    }

    ; --- 配置模块 (隐式上下文) ---
    Config := {
        Get: (key, defaultValue := "") => ConfigService.GetConfigValue(this._pluginInfo.name, key, defaultValue)
    }

    ; --- GUI模块 (隐式上下文) ---
    Gui := {
        ShowNotification: (text) => GuiService.ShowNotification(text),
        ShowConfiguration: (ownerHwnd := 0) => GuiService.ShowPluginConfiguration(this._pluginInfo.name, ownerHwnd)
    }
}
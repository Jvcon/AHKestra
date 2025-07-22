; Core/PluginApi.ahk - 供插件使用的统一接口
#Requires AutoHotkey v2.0

class PluginApi {
    __New(pluginName) {
        this.pluginName := pluginName
        
        ; 为插件提供一个带作用域的日志记录器
        this.Log := (message) => {}
    }

    ; --- Events API ---
    Events := {
        On: (eventName, callback, target := "") => Events.On(event, callback, target := ""),
        Off: (eventName, callback, target := "") => Events.Off(event, callback, target := ""),
        Trigger: (eventName, data) => Events.Trigger(event, data)
    }

    ; --- ContextService API ---
    Context := {
        Get: () => ContextService.GetContext(),
        Invalidate: (scope) => ContextService.InvalidateContext(scope),
        RegisterProvider: (processName, providerFunc) => ContextService.RegisterProvider(processName, providerFunc)
    }

    ; --- ConditionService API ---
    Condition := {
        Check: (conditionExpression, context) => ConditionService.Check(conditionExpression, context),
        Register: (name, func) => ConditionService.Register(name, func)
    }

    ; --- ConfigService API (只读) ---
    Config := {
        Get: (key) => ConfigService.Get(this.pluginName . ".settings." . key),
    }

    ; --- GuiService API ---
    Gui := {
        CreateThemedWindow: (options, title) => GuiService.CreateThemedWindow(options, title),
        ShowSingletonWindow: (name, creationFunc) => GuiService.ShowSingletonWindow(this.pluginName . "_" . name, creationFunc),
        ShowConfiguration: (this, ownerHwnd := 0) => PluginConfigGuiFactory.CreateAndShow(this.context.name, ownerHwnd),
    }

    ; --- MonitorManager API ---
    Monitors := {
        GetAll: () => MonitorManager.GetAll(),
        GetPrimary: () => MonitorManager.GetPrimary(),
        GetFromWindow: (hwnd) => MonitorManager.GetFromWindow(hwnd),
        SetBrightness: (index, value) => MonitorManager.SetBrightness(index, value)
    }
}

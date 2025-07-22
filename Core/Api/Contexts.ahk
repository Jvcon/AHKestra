#Include %A_ScriptDir%\..\Contexts\IContextProvider.ahk
#Include %A_ScriptDir%\..\Contexts\ContextService.ahk
#Include %A_ScriptDir%\..\Contexts\ContextRegistry.ahk
#Include %A_ScriptDir%\..\Contexts\ContextLoaderService.ahk


/**
 * 上下文系统的公共API (Facade)。
 * 为插件开发者提供一个简单、统一的接口来获取完整的当前上下文信息。
 */
class Contexts {
    /**
     * 获取当前完整的上下文视图。
     * @returns {Map} 一个包含了所有可用上下文信息的Map对象。
     */
    static GetCurrent() {
        return ContextService.GetContext()
    }
}

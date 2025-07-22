; Core/Events/EventLoaderService.ahk

/**
 * 负责自动发现和加载事件提供者。
 * 它扫描指定目录，并动态包含脚本文件来执行事件注册。
 * 这利用了AHK的文件和文件夹操作能力。
 */
class EventLoaderService {
    static _loadedProviders := Map() ; 用于防止重复加载同一个文件

    /**
     * 加载所有核心事件提供者。
     * 此方法应在框架启动时调用。
     */
    static LoadCoreProviders() {
        local providerPath := A_ScriptDir . "\Core\Events\Providers"
        Loop Files, providerPath . "\*.ahk" {
            this.LoadProviderFile(A_LoopFileFullPath)
        }
    }

    /**
     * 根据插件的manifest加载其声明的事件提供者。
     * @param pluginName {String} 插件的名称。
     * @param pluginPath {String} 插件的根目录路径。
     * @param manifestData {Map} 插件的manifest数据。
     */
    static RegisterProvider(pluginName, pluginPath, eventProvidersDef) {
        if (!IsObject(eventProvidersDef)) {
            return
        }
        for providerFile in eventProvidersDef {
            local fullPath := pluginPath . "\" . providerFile
            this.LoadProviderFile(fullPath, pluginName)
        }
    }
    
    /**
     * 加载单个事件提供者文件。
     * 核心逻辑是使用 #Include 来执行文件中的注册代码。
     * @param providerFullPath {String} 要加载的AHK文件的完整路径。
     * @param producerName {String} [可选] 事件生产者名称, 主要用于插件。
     * @see [[AHK]AutoHotKey 常用命令及示例_ahk msgbox-CSDN博客](https://blog.csdn.net/liuyukuan/article/details/54385259){target="_blank" class="gpt-web-url"}
     */
    static LoadProviderFile(providerFullPath, producerName := "default") {
        if (!FileExist(providerFullPath) || this._loadedProviders.Has(providerFullPath)) {
            return
        }
        
        try {
            ; 动态传入参数给被#Include的文件，这是一个高级技巧
            global _CURRENT_EVENT_PROVIDER_PATH := providerFullPath
            global _CURRENT_EVENT_PRODUCER_NAME := producerName
            
            #Include %providerFullPath%

            local className := StrReplace(A_LoopFileName, ".ahk")
            if (IsObject(className) && className.Prototype is IEventProvider) {
                local providerInstance := %className%()
                providerInstance.RegisterEvents(producerName)
                this._loadedProviders[providerFullPath] := providerInstance
            }
        } catch Error as e {
            ; 记录加载失败的日志
        } finally {
            _CURRENT_EVENT_PROVIDER_PATH := ""
            _CURRENT_EVENT_PRODUCER_NAME := ""
        }
    }
}

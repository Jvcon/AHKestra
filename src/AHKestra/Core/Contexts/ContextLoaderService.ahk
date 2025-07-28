#Include %A_ScriptDir%\..\Contexts\IContextProvider.ahk
#Include %A_ScriptDir%\..\Contexts\ContextRegistry.ahk

/**
 * 负责自动发现、验证和加载上下文提供者（Context Providers）。
 * 它扫描指定目录，并动态包含脚本文件来执行上下文的注册。
 */
class ContextLoaderService {
    static _loadedProviders := Map() ; 用于防止重复加载同一个文件

    static LoadCoreProviders() {
        local coreProviderPath := A_ScriptDir . "\Core\Contexts\Providers"
        this._LoadFromDirectory(coreProviderPath)
    }

    /**
     * 根据插件的manifest加载其声明的上下文提供者。
     * @param pluginName {String} 插件的名称。
     * @param pluginPath {String} 插件的根目录路径。
     * @param contextProvidersDef {Map} 插件的manifest.contextProviders数据。
     */
    static RegisterProvider(pluginName, pluginPath, contextProvidersDef) {
        if (!IsObject(contextProvidersDef)) {
            return
        }
        for providerFile in contextProvidersDef {
            local fullPath := pluginPath . "\" . providerFile
            this._LoadProviderFile(fullPath)
        }
    }

    /**
     * 遍历指定目录并加载所有 .ahk 文件作为提供者。
     * @param directoryPath {String} 要扫描的目录的完整路径。
     */
    static _LoadFromDirectory(directoryPath) {
        if !InStr(FileGetAttrib(directoryPath), "D") {
            return
        }
        Loop Files, directoryPath . "\*.ahk" {
            this._LoadProviderFile(A_LoopFileFullPath)
        }
    }

    /**
     * 加载并注册单个上下文提供者文件。
     * 这是服务发现机制的核心实现。
     * @param providerFullPath {String} 要加载的AHK文件的完整路径。
     */
    static _LoadProviderFile(providerFullPath) {
        if (!FileExist(providerFullPath) || this._loadedProviders.Has(providerFullPath)) {
            return
        }

        global _g_CurrentContextProviderClass := ""

        try {
            #Include %providerFullPath%

            if (IsObject(_g_CurrentContextProviderClass) && (_g_CurrentContextProviderClass.Prototype is IContextProvider)) {
                local providerInstance := _g_CurrentContextProviderClass()

                local definitions := providerInstance.GetContextDefinitions()

                ; 遍历定义并逐个注册
                for name, def in definitions {
                    def.name := name ; 将上下文名称注入定义中，便于注册表处理
                    ContextRegistry.Register(def, providerInstance)
                }

                ; 标记此文件已成功加载
                this._loadedProviders[providerFullPath] := true
            } else {
                ; 可选: 记录一个警告，指出该文件是一个无效的提供者文件
                OutputDebug("警告: 文件 " . providerFullPath . " 不是一个有效的上下文提供者。")
            }
        } catch Error as e {
            ; 记录加载过程中发生的任何错误
            OutputDebug("错误: 加载上下文提供者 " . providerFullPath . " 失败。`n" . e.Message)
        } finally {
            ; 无论成功与否，都必须清理全局“信使”变量，防止污染下一次加载
            _g_CurrentContextProviderClass := ""
        }
    }
}
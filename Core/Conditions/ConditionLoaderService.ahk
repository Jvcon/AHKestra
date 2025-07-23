class ConditionLoaderService {
    static _loadedProviders := Map()
    static LoadCoreProviders() {
        local providerPath := A_ScriptDir . "\Core\Conditions\Providers"
        Loop Files, providerPath . "\*.ahk" {
            this.LoadProviderFile(A_LoopFileFullPath)
        }
    }
    /**
     * 根据插件的manifest加载其声明的事件提供者。
     * @param pluginName {String} 插件的名称。
     * @param pluginPath {String} 插件的根目录路径。
     * @param conditionProvidersDef {Map} 插件的manifest.conditionProviders数据。
     */
    static RegisterProvider(pluginName, pluginPath, conditionProvidersDef) {
        if (!IsObject(conditionProvidersDef)) {
            return
        }
        for providerFile in conditionProvidersDef {
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
            global _g_CurrentConditionProviderClass := ""

            #Include %providerFullPath%

            if (IsObject(_g_CurrentConditionProviderClass) && (_g_CurrentConditionProviderClass.Prototype is IConditionProvider)) {
                local providerInstance := _g_CurrentProviderClass()
                ConditionRegistry.Register(providerInstance)
            }
        } catch Error as e {
            ; 记录加载失败的日志
            OutputDebug("错误: 加载条件判断提供者 " . providerFullPath . " 失败。`n" . e.Message)

        } finally {
            _g_CurrentProviderClass := ""
        }
    }
}
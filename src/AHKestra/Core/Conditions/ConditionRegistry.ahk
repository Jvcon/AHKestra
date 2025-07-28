class ConditionRegistry {
    static _registry := Map()

    static Register(ProviderClass) {
        local definitions := providerInstance.GetConditionDefinitions()
        
        for name, def in definitions {
            if (this._registry.Has(name)) {
                OutputDebug("警告: 条件 '" . name . "' 被重复注册。")
            }

            ; 每一个条件定义都存储其元数据和对其“父”提供者实例的引用。
            def.providerInstance := providerInstance
            this._registry[name] := def
        }
    }

    static GetDefinition(name) {
        return this._registry.Has(name) ? this._registry[name] : ""
    }
    
    static GetAllDefinitions() {
        return this._registry
    }
}

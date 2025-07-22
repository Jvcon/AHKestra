class ConditionRegistry {
    static _registry := Map()

    static Register(ProviderClass) {
        local providerInstance := new ProviderClass()
        local definitions := providerInstance.GetConditionDefinitions()
        
        for name, def in definitions {
            def.class := ProviderClass ; 将类本身注入到定义中，供引擎实例化
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

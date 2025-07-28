class ContextRegistry {
    static _providersByLayer := Map(
        "stable", [],
        "active", [],
        "volatile", []
    )
    static _definitions := Map() ; 用于文档生成

    static Register(definition, providerInstance) {
        local layer := definition.layer
        if (!this._providersByLayer.Has(layer)) {
            return
        }

        this._providersByLayer[layer].Push(providerInstance)

        ; 存储定义用于API生成
        local contextName := ""
        for k, v in definition {
            if (k != "layer") {
                contextName := k
            }
        }
        this._definitions[contextName] := definition
    }

    static GetProvidersByLayer(layer) {
        return this._providersByLayer.Has(layer) ? this._providersByLayer[layer] : []
    }

    static GetAllDefinitions() {
        return this._definitions
    }
}
class WindowConditionProvider extends IConditionProvider {
    _params := ""

    __New(params) {
        this._params := params
    }

    Evaluate(context) {

    }

    GetConditionDefinitions() {
        return Map()
    }
}
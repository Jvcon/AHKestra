class IConditionProvider {
    /**
     * 在给定的上下文中评估条件。
     * @param context {Map} 由 Contexts.GetCurrent() 提供的当前系统状态。
     * @returns {Boolean} 如果条件满足则返回 true，否则返回 false。
     */
    Evaluate(context) {
        throw NotImplementedError()
    }

    GetConditionDefinitions() {
        throw NotImplementedError()
    }
}
/**
 * 条件引擎，解释器模式的核心客户端。
 * 负责解析声明式的条件表达式，并构建一个由 ICondition 对象组成的语法树。
 */
class ConditionEngine {
    /**
     * 解析表达式并评估结果。
     * @param conditionExpression {Map} 用户定义的条件表达式。
     * @param context {Map} 当前的上下文。
     * @returns {Boolean}
     */
    static Evaluate(conditionExpression, context) {
        try {
            local conditionTree := this.BuildTree(conditionExpression)
            return conditionTree.Evaluate(context)
        } catch Error as e {
            OutputDebug("条件评估错误: " . e.Message)
            return false
        }
    }

    /**
     * 递归地构建条件对象树（语法树）。
     * @param expression {Map}
     * @returns {ICondition}
     */
    static BuildTree(expression) {
        local type := expression.Has("type") ? expression.type : ""

        ; 对于AND/OR/NOT，它的工作是：
        ; 1. 递归地为它的子节点构建对象树。
        ; 2. 从注册表获取相应的类（AndCondition, OrCondition等）。
        ; 3. 实例化这个类，并将子树作为参数传入。
        ; 这样，评估逻辑就被完美地封装在了各个条件类中。
        if (type = "AND" || type = "OR") {
            local ConditionClass := ConditionRegistry.Get(type)
            if (!IsObject(ConditionClass)) {
                throw ValueError("未注册的条件类型: " . type)
            }
            local subTrees := []
            for subExpr in expression.conditions {
                subTrees.Push(this.BuildTree(subExpr))
            }
            return ConditionClass(subTrees)
        }
        if (type = "NOT") {
            local ConditionClass := ConditionRegistry.Get(type)
            if (!IsObject(ConditionClass)) {
                throw ValueError("未注册的条件类型: " . type)
            }
            local subTree := this.BuildTree(expression.condition)
            return ConditionClass(subTree)
        }

        ; 对于终结符，它的工作是获取相应的类并实例化。
        local ConditionDef := ConditionRegistry.GetDefinition(type)
        if (!IsObject(ConditionDef)) {
            throw ValueError("未注册的条件类型: " . type)
        }
        local params := expression.Clone()
        params.Delete("type")
        ; 终结符的评估逻辑被封装在其 providerInstance 中。
        return TerminalCondition(type, params, ConditionDef.providerInstance)
    }
}

/**
 * 一个轻量级的终结符表达式包装器
 * 它的Evaluate方法会调用真正的Provider的Evaluate方法
 */
class TerminalCondition extends ICondition {
    __New(type, params, provider) {
        this.type := type
        this.params := params
        this.provider := provider
    }
    Evaluate(context) {
        return this.provider.Evaluate(context, this.type, this.params)
    }
}
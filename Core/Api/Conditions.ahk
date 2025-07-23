#Include %A_ScriptDir%\..\Services\ConditionEngine.ahk
#Include %A_ScriptDir%\..\API\Contexts.ahk

class Conditions {
    /**
     * 检查给定的条件表达式是否满足。
     * 这是暴露给框架其他部分的唯一接口。
     * @param conditionExpression {Map} 用户定义的条件表达式。
     * @returns {Boolean}
     */
    static Check(conditionExpression,context) {
        if (!IsObject(conditionExpression) || !conditionExpression.Has("type")) {
            return true ; 如果表达式无效或为空，默认为真
        }
        return ConditionEngine.Evaluate(conditionExpression, context)
    }
}

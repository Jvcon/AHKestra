#Include %A_ScriptDir%\..\ICondition.ahk

/**
 * 非终结符表达式：实现逻辑“与”操作。
 * 它包含一个子表达式列表，只有当所有子表达式都为真时，它才返回真。
 */
class AndCondition extends ICondition {
    _conditions := [] ; 存储 ICondition 对象的数组

    __New(conditionObjects) {
        this._conditions := conditionObjects
    }

    Evaluate(context) {
        for condition in this._conditions {
            if (!condition.Evaluate(context)) {
                return false ; 一假即假
            }
        }
        return true ; 全真才真
    }
}

global _g_CurrentConditionProviderClass := AndCondition
; Core/Services/ConditionService.ahk - 条件检查辅助服务
#Requires AutoHotkey v2.0

class ConditionService {
    static _conditionRegistry := Map() ; 内部注册表，存储所有条件函数

    /**
     * 初始化：可以预注册一些基础的逻辑操作符
     */
    static Init() {
        ; 未来可以扩展，用于初始化
    }
    
    /**
     * 注册一个条件函数。
     * 这是插件和核心模块向系统贡献条件的【唯一】入口。
     * @param name {String} 条件的名称，如 "isExplorer"。
     * @param func {Func} 接收一个 context 对象并返回布尔值的函数。
     */
    static Register(name, func) {
        if (!IsObject(func) || func.MinParams < 1) {
            throw ValueError("Condition function must be an object and accept at least one parameter (context).")
        }
        this._conditionRegistry[name] := func
    }

    /**
     * 【核心方法】检查一个条件表达式是否为真。
     * @param conditionExpression {String} 条件表达式，如 "isExplorer", "isMaximized"。
     * @param context {Map} 由 ContextInfo 提供的当前上下文对象。
     * @returns {Boolean} 表达式的评估结果。
     */
    static Check(conditionExpression, context) {
        if (conditionExpression == "") {
            return true ; 空条件始终为真
        }

        local isNegated := false
        local key := Trim(conditionExpression)

        ; 处理否定逻辑 "!"
        if (SubStr(key, 1, 1) == "!") {
            isNegated := true
            key := Trim(SubStr(key, 2))
        }
        
        if (!this._conditionRegistry.Has(key)) {
            Tooltip "Unknown condition '" . key . "'. Evaluation defaulted to false."
            return false
        }

        try {
            local result := this._conditionRegistry[key](context)
            return isNegated ? !result : !!result ; 确保返回的是纯布尔值
        } catch Error as e {
            Error "Condition '" . key . "' failed with an error: " . e.Message
            return false ; 任何条件函数执行出错，都安全地返回 false
        }
    }
}

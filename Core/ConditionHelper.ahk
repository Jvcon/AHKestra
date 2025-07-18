; Core/ConditionHelper.ahk - 通用条件检查辅助工具
#Requires AutoHotkey v2.0

class ConditionHelper {
    /**
     * 评估一个定义对象（如热键或菜单项）的条件是否在当前上下文中满足。
     * @param def {Object} 定义对象，必须包含 'plugin' 属性，并可能包含 'condition' 属性。
     * @param context {Object} 当前的上下文信息。
     * @returns {Boolean} 如果条件满足或没有条件，则返回 true。
     */
    static Evaluate(def, context) {
        if !def.HasProp("condition") || def.condition == "" {
            return true 
        }

        local condFuncName := def.condition
         if (Conditions.HasMethod(condName)) {
            try {
                return Conditions[condName](context)
            } catch Error as e {
                ToolTip("通用条件函数执行错误: " . e.Message,,"Error")
                SetTimer () => ToolTip(), -3000
                return false
            }
        }

        local pluginInstance := LoadedPlugins[def.plugin]

        if !IsObject(pluginInstance) || !pluginInstance.HasMethod(condFuncName) {
            return false
        }
        
        try {
            return pluginInstance[condFuncName](context)
        } catch Error as e {
            ToolTip("条件函数执行错误: " e.Message "`n插件: " def.plugin,,"Error")
            SetTimer () => ToolTip(), -3000
            return false
        }
    }
}

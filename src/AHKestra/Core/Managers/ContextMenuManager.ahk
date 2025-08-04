; ContextMenuManager.ahk - 增强的上下文菜单管理器
#Requires AutoHotkey v2.0

class ContextMenuManager {
    static AllMenuItems := [] ; 存储所有已注册的菜单项定义

    static Init(){
        local menuKey := ConfigService.Get("ContextMenuManager.settings.menuKey")
        Hotkey(menuKey, (*) => this.BuildAndShowMenu())
    }

    /**
     * 由 PluginService 调用，注册一个菜单项定义。
     * @param pluginName {String} 插件名称。
     * @param path {String} 菜单路径，用 "/" 分隔，如 "文件/操作/复制"。
     * @param condition {Func} 条件函数，接收上下文并返回布尔值。
     * @param callback {Func} 回调函数，接收上下文。
     */
    static Register(pluginName, path, condition, callback) {
        this.AllMenuItems.Push({
            plugin: pluginName,
            path: path,
            condition: condition,
            callback: callback
        })
    }

    /**
     * [核心] 注销一个插件贡献的所有菜单项。
     * @param pluginName {String} 要注销其菜单项的插件名称。
     */
    static Unregister(pluginName) {
        ; 我们从后向前遍历数组，这样在删除元素时不会影响后续元素的索引。
        ; 这是在迭代中修改数组的安全做法。
        loop this.AllMenuItems.Length {
            local index := this.AllMenuItems.Length - A_Index + 1
            local itemDef := this.AllMenuItems[index]

            if (itemDef.plugin == pluginName) {
                this.AllMenuItems.RemoveAt(index)
            }
        }
    }

    /**
     * 构建并显示上下文菜单。
     */
    static BuildAndShowMenu() {
        local context := ContextService.GetContext()
        local dynamicMenu := Menu()
        local hasVisibleItems := false

        for itemDef in this.AllMenuItems {
            ; 检查条件是否满足
            local showItem := true
            if Conditions.Check(itemDef.condition,context) {
                try {
                    showItem := itemDef.condition(context)
                } catch {
                    showItem := false ; 条件出错时，为安全起见不显示
                }
            }
            
            if (showItem) {
                ; 解析路径并创建子菜单
                local parts := StrSplit(itemDef.path, "/")
                local itemName := parts.Pop()
                local parentMenu := this._getOrCreateSubMenu(dynamicMenu, parts)

                ; 添加菜单项，并绑定回调
                parentMenu.Add(itemName, (item, *) => itemDef.callback(context))
                hasVisibleItems := true
            }
        }

        if (hasVisibleItems) {
            MouseGetPos(&mouseX, &mouseY)
            dynamicMenu.Show(mouseX, mouseY)
        }
    }

    /**
     * 内部辅助函数：根据路径数组，获取或创建层级子菜单。
     * @param rootMenu {Menu} 根菜单对象。
     * @param pathParts {Array} 路径部分组成的数组。
     * @returns {Menu} 最终的父菜单对象。
     */
    static _getOrCreateSubMenu(rootMenu, pathParts) {
        local currentMenu := rootMenu
        for part in pathParts {
            ; 检查子菜单是否已存在
            try {
                local subMenu := Menu()
                currentMenu.Add(part, subMenu)
                currentMenu := subMenu
            } catch {
                ; 理论上 Add 不会失败，但这是防御性编程
            }
        }
        return currentMenu
    }
}

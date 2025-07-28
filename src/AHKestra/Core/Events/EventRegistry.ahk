; Core/Events/EventRegistry.ahk

class EventRegistry {
    static _events := Map()

    /**
     * 注册一个新的事件类型。
     * @param eventName {String} 事件的唯一名称。
     * @param type {String} 事件类型, 'global' 或 'dynamic'。
     * @param desc {String} 事件的描述。
     * @param provider {String} 定义该事件的AHK文件的完整路径。
     * @param producer {String} [可选] 事件生产者的名称, 默认为 'default'。
     *                         如果是插件注册，则应传入插件名称。
     */
    static Register(eventName, type, desc, provider, producer := "default") {
        if this._events.Has(eventName) {
            return
        }
        this._events[eventName] := {
            name: eventName,
            type: type,
            desc: desc,
            producer: producer,
            handler: provider ; 新增字段，记录事件定义文件的来源
        }
    }

    static Get(eventName) {
        return this._events.Has(eventName) ? this._events[eventName] : ""
    }

    static GetAll() {
        return this._events
    }
}

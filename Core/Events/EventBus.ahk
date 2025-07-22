; Core/Events/EventBus.ahk

/**
 * 核心事件总线，负责管理订阅和事件分发。
 * 它封装了全局和动态事件的处理逻辑，是EDA模式的核心实现。
 * @see [Event-Driven Architecture (EDA): A Complete Introduction](https://www.confluent.io/learn/event-driven-architecture/){target="_blank" class="gpt-web-url"}
 */
class EventBus {

    ; 全局事件监听器: Map { "eventName": [callback1, callback2] }
    static _globalListeners := Map()

    ; 动态事件监听器: Map { "eventName|target": {hook: WinEventObject, callbacks: [cb1, cb2]} }
    static _dynamicListeners := Map()

    /**
     * 订阅一个事件。
     * @param eventName {String} 要订阅的事件名称。
     * @param callback {Func} 回调函数。
     * @param target {String} [可选] 对于动态事件，指定目标。
     */
    static On(eventName, callback, target := "") {
        local eventDef := EventRegistry.Get(eventName)
        if !IsObject(eventDef) {
            throw ValueError("Event '" . eventName . "' is not registered.")
        }

        if (eventDef.type == "global") {
            if !this._globalListeners.Has(eventName) {
                this._globalListeners[eventName] := []
            }
            this._globalListeners[eventName].Push(callback)
        } else if (eventDef.type == "dynamic") {
            if (target == "") {
                throw ValueError("Dynamic event '" . eventName . "' requires a 'target' parameter.")
            }
            local hookKey := eventName . "|" . target
            if (this._dynamicListeners.Has(hookKey)) {
                this._dynamicListeners[hookKey].callbacks.Push(callback)
                return
            }
            local providerInstance := eventDef.handler
            if (!IsObject(providerInstance) || !(providerInstance is IEventProvider)) {
                throw Error("No valid dynamic event provider found for '" . eventName . "'")
            }
            try {
                local hookObj := providerInstance.CreateHook(eventName, target, this._GenericEventHandler.Bind(this))
                hookObj.CustomHookKey := hookKey
                this._dynamicListeners[hookKey] := { hookObj: hookObj, callbacks: [callback] }
            } catch Error as e {
                throw Error("EventBus failed to create dynamic hook for '" . eventName . "'.", -1, e)
            }
        }
    }

    /**
     * 取消订阅一个事件。
     * 这是任何事件总线实现的关键部分，用于管理订阅者的生命周期。
     * @see [Implementing event-based communication between microservices ...](https://dzfweb.gitbooks.io/microsoft-microservices-book/content/multi-container-microservice-net-applications/integration-event-based-microservice-communications.html){target="_blank" class="gpt-web-url"}
     * @param eventName {String} 要取消订阅的事件名称。
     * @param callback {Func} 用于订阅的回调函数。
     * @param target {String} [可选] 对于动态事件，必须提供与订阅时相同的目标。
     */
    static Off(eventName, callback, target := "") {
        local eventDef := EventRegistry.Get(eventName)
        if !IsObject(eventDef) {
            return
        }

        if (eventDef.type == "global") {
            if (this._globalListeners.Has(eventName)) {
                local listeners := this._globalListeners[eventName]
                loop listeners.Length {
                    local index := listeners.Length - A_Index + 1
                    if (listeners[index] == callback) {
                        listeners.RemoveAt(index)
                        break
                    }
                }
                if (listeners.Length == 0) {
                    this._globalListeners.Delete(eventName)
                }
            }
        } else if (eventDef.type == "dynamic") {
            if (target == "") {
                throw ValueError("To unsubscribe from a dynamic event, a 'target' parameter is required.")
            }
            local hookKey := eventName . "|" . target
            if (this._dynamicListeners.Has(hookKey)) {
                local hookInfo := this._dynamicListeners[hookKey]
                local callbacks := hookInfo.callbacks

                loop callbacks.Length {
                    local index := callbacks.Length - A_Index + 1
                    if (callbacks[index] == callback) {
                        callbacks.RemoveAt(index)
                        break
                    }
                }

                if (callbacks.Length == 0) {
                    try hookInfo.hookObj.Delete()
                    this._dynamicListeners.Delete(hookKey)
                }
            }
        }
    }

    /**
     * 触发一个全局事件。
     */
    static Trigger(eventName, data := "") {
        if this._globalListeners.Has(eventName) {
            for cb in this._globalListeners[eventName] {
                try cb(data)
            }
        }
    }

    /**
     * 动态事件的通用处理器。
     */
    static _GenericEventHandler(hWnd, eventObj, dwmsEventTime) {
        local hookKey := eventObj.CustomHookKey
        if (this._dynamicListeners.Has(hookKey)) {
            local data := { hWnd: hWnd, time: dwmsEventTime }
            for cb in this._dynamicListeners[hookKey].callbacks {
                try cb(data)
            }
        }
    }
}
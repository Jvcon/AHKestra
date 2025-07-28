; Core/Events/IEventProvider.ahk

/**
 * 动态事件提供者的接口。
 * 定义了所有动态事件提供者必须实现的方法，
 * 以便EventBus能够以一种统一的方式与它们交互。
 */
class IEventProvider {
    /**
     * 注册此提供者能够产生的所有事件。
     * @param producerName {String} 事件生产者名称。
     */
    RegisterEvents(producerName) {
        throw NotImplementedError()
    }

    /**
     * 【核心】为特定的动态事件创建钩子。
     * 这是将创建逻辑从EventBus解耦的关键。
     * @param eventName {String} 具体的事件名称。
     * @param target {String} 订阅的目标。
     * @param handler {Func} EventBus提供的通用事件处理器。
     * @returns {Object} 返回一个钩子对象，该对象必须有一个 .Delete() 方法。
     */
    CreateHook(eventName, target, handler) {
        throw NotImplementedError()
    }

    /**
     * 【用于文档生成】获取此提供者所有事件的结构化定义。
     * 这个方法是实现自动文档生成的关键，它返回一个机器可读的格式。
     * @returns {Map} 一个Map对象，键是事件名称，值是包含事件元数据的对象。
     *         元数据对象应包含: {type, desc, data_schema, example}
     */
    GetEventDefinitions() {
        throw NotImplementedError()
    }
}
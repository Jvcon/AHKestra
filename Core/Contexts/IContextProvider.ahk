/**
 * 上下文提供者的接口。
 * 定义了所有上下文提供者必须实现的方法，以便框架能以统一方式获取上下文信息，
 * 并为文档生成工具提供结构化的元数据。
 */
class IContextProvider {
    /**
     * 【用于运行时】获取当前的上下文值。
     * 此方法应高效，因其可能被频繁调用。建议内部实现缓存机制。
     * @returns {*} 返回上下文的值，可以是字符串、数字或Map对象。
     */
    GetValue(currentContext := "") {
        throw NotImplementedError()
    }

    /**
     * 【用于文档生成】获取此上下文的结构化定义。
     * 这是实现自动文档生成的关键，返回机器可读的格式。
     * @returns {Map} 一个Map对象，包含上下文的元数据。
     *         元数据应包含: {name, desc, return_type, return_schema, example}
     */
    GetContextDefinitions() {
        throw NotImplementedError()
    }
}

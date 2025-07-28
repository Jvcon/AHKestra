
class PersistenceHelper {
    /**
     * 从指定路径读取并解析JSON文件。
     * @param filePath {String} 文件的绝对路径。
     * @returns {Map | Array} 解析后的AHK对象，如果文件不存在或为空则返回空Map。
     */
    static ReadJson(filePath) {
        if (!FileExist(filePath)) {
            return Map()
        }
        try {
            local content := FileRead(filePath, "UTF-8")
            if (Trim(content) == "") {
                return Map()
            }
            return jsongo.Parse(content)
        } catch e {
            Error("读取或解析JSON文件失败: " . filePath . "`n" . e.Message)
            return Map() ; 出错时返回空Map，保证健壮性
        }
    }
    /**
     * 将AHK对象序列化为JSON并写入指定文件。
     * @param filePath {String} 文件的绝对路径。
     * @param data {Map | Array} 要写入的AHK对象。
     * @param pretty {Boolean} 是否格式化输出 (pretty print)。
     */
    static WriteJson(filePath, data, pretty := true) {
        try {
            local jsonString := jsongo.Stringify(data, , pretty ? 4 : "")
            ; 确保目录存在
            FileExist(filePath) ? "" : DirCreate(RegExReplace(filePath, "[^\\]+$"))
            FileOpen(filePath, "w", "UTF-8").Write(jsonString)
        } catch e {
            Error("写入JSON文件失败: " . filePath . "`n" . e.Message)
        }
    }
}
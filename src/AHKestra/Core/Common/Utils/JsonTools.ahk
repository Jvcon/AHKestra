/**
 * JsonTools - 一个AutoHotkey的JSON外部工具链的集成库。
 * 通过一个外部的、高性能的、支持批量验证的.NET库（NJsonSchema）构建DLL(src/AHKestra.Tools.Json)实现。
 */
#Include %A_ScriptDir%\..\..\Lib\JSON.ahk

class JsonTools {
    /**
     * 验证给定的JSON manifest文件是否符合指定的JSON schema。
     * @param schemaPath - JSON schema文件的路径。
     * @param manifestPath - JSON manifest文件的路径。
     * @return 返回一个Map对象，包含验证结果。
     *         如果验证通过，Map中包含 "ok": true。
     *         如果验证失败，Map中包含 "ok": false 和 "errors": 错误信息列表。
     * @throws Error - 如果验证过程中发生错误或验证结果为空。
     */
    static Validate(schemaPath, manifestPath) {
        static dllPath := A_ScriptDir . "\AHKestra.Tools.Json.dll"
        static isDllChecked := false
        if !isDllChecked {
            if !FileExist(dllPath) {
                throw Error("Validation DLL not found at: " . dllPath)
            }
            isDllChecked := true
        }

        try {
            resultJson := DllCall(
                dllPath . "\ValidateManifestFromFile", ; DLL Path and Function Name
                "WStr", manifestPath,          ; Parameter 1: Manifest JSON (Unicode String)
                "WStr", schemaPath,            ; Parameter 2: Schema JSON (Unicode String)
                "AStr"                         ; Return Type: AHK String (automatically handles memory)
            )
        } catch Error as e {
        throw Error("Failed to call ValidateManifestFromFile function in DLL.", -1, e)
        }

        if (resultJson = "") {
            throw Error("Validation returned empty result. Please check the schema and manifest files.")
        }

        validationResult := jsongo.Parse(resultJson)
        return validationResult
    }
}
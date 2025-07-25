/**
 * JsonValidator - 一个AutoHotkey的JSON Schema验证库。
 * 通过封装一个外部的、高性能的、支持批量验证的.NET命令行工具 `validator.exe` (https://github.com/Jvcon/Validator) 来实现。
 */
#Include %A_ScriptDir%\..\..\Lib\JSON.ahk

class JsonValidator {
    /**
     * [批量验证] 验证一个或多个manifest文件是否符合指定的Schema。
     * @param schema {Map} 用于验证的JSON Schema对象。
     * @param manifestFilePaths {Array} 一个包含一个或多个manifest文件绝对路径的数组。
     * @returns {Map} 一个以文件路径为键的报告。
     *                每个值是一个对象 {ok: Boolean, errors: Array},
     *                其中errors是格式化后的错误信息字符串数组。
     *                例如: 
     *                {
     *                  "C:\path\to\plugin1\manifest.json": {ok: true, errors: []},
     *                  "C:\path\to\plugin2\manifest.json": {ok: false, errors: ["L25 at '#/contributes': ..."]}
     *                }
     */
    static Validate(schema, manifestFilePaths) {
        if (!IsObject(manifestFilePaths) || manifestFilePaths.Length == 0) {
            return Map() ; 没有文件需要验证，返回空报告
        }

        ; 准备schema的临时文件
        local schemaFilePath := this._WriteTempFile(jsongo.Stringify(schema))
        
        local report := Map()
        ; 假设 validator.exe 放在与本文件相同的目录下
        local validatorExePath := A_ScriptDir . "\validator.exe"

        try {
            ; 1. 构建批量验证的命令行
            local command := '"' . validatorExePath . '"'
            command .= ' "' . schemaFilePath . '"' ; 第一个参数是schema

            for _, filePath in manifestFilePaths {
                command .= ' "' . filePath . '"' ; 追加所有manifest文件路径
            }

            command .= " -f json" ; 【关键】要求返回JSON格式的报告

            ; 2. 执行命令并捕获输出
            local shell := ComObject("WScript.Shell")
            local exec := shell.Exec(A_ComSpec " /c " . command)

            local stdout := exec.StdOut.ReadAll()
            local stderr := exec.StdErr.ReadAll()
            
            ; 3. 解析结构化的JSON报告
            if (Trim(stdout) != "") {
                try {
                    local validationReport := jsongo.Parse(stdout)
                    
                    ; 4. 将JSON报告转换为我们内部使用的标准Map格式
                    for fileResult in validationReport.results {
                        local formattedErrors := []
                        if (!fileResult.isValid) {
                            for err in fileResult.errors {
                                ; 从详细的错误对象中构建易于阅读的错误信息
                                local errorMsg := "L" . err.lineNumber . " at '" . err.path . "': " . err.errorType
                                if (err.property) {
                                    errorMsg .= " (Property: " . err.property . ")"
                                }
                                formattedErrors.Push(errorMsg)
                            }
                        }
                        
                        report[fileResult.filePath] := Map(
                            "ok", fileResult.isValid,
                            "errors", formattedErrors
                        )
                    }
                } catch e {
                    ; 如果JSON解析失败，说明验证工具可能输出了非JSON的错误
                    report["_error"] := Map("ok", false, "errors", ["无法解析验证器的输出: " . stdout, "Stderr: " . stderr])
                }
            } else if (Trim(stderr) != "") {
                report["_error"] := Map("ok", false, "errors", ["验证工具执行错误: " . stderr])
            }

        } catch e {
             report["_error"] := Map("ok", false, "errors", ["执行验证时发生异常: " . e.Message])
        } finally {
            ; 5. 清理临时文件
            FileDelete(schemaFilePath)
        }
        
        return report
    }

    /**
     * [私有辅助函数] 将内容写入一个临时文件并返回其路径。
     */
    static _WriteTempFile(content) {
        local tempPath := APP_TEMP_DIR . "\" . Random() . ".json"
        try {
            FileOpen(tempPath, "w", "UTF-8").Write(content)
        } catch Error as e {
            throw Error("无法创建临时文件: " . tempPath . ". " . e.Message)
        }
        return tempPath
    }
}

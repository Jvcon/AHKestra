class ApiGenerator {
    static GenerateEventDocs(outputFile) {
        local providersPath := A_ScriptDir . "\Core\Events\Providers"
        local markdown := "# 事件 API 文档" . "`n`n"

        Loop Files, providersPath . "\*.ahk" {
            try {
                local providerFileContent := FileRead(A_LoopFileFullPath)
                
                ; 1. 解析文件头注释
                local providerName := RegExMatch(providerFileContent, "m`a)^\s*\*\s*@ProviderName\s+(.*)", &m) ? m[1] : A_LoopFileName
                local providerDesc := RegExMatch(providerFileContent, "m`a)^\s*\*\s*@ProviderDescription\s+(.*)", &m) ? m[1] : ""
                markdown .= "## " . providerName . "`n`n"
                markdown .= providerDesc . "`n`n"

                ; 2. 动态加载并调用GetEventDefinitions
                #Include %A_LoopFileFullPath%
                local className := StrReplace(A_LoopFileName, ".ahk")
                local providerInstance := new %className%()
                local definitions := providerInstance.GetEventDefinitions()
                
                ; 3. 格式化输出
                for name, def in definitions {
                    markdown .= "### `" . name . "` `[" . def.type . "]`" . "`n`n"
                    markdown .= def.desc . "`n`n"
                    markdown .= "**数据结构:**`n`"
                    markdown .= "| 键名 | 描述 |`n`|---|---|`n`"
                    for key, desc in def.data_schema {
                        markdown .= "| `" . key . "` | " . desc . " |`n`"
                    }
                    markdown .= "`n`**示例:**`n```ahk`n" . def.example . "`n````n`n"
                }
            } catch {
                ; 记录错误
            }
        }
        
        FileOpen(outputFile, "w", "UTF-8").Write(markdown)
    }
}

; 使用方法:
ApiGenerator.GenerateEventDocs("API_Docs_Events.md")

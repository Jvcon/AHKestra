class ApiGenerator {
    static GenerateEventDocs(outputFile) {
        local providersPath := A_ScriptDir . "\Core\Events\Providers"
        local markdown := "# 事件 API 文档" . "`n`n"

        Loop Files, providersPath . "\*.ahk" {
            try {
                local providerFileContent := FileRead(A_LoopFileFullPath)

                local providerName := RegExMatch(providerFileContent, "m`a)^\s*\*\s*@ProviderName\s+(.*)", &m) ? m[1] : A_LoopFileName
                local providerDesc := RegExMatch(providerFileContent, "m`a)^\s*\*\s*@ProviderDescription\s+(.*)", &m) ? m[1] : ""
                markdown .= "## " . providerName . "`n`n"
                markdown .= providerDesc . "`n`n"

                global _g_CurrentProviderClass := ""

                #Include %providerFullPath%

                if (IsObject(_g_CurrentProviderClass) && (_g_CurrentProviderClass.Prototype is IEventProvider)) {
                    local providerInstance := _g_CurrentProviderClass()
                    definitions := providerInstance.GetEventDefinitions()
                }

                for name, def in definitions {
                    markdown .= "### `" . name . "``[" . def.type . "]` " . "`n`n "
                    markdown .= def.desc . "`n`n"
                    markdown .= "**数据结构:**`n`"
                    markdown .= "| 键名 | 描述 |`n`|---|---|`n`"
                    for key, desc in def.data_schema {
                        markdown .= "| `" . key . "` | " . desc . " | `n` "
                    }
                    markdown .= "`n`**示例:**`n```ahk`n" . def.example . "`n````n`n"
                }
            } catch {
                ; 记录错误
            }
        }
        _g_CurrentProviderClass := ""
        FileOpen(outputFile, "w", "UTF-8").Write(markdown)
    }
    static GenerateContextDocs(outputFile) {
        local providersPath := A_ScriptDir . "\Core\Contexts\Providers"
        local markdown := "# 上下文 API 文档" . "`n`n"

        Loop Files, providersPath . "\*.ahk" {
            try {
                local providerFileContent := FileRead(A_LoopFileFullPath)

                local providerName := RegExMatch(providerFileContent, "m`a)^\s*\*\s*@ProviderName\s+(.*)", &m) ? m[1] : A_LoopFileName
                local providerDesc := RegExMatch(providerFileContent, "m`a)^\s*\*\s*@ProviderDescription\s+(.*)", &m) ? m[1] : ""
                markdown .= "## " . providerName . "`n`n"
                markdown .= providerDesc . "`n`n"
                global _g_CurrentProviderClass := ""

                #Include %providerFullPath%
                if (IsObject(_g_CurrentProviderClass) && (_g_CurrentProviderClass.Prototype is IContextProvider)) {
                    local providerInstance := _g_CurrentProviderClass()
                    definitions := providerInstance.GetEventDefinitions()
                }

                for name, def in definitions {
                    markdown .= "### `" . name . "``[" . def.type . "]` " . "`n`n "
                    markdown .= def.desc . "`n`n"
                    markdown .= "**数据结构:**`n`"
                    markdown .= "| 键名 | 描述 |`n`|---|---|`n`"
                    for key, desc in def.data_schema {
                        markdown .= "| `" . key . "` | " . desc . " | `n` "
                    }
                    markdown .= "`n`**示例:**`n```ahk`n" . def.example . "`n````n`n"
                }
            } catch {
                ; 记录错误
            }
        }
        _g_CurrentProviderClass := ""
        FileOpen(outputFile, "w", "UTF-8").Write(markdown)
    }
}

; 使用方法:
ApiGenerator.GenerateEventDocs("API_Docs_Events.md")
ApiGenerator.GenerateContextDocs("API_Docs_Contexts.md")
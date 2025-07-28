/**
 * @ProviderName Text Context Provider
 * @ProviderDescription 提供了与操作系统窗口相关的核心事件，如窗口的激活、移动和大小调整。
 * @Version 1.1.0
 */

class TextContextProvider extends IContextProvider {

    /**
     * 获取所有可能的文本源
     * @returns {Map} 一个包含所有文本源的 Map 对象。
     */
    static GetTextSources() {
        local sources := Map()
        local oldClipboard := ClipboardAll(), selectedText := ""
        A_Clipboard := ""
        SendInput "^c"
        if ClipWait(0.2, true) {
            selectedText := A_Clipboard
        }
        A_Clipboard := oldClipboard

        if (selectedText != "") {
            sources["selection"] := selectedText
        }

        if (A_Clipboard != "") {
            sources["clipboard"] := A_Clipboard
        }

        return sources
    }
}

global _g_CurrentContextProviderClass := TextContextProvider

; Core/Services/CommonConditions.ahk - 常用条件

#Requires AutoHotkey v2.0

; 一个包含常用、通用条件判断方法的静态类。
; 它的目标是让插件开发者可以像使用库一样，直接在 manifest.json 中引用这些方法。
class Conditions {
    ; --- 文本相关条件 ---
    static hasSelection(ctx) {
        return IsSet(ctx.TextSources.selection) && ctx.TextSources.selection != ""
    }
    static hasText(ctx) {
        return (IsSet(ctx.TextSources.selection) && ctx.TextSources.selection != "") || 
               (IsSet(ctx.TextSources.clipboard) && ctx.TextSources.clipboard != "")
    }
    static selectionIsUrl(ctx) {
        return this.hasSelection(ctx) && RegExMatch(ctx.TextSources.selection, "i)https?://")
    }
    static clipboardIsUrl(ctx) {
        return IsSet(ctx.TextSources.clipboard) && RegExMatch(ctx.TextSources.clipboard, "i)https?://")
    }

    ; --- 窗口与应用相关条件 ---
    static isExplorer(ctx) {
        return ctx.ActiveWindow.processName == "explorer.exe"
    }
    static isBrowser(ctx) {
        return ctx.ActiveWindow.processName ~= "i)chrome\.exe|firefox\.exe|msedge\.exe"
    }
    static isMaximized(ctx) {
        return WinGetMinMax("ahk_id " . ctx.ActiveWindow.hwnd) == 1
    }
}

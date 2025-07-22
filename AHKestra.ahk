; Main.ahk - 主程序入口
#Requires AutoHotkey v2.0
#SingleInstance Force

; 全局设置
global APP_NAME := "AHKestra"
global APP_VERSION := "1.0.0"
global APP_CONFIG_DIR := A_AppData . "\" . APP_NAME
global APP_PLUGINS_DIR := A_ScriptDir . "\Plugins"
global APP_THEMES_DIR := A_ScriptDir . "\Themes"
global APP_LIB_DIR := A_ScriptDir . "\Lib"

defaultThemeName := "NordDark"
defaultMenuKey := "#RButton"
defaultLeaderKey := "Space"
if (!DirExist(APP_THEMES_DIR))
    DirCreate(APP_THEMES_DIR)

defaultThemePath := APP_THEMES_DIR . "\" . defaultThemeName . ".json"
if (!FileExist(defaultThemePath)) {
    ; 1. 将默认主题定义为原生的 AHK Map 对象，更易于维护
    defaultThemeMap := Map(
        "name", "Nord Dark",
        "author", "Arctic Ice Studio",
        "colors", Map(
            "bg", "2E3440",
            "text", "E5E9F0",
            "accent", "88C0D0",
            "border", "4C566A",
            "success", "A3BE8C",
            "warning", "EBCB8B",
            "error", "BF616A"
        ),
        "fonts", Map(
            "family", "Segoe UI",
            "size", 10,
            "titleSize", 14
        )
    )

    try {
        ; 2. 使用 jsongo.Stringify 并传入 spacer 参数 (这里用 4 个空格) 来生成格式化的JSON字符串
        formattedJson := jsongo.Stringify(defaultThemeMap, , 4)

        ; 3. 将格式化后的字符串写入文件
        FileOpen(defaultThemePath, "w", "UTF-8").Write(formattedJson)
    } catch {
        MsgBox "无法创建默认主题文件，程序可能无法正常显示UI。", , "16"
    }
}


; 引入核心库
#Include <JSON>
#Include <YAML>

#Include %A_ScriptDir%\Core\Events\Events.ahk
#Include %A_ScriptDir%\Core\Services\ContextService.ahk
#Include %A_ScriptDir%\Core\Services\ConditionService.ahk
#Include %A_ScriptDir%\Core\Services\ConfigService.ahk
#Include %A_ScriptDir%\Core\Services\GuiService.ahk
#Include %A_ScriptDir%\Core\Conditions.ahk
#Include %A_ScriptDir%\Core\Errors.ahk


#Include %A_ScriptDir%\Core\Managers\PluginService.ahk
#Include %A_ScriptDir%\Core\Managers\HotkeyManager.ahk
#Include %A_ScriptDir%\Core\Managers\ContextMenuManager.ahk
#Include %A_ScriptDir%\Core\Managers\TextEngineManager.ahk

#Include %A_ScriptDir%\Core\TrayMenu.ahk
#Include %A_ScriptDir%\Core\Views\SettingsGui.ahk
#Include %A_ScriptDir%\Core\Views\PluginConfigGuiFactory.ahk

; 初始化应用
InitApp()

InitApp() {
    ; 创建必要的目录
    if (!DirExist(APP_CONFIG_DIR))
        DirCreate(APP_CONFIG_DIR)
    if (!DirExist(APP_PLUGINS_DIR))
        DirCreate(APP_PLUGINS_DIR)

    guiDefaults := Map("activeTheme", defaultThemeName)
    menuDefaults := Map("menuKey", defaultMenuKey)
    hotkeyDefaults := Map("leaderKey",defaultLeaderKey , "timeout", 1000)
    ConfigService.RegisterDefaults("ContextMenuManager", "settings", menuDefaults)
    ConfigService.RegisterDefaults("HotkeyManager", "settings", hotkeyDefaults)
    ConfigService.RegisterDefaults("GuiService", "settings", guiDefaults)
   
    ; 加载配置
    ConfigService.Load()
    EventLoaderService.LoadCoreProviders()


    EventService.Init()
    ConditionService.Init()
    GuiService.Init()

    MonitorManager.Init()

    ; 加载插件
    PluginService.LoadPlugins()


    HotkeyManager.Init()
    ContextMenuManager.Init()
    TextEngineManager.Init()

    ; 设置系统托盘
    TrayMenu.Init()
}
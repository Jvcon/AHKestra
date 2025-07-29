global APP_VERSION := "1.0.0", APP_NAME := "AHKestra"

;@Ahk2Exe-SetName AHKestra
;@Ahk2Exe-SetDescription A context-aware automation toolbox for Windows
;@Ahk2Exe-SetVersion 0.0.1
;@Ahk2Exe-SetCopyright Jacques Yip
;@Ahk2Exe-SetOrigFilename AHKestra.exe
;@Ahk2Exe-SetMainIcon AHKestra.ico
;@Ahk2Exe-AddResource ..\..\assets\icons\tray_light.ico, 160
;@Ahk2Exe-AddResource ..\..\assets\icons\tray_dark.ico, 161

#Requires AutoHotkey v2.0
#SingleInstance Force

global APP_PLUGINS_DIR := A_ScriptDir . "\Plugins"
global APP_TEMP_DIR := A_ScriptDir . "\Temp"
global APP_LIB_DIR := A_ScriptDir . "\Lib"
global APP_THEMES_DIR := A_ScriptDir . "\Assests\Themes"

; 引入核心库
#Include "%A_ScriptDir%\Core\Common"

#Include %A_ScriptDir%\Core\Api\Events.ahk
#Include %A_ScriptDir%\Core\Api\Contexts.ahk
#Include %A_ScriptDir%\Core\Api\Conditions.ahk

#Include %A_ScriptDir%\Core\Services\ConfigService.ahk
#Include %A_ScriptDir%\Core\Services\GuiService.ahk
#Include %A_ScriptDir%\Core\Services\PluginService.ahk

#Include %A_ScriptDir%\Core\Managers\HotkeyManager.ahk
#Include %A_ScriptDir%\Core\Managers\ContextMenuManager.ahk
#Include %A_ScriptDir%\Core\Managers\TextEngineManager.ahk

#Include %A_ScriptDir%\Core\Views\TrayMenu.ahk
#Include %A_ScriptDir%\Core\Views\SettingsGui.ahk
#Include %A_ScriptDir%\Core\Views\PluginConfigGuiFactory.ahk

; 初始化应用
InitApp()

InitApp() {
    defaultThemeName := "NordDark"
    defaultMenuKey := "#RButton"
    defaultLeaderKey := "Space"

    ; 创建必要的目录
    if (!DirExist(APP_TEMP_DIR))
        DirCreate(APP_TEMP_DIR)
    if (!DirExist(APP_PLUGINS_DIR))
        DirCreate(APP_PLUGINS_DIR)
    if (!DirExist(APP_THEMES_DIR))
        DirCreate(APP_THEMES_DIR)

    defaultThemePath := APP_THEMES_DIR . "\" . defaultThemeName . ".json"

    guiDefaults := Map("activeTheme", defaultThemeName)
    menuDefaults := Map("menuKey", defaultMenuKey)
    hotkeyDefaults := Map("leaderKey", defaultLeaderKey, "timeout", 1000)
    
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
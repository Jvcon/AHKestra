; Main.ahk - 主程序入口
#Requires AutoHotkey v2.0
#SingleInstance Force

; 全局设置
global APP_NAME := "AHKestra"
global APP_VERSION := "1.0.0"
global APP_CONFIG_DIR := A_AppData . "\" . APP_NAME
global APP_PLUGINS_DIR := A_ScriptDir . "\Plugins"
global APP_LIB_DIR := A_ScriptDir . "\Lib"

; 引入核心库
#Include <JSON>
#Include <YAML>
#Include <Monitors>

#Include %A_ScriptDir%\Core\Services\EventService.ahk
#Include %A_ScriptDir%\Core\Services\ContextService.ahk
#Include %A_ScriptDir%\Core\Services\ConditionService.ahk
#Include %A_ScriptDir%\Core\Services\ConfigService.ahk
#Include %A_ScriptDir%\Core\Services\GuiService.ahk
#Include %A_ScriptDir%\Core\Conditions.ahk


#Include %A_ScriptDir%\Core\Managers\PluginManager.ahk
#Include %A_ScriptDir%\Core\Managers\HotkeyManager.ahk
#Include %A_ScriptDir%\Core\Managers\ContextMenuManager.ahk
#Include %A_ScriptDir%\Core\Managers\TextEngineManager.ahk

#Include %A_ScriptDir%\Core\TrayMenu.ahk

; 初始化应用
InitApp()

InitApp() {
    ; 创建必要的目录
    if (!DirExist(APP_CONFIG_DIR))
        DirCreate(APP_CONFIG_DIR)
    if (!DirExist(APP_PLUGINS_DIR))
        DirCreate(APP_PLUGINS_DIR)

    EventService.Init()
    ConditionService.Init()
    GuiService.Init()

    HotkeyManager.Init()
    ContextMenuManager.Init()
    TextEngineManager.Init()
    MonitorManager.Init()

    ; 加载插件
    PluginManager.LoadPlugins()

    ; 加载配置
    ConfigService.Load()

    HotkeyManager.Activate()
    ContextMenuManager.Activate()
    TextEngineManager.Activate()
    MonitorManager.Activate()

    ; 设置系统托盘
    TrayMenu.Init()

    ; 触发应用启动事件
    EventService.Trigger("App.Started")
}
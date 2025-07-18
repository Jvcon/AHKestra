; Main.ahk - 主程序入口
#Requires AutoHotkey v2.0
#SingleInstance Force

; 全局设置
global APP_NAME := "AHKestra"
global APP_VERSION := "1.0.0"
global APP_CONFIG_DIR := A_AppData . "\" . APP_NAME
global APP_PLUGINS_DIR := A_ScriptDir . "\Plugins"
global APP_LIB_DIR := A_ScriptDir . "\Lib"
global AppConfig := {}
global LoadedPlugins := Map()

; 引入核心库
#Include <JSON>
#Include <YAML>

#Include %A_ScriptDir%\Core\EventSystem.ahk
#Include %A_ScriptDir%\Core\ContextInfo.ahk
#Include %A_ScriptDir%\Core\Conditions.ahk
#Include %A_ScriptDir%\Core\ConditionHelper.ahk


#Include %A_ScriptDir%\Core\PluginManager.ahk
#Include %A_ScriptDir%\Core\HotkeyManager.ahk
#Include %A_ScriptDir%\Core\ContextMenuManager.ahk
#Include %A_ScriptDir%\Core\TextEngineManager.ahk

#Include %A_ScriptDir%\Core\Config.ahk
#Include %A_ScriptDir%\Core\TrayMenu.ahk
#Include %A_ScriptDir%\Core\GUI.ahk

; 初始化应用
InitApp()

InitApp() {
    ; 创建必要的目录
    if (!DirExist(APP_CONFIG_DIR))
        DirCreate(APP_CONFIG_DIR)
    if (!DirExist(APP_PLUGINS_DIR))
        DirCreate(APP_PLUGINS_DIR)
        
    ; 加载配置
    Config.Load()
    
    ; 设置系统托盘
    TrayMenu.Init()
    
    ; 加载插件
    PluginManager.LoadPlugins()
    
    ; 初始化主界面
    GUI.Init()
    
    ; 触发应用启动事件
    EventSystem.Trigger("App.Started")
}
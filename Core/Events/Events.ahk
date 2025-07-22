#Include %A_ScriptDir%\IEventProvider.ahk
#Include %A_ScriptDir%\EventBus.ahk
#Include %A_ScriptDir%\EventRegistry.ahk
#Include %A_ScriptDir%\EventLoaderService.ahk


class Events {
    static On(eventName, callback, target := "") {
        EventBus.On(eventName, callback, target)
    }

    static Off(eventName, callback, target := "") {
        EventBus.Off(eventName, callback, target)
    }

    static Trigger(eventName, data := "") {
        EventBus.Trigger(eventName, data)
    }
}
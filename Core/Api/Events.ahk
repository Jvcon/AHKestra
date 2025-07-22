#Include %A_ScriptDir%\..\Events\IEventProvider.ahk
#Include %A_ScriptDir%\..\Events\EventBus.ahk
#Include %A_ScriptDir%\..\Events\EventRegistry.ahk
#Include %A_ScriptDir%\..\Events\EventLoaderService.ahk


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
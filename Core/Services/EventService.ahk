; Core/Services/EventService.ahk - 事件消息服务
class EventService {
    static Listeners := Map()
    
    static On(event, callback) {
        if !this.Listeners.Has(event) {
            this.Listeners[event] := []
        }
        this.Listeners[event].Push(callback)
    }
    
    static Off(event, callback) {
        if this.Listeners.Has(event) {
            listeners := this.Listeners[event]
            for i, listener in listeners {
                if listener == callback {
                    listeners.RemoveAt(i)
                    break
                }
            }
            if listeners.Length == 0 {
                this.Listeners.Delete(event)
            }
        }
    }
    
    static Trigger(event, data := "") {
        if this.Listeners.Has(event) {
            for callback in this.Listeners[event] {
                try {
                    callback(data)
                } catch Error as err {
                    MsgBox("事件处理失败: " . event . "`n" . err.Message)
                }
            }
        }
    }
}
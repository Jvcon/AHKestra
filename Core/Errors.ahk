class NotImplementedError extends Error {
    __New(message := "此方法或功能尚未实现。", what := "", extra := "") {
        super.__New(message, what, extra)
        this.Name := "NotImplementedError"
    }
}
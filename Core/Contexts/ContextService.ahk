#Requires AutoHotkey v2.0
#Include %A_ScriptDir%\..\Contexts\ContextRegistry.ahk

/**
 * 上下文服务 - 负责组装和缓存上下文信息。
 * 这是一个核心的服务层组件，它编排多个上下文提供者（Context Providers）
 * 来构建一个统一的、多层次的上下文视图。
 * 它本身不获取任何数据，只负责管理流程、缓存和生命周期。
 */
class ContextService {
    ; --- 缓存管理属性 ---
    static _cachedContext := Map("stable", "", "active", "")
    static _cacheTimestamps := Map("stable", 0, "active", 0)
    static _cacheDurations := Map(
        "stable", -1,   ; 稳定层：只通过事件失效
        "active", 250   ; 活动层：有效期为 250ms
    )

    /**
     * 初始化服务，主要是启动用于缓存失效的系统事件钩子。
     */
    static Init() {
        Events.On("Window.Activated", this._onWindowActivated.Bind(this))

    }

    /**
     * 卸载服务，释放系统资源。
     */
    static Unhook() {
        Events.Off("Window.Activated", this._onWindowActivated)
    }

    /**
     * 当监听到前台窗口切换事件时，失效相关缓存。
     */
    static _onWindowActivated(data) {
        this.InvalidateContext("all")
    }

    /**
     * 公共接口：允许外部模块按需失效缓存。
     * @param scope {String} 要失效的范围, "all", "active"。
     */
    static InvalidateContext(scope := "active") {
        Switch scope {
            Case "all":
                this._cachedContext.stable := ""
                this._cacheTimestamps.stable := 0
                this._cachedContext.active := ""
                this._cacheTimestamps.active := 0
            Case "active":
                this._cachedContext.active := ""
                this._cacheTimestamps.active := 0
        }
    }

    /**
     * 核心方法：组装三层上下文。
     * 这是服务编排的核心，它按顺序调用不同层级的提供者并应用缓存策略。
     * @returns {Map} 一个包含了所有上下文信息的完整Map对象。
     */
    static GetContext() {
        local now := A_TickCount
        local finalContext := Map()

        ; --- 步骤 1: 构建稳定层 (Stable Layer) ---
        if (this._cachedContext.stable && (this._cacheDurations.stable < 0 || now - this._cacheTimestamps.stable < this._cacheDurations.stable)) {
            finalContext := this._cachedContext.stable.Clone()
        } else {
            for provider in ContextRegistry.GetProvidersByLayer("stable") {
                for key, value in provider.GetValue(finalContext) {
                    finalContext[key] := value
                }
            }
            this._cachedContext.stable := finalContext.Clone()
            this._cacheTimestamps.stable := now
            this.InvalidateContext("active") 
        }

        if (this._cachedContext.active && now - this._cacheTimestamps.active < this._cacheDurations.active) {
            for key, value in this._cachedContext.active {
                finalContext[key] := value
            }
        } else {
            local activeContext := Map()
            for provider in ContextRegistry.GetProvidersByLayer("active") {
                for key, value in provider.GetValue(finalContext) {
                    activeContext[key] := value
                }
            }
            this._cachedContext.active := activeContext
            this._cacheTimestamps.active := now
            for key, value in activeContext {
                finalContext[key] := value
            }
        }

        for provider in ContextRegistry.GetProvidersByLayer("volatile") {
            for key, value in provider.GetValue(finalContext) {
                finalContext[key] := value
            }
        }

        return finalContext
    }
}
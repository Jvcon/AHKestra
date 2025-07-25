
class ManifestsMigration {
    static _migrations := Map(
        ; "2.0", ObjBindMethod(this, "_migrate_1_to_2"),
        ; "3.0", ObjBindMethod(this, "_migrate_2_to_3")
    )

    static Apply(data, latestVersion) {
        if (!IsObject(data) || !data.Has("manifestVersion")) {
            return data
        }
        local currentVersion := data.manifestVersion

        while (this._compareVersions(currentVersion, latestVersion) < 0) {
            local nextVersion := this._findNextVersion(currentVersion)

            if (!this._migrations.Has(nextVersion)) {
                throw Error("无法找到从版本 " . currentVersion . " 到 " . nextVersion . " 的迁移路径。")
            }

            local migrationFunc := this._migrations[nextVersion]
            data := migrationFunc(data)

            currentVersion := data.manifestVersion
        }

        return data
    }
    
/*
    static _migrate_1_to_2(data) {
        if (data.Has("main")) {
            data["entryPoint"] := data["main"]
            data.Delete("main")
        }
        if (data.Has("author")) {
            data["contributors"] := [Map("name", data["author"], "role", "Lead Developer")]
            data.Delete("author")
        }
        data.manifestVersion := "2.0"
        return data
    }

    static _migrate_2_to_3(data) {
        if (data.Has("hotkeys")) {
            local commands := Map()
            local keybindings := []
            for id, hotkeyDef in data.hotkeys {
                commands[id] := hotkeyDef.title
                keybindings.Push(Map("command", id, "key", hotkeyDef.key))
            }
            data.contributes.commands := commands
            data.contributes.keybindings := keybindings
            data.Delete("hotkeys")
        }
        data.manifestVersion := "3.0"
        return data
    }
*/

    static _findNextVersion(fromVersion) {
        ; 在一个真实的项目中，这里应该有更复杂的逻辑来查找已注册的、
        ; 大于 fromVersion 的最小版本。为简化，我们这里直接递增主版本号。
        local parts := StrSplit(fromVersion, ".")
        return (parts[1] + 1) . ".0"
    }

    /** 简化的版本比较函数 */
    static _compareVersions(v1, v2) {
        if (v1 == v2) {
            return 0
        }
        return v1 < v2 ? -1 : 1
    }
}
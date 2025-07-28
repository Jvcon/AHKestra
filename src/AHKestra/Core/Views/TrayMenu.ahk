class TrayMenu {
    static Init() {
        local tray := A_TrayMenu
        tray.Delete() ; 清空默认菜单
        tray.Add("Settings...", (*) => SettingsView.Show())
        tray.Add("---")
        tray.Add("Exit", (*) => ExitApp())
        tray.Default := "Settings..."
    }
}
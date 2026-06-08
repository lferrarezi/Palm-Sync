import SwiftUI

@main
struct PalmSyncMacApp: App {
    @State private var store = AppStore.preview

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .frame(minWidth: 1120, minHeight: 720)
        }
        .defaultSize(width: 1280, height: 820)
        .windowResizability(.contentMinSize)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)

        Settings {
            SettingsView()
                .environment(store)
                .frame(width: 720, height: 520)
        }
    }
}

import SwiftUI

@main
struct PalmSyncMacApp: App {
    @State private var store = AppStore.preview
    @State private var isAboutPresented = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .frame(minWidth: 1120, minHeight: 720)
                .sheet(isPresented: $isAboutPresented) {
                    AboutView()
                        .environment(store)
                }
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

        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("Sobre Palm Sync / About Palm Sync") {
                    isAboutPresented = true
                }
            }
        }
    }
}

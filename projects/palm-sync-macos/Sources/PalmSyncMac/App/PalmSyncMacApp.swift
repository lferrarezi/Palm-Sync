import SwiftUI
import UniformTypeIdentifiers

@main
struct PalmSyncMacApp: App {
    @State private var store = AppStore.preview
    @State private var isAboutPresented = false
    @State private var isImporterPresented = false

    private static let pdbType = UTType(filenameExtension: "pdb") ?? .data

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .frame(minWidth: 1120, minHeight: 720)
                .task { store.attachDatabase() }
                .sheet(isPresented: $isAboutPresented) {
                    AboutView()
                        .environment(store)
                }
                .fileImporter(
                    isPresented: $isImporterPresented,
                    allowedContentTypes: [Self.pdbType],
                    allowsMultipleSelection: true
                ) { result in
                    switch result {
                    case let .success(urls):
                        for url in urls {
                            store.importPalmBackup(from: url)
                        }
                    case let .failure(error):
                        store.lastImportSummary = LocalizedLabel(
                            ptBR: "Não foi possível selecionar o backup: \(error.localizedDescription)",
                            en: "Could not select the backup: \(error.localizedDescription)"
                        )
                    }
                }
                .alert(
                    LocalizedLabel(ptBR: "Importação Palm", en: "Palm Import").text(store.language),
                    isPresented: Binding(
                        get: { store.lastImportSummary != nil },
                        set: { if !$0 { store.lastImportSummary = nil } }
                    )
                ) {
                    Button("OK") { store.lastImportSummary = nil }
                } message: {
                    Text(store.lastImportSummary?.text(store.language) ?? "")
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
            CommandGroup(after: .newItem) {
                Button(LocalizedLabel(ptBR: "Importar backup Palm (.pdb)…", en: "Import Palm backup (.pdb)…").text(store.language)) {
                    isImporterPresented = true
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            }
        }
    }
}

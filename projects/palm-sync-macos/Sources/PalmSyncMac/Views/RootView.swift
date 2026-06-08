import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store

        NavigationSplitView {
            SidebarView(selection: $store.selectedSection)
                .navigationSplitViewColumnWidth(min: 220, ideal: 250)
        } detail: {
            ZStack {
                AppBackground()
                DetailRouter(section: store.selectedSection)
                    .padding(22)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(nil, value: store.selectedSection)
            .transaction { transaction in
                transaction.animation = nil
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        store.startLocalSyncSimulation()
                    } label: {
                        Label(LocalizedLabel(ptBR: "Sincronizar", en: "Sync").text(store.language), systemImage: "arrow.triangle.2.circlepath")
                    }
                    .glassButtonStyle(prominent: true)

                    Button {
                        store.isInspectorPresented.toggle()
                    } label: {
                        Label(LocalizedLabel(ptBR: "Inspetor", en: "Inspector").text(store.language), systemImage: "sidebar.trailing")
                    }
                    .glassButtonStyle()
                }
            }
            .inspector(isPresented: $store.isInspectorPresented) {
                InspectorView()
                    .environment(store)
                    .inspectorColumnWidth(min: 260, ideal: 300, max: 360)
            }
        }
        .searchable(text: $store.searchText, placement: .sidebar)
    }
}

private struct DetailRouter: View {
    var section: AppSection

    var body: some View {
        Group {
            switch section {
            case .dashboard:
                DashboardView()
            case .agenda:
                AgendaView()
            case .contacts:
                ContactsView()
            case .tasks:
                TasksView()
            case .memos:
                MemosView()
            case .devices:
                DevicesView()
            case .sync:
                SyncCenterView()
            case .settings:
                SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct SidebarView: View {
    @Environment(AppStore.self) private var store
    @Binding var selection: AppSection

    var body: some View {
        List(selection: $selection) {
            Section("Palm Sync") {
                ForEach(AppSection.allCases.prefix(5)) { section in
                    NavigationLink(value: section) {
                        Label(section.title(for: store.language), systemImage: section.symbol)
                    }
                }
            }

            Section(LocalizedLabel(ptBR: "Sistema", en: "System").text(store.language)) {
                ForEach(AppSection.allCases.suffix(3)) { section in
                    NavigationLink(value: section) {
                        Label(section.title(for: store.language), systemImage: section.symbol)
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }
}

struct InspectorView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizedLabel(ptBR: "Estado", en: "Status").text(store.language))
                    .font(.headline)

                if let device = store.selectedDevice {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "palm")
                                .font(.title2)
                                .foregroundStyle(PalmTheme.sidebarTint)
                            VStack(alignment: .leading) {
                                Text(device.name)
                                    .font(.subheadline.weight(.semibold))
                                Text(device.model)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            StatusPill(state: device.state)
                        }

                        LabeledContent(LocalizedLabel(ptBR: "Usuario", en: "User").text(store.language), value: device.userID)
                        LabeledContent(LocalizedLabel(ptBR: "Conexao", en: "Connection").text(store.language), value: device.connection)
                        LabeledContent(LocalizedLabel(ptBR: "Bateria", en: "Battery").text(store.language), value: device.battery > 0 ? "\(device.battery)%" : "N/D")
                    }
                    .padding(14)
                    .glassSurface()
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(LocalizedLabel(ptBR: "Pendencias", en: "Pending").text(store.language))
                        .font(.subheadline.weight(.semibold))
                    LabeledContent(LocalizedLabel(ptBR: "Conflitos", en: "Conflicts").text(store.language), value: "\(store.unresolvedCount)")
                    LabeledContent(LocalizedLabel(ptBR: "Mudancas", en: "Changes").text(store.language), value: "\(store.pendingChanges)")
                    LabeledContent(LocalizedLabel(ptBR: "Fontes", en: "Sources").text(store.language), value: "\(store.accounts.count)")
                }
                .padding(14)
                .glassSurface()

                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizedLabel(ptBR: "Contas", en: "Accounts").text(store.language))
                        .font(.subheadline.weight(.semibold))

                    ForEach(store.accounts) { account in
                        HStack {
                            Label(account.provider, systemImage: account.symbol)
                            Spacer()
                            StatusPill(state: account.status)
                        }
                        .font(.caption)
                    }
                }
                .padding(14)
                .glassSurface()
            }
            .padding(18)
        }
        .background(.thinMaterial)
    }
}

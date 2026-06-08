import SwiftUI

struct DevicesView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HeaderView(title: "Dispositivos", subtitle: "Palms conhecidos, portas e estado de HotSync", symbol: "externaldrive.connected.to.line.below")

                ForEach(store.devices) { device in
                    Button {
                        store.selectedDeviceID = device.id
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "palm")
                                .font(.title)
                                .foregroundStyle(device.state.color)
                                .frame(width: 54, height: 54)
                                .glassSurface(tint: device.state.color.opacity(0.12), cornerRadius: PalmTheme.compactCorner)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(device.name)
                                    .font(.title3.weight(.semibold))
                                Text(device.model)
                                    .foregroundStyle(.secondary)
                                Text(device.connection)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 8) {
                                StatusPill(state: device.state)
                                Text(device.lastSync?.formatted(date: .abbreviated, time: .shortened) ?? "Nunca sincronizado")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(16)
                    .glassSurface(interactive: true, tint: store.selectedDeviceID == device.id ? PalmTheme.sidebarTint.opacity(0.12) : nil)
                }

                DiagnosticPanel()
            }
            .frame(maxWidth: PalmTheme.contentWidth)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct DiagnosticPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Diagnostico esperado", systemImage: "stethoscope")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ProbeStep(symbol: "cable.connector", title: "Porta", value: "/dev/cu.*")
                ProbeStep(symbol: "hand.raised", title: "Handshake", value: "HotSync")
                ProbeStep(symbol: "rectangle.stack", title: "Bancos", value: "PDB")
                ProbeStep(symbol: "archivebox", title: "Backup", value: "Snapshot")
            }
        }
        .padding(18)
        .glassSurface()
    }
}

private struct ProbeStep: View {
    var symbol: String
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(PalmTheme.sidebarTint)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(value)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassSurface(interactive: false, tint: PalmTheme.sidebarTint.opacity(0.08), cornerRadius: PalmTheme.compactCorner)
    }
}

struct SyncCenterView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HeaderView(title: "Sincronismo", subtitle: "Palm local primeiro, servicos externos depois", symbol: "arrow.triangle.2.circlepath")

                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Fontes", systemImage: "point.3.connected.trianglepath.dotted")
                            .font(.headline)
                        ForEach(store.accounts) { account in
                            IntegrationRow(account: account)
                        }
                    }
                    .padding(18)
                    .glassSurface()

                    VStack(alignment: .leading, spacing: 14) {
                        Label("Politica", systemImage: "shield.checkered")
                            .font(.headline)
                        PolicyRow(symbol: "archivebox", title: "Snapshot obrigatorio", detail: "Antes de qualquer escrita no Palm")
                        PolicyRow(symbol: "arrow.left.arrow.right", title: "Merge por origem", detail: "Palm, local, Google e iCloud mantem cursores")
                        PolicyRow(symbol: "exclamationmark.bubble", title: "Conflito visivel", detail: "Nada e sobrescrito sem revisao")
                    }
                    .padding(18)
                    .glassSurface()
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("Historico", systemImage: "clock")
                        .font(.headline)
                    ForEach(store.syncRuns) { run in
                        HStack(spacing: 12) {
                            StatusPill(state: run.status)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(run.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(run.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(run.startedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(run.changes)")
                                .font(.caption.monospacedDigit())
                                .frame(width: 34)
                        }
                        .padding(12)
                        .glassSurface(cornerRadius: PalmTheme.compactCorner)
                    }
                }
                .padding(18)
                .glassSurface()
            }
            .frame(maxWidth: PalmTheme.contentWidth)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct IntegrationRow: View {
    var account: IntegrationAccount

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: account.symbol)
                .font(.title3)
                .frame(width: 34, height: 34)
                .glassSurface(tint: account.status.color.opacity(0.10), cornerRadius: PalmTheme.compactCorner)
            VStack(alignment: .leading, spacing: 3) {
                Text(account.provider)
                    .font(.subheadline.weight(.semibold))
                Text(account.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            StatusPill(state: account.status)
        }
        .padding(12)
        .glassSurface(interactive: true, cornerRadius: PalmTheme.compactCorner)
    }
}

private struct PolicyRow: View {
    var symbol: String
    var title: String
    var detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(PalmTheme.amber)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var automaticBackup = true
    @State private var conflictMode = "Perguntar"
    @State private var selectedCollections: Set<String> = ["Agenda", "Contatos", "Tarefas", "Notas"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HeaderView(title: "Ajustes", subtitle: "Preferencias do piloto macOS", symbol: "gearshape")

                VStack(alignment: .leading, spacing: 18) {
                    LabeledContent("Versao", value: AppVersionInfo.displayVersion)
                    LabeledContent("Build", value: "\(AppVersionInfo.build)")

                    Toggle(isOn: $automaticBackup) {
                        Label("Backup automatico antes do HotSync", systemImage: "archivebox")
                    }

                    Picker("Conflitos", selection: $conflictMode) {
                        Text("Perguntar").tag("Perguntar")
                        Text("Preferir Palm").tag("Preferir Palm")
                        Text("Preferir local").tag("Preferir local")
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Colecoes")
                            .font(.subheadline.weight(.semibold))
                        HStack {
                            ForEach(["Agenda", "Contatos", "Tarefas", "Notas"], id: \.self) { collection in
                                Toggle(collection, isOn: Binding(
                                    get: { selectedCollections.contains(collection) },
                                    set: { enabled in
                                        if enabled {
                                            selectedCollections.insert(collection)
                                        } else {
                                            selectedCollections.remove(collection)
                                        }
                                    }
                                ))
                                .toggleStyle(.checkbox)
                            }
                        }
                    }
                }
                .padding(18)
                .glassSurface()

                VStack(alignment: .leading, spacing: 12) {
                    Label("Contas configuradas", systemImage: "person.badge.key")
                        .font(.headline)
                    ForEach(store.accounts) { account in
                        IntegrationRow(account: account)
                    }
                }
                .padding(18)
                .glassSurface()
            }
            .frame(maxWidth: PalmTheme.contentWidth)
            .frame(maxWidth: .infinity)
            .padding(22)
        }
        .background(AppBackground())
    }
}

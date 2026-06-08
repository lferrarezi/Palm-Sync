import SwiftUI

struct DevicesView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HeaderView(title: LocalizedLabel(ptBR: "Dispositivos", en: "Devices").text(store.language), subtitle: LocalizedLabel(ptBR: "Palms conhecidos, portas e estado de HotSync", en: "Known Palms, ports, and HotSync status").text(store.language), symbol: "externaldrive.connected.to.line.below")

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
                                Text(device.lastSync?.formatted(date: .abbreviated, time: .shortened) ?? LocalizedLabel(ptBR: "Nunca sincronizado", en: "Never synced").text(store.language))
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct DiagnosticPanel: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(LocalizedLabel(ptBR: "Diagnostico esperado", en: "Expected diagnostics").text(store.language), systemImage: "stethoscope")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ProbeStep(symbol: "cable.connector", title: LocalizedLabel(ptBR: "Porta", en: "Port").text(store.language), value: "/dev/cu.*")
                ProbeStep(symbol: "hand.raised", title: "Handshake", value: "HotSync")
                ProbeStep(symbol: "rectangle.stack", title: LocalizedLabel(ptBR: "Bancos", en: "Databases").text(store.language), value: "PDB")
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
                HeaderView(title: LocalizedLabel(ptBR: "Sincronismo", en: "Sync").text(store.language), subtitle: LocalizedLabel(ptBR: "Palm local primeiro, servicos externos depois", en: "Local Palm first, external services later").text(store.language), symbol: "arrow.triangle.2.circlepath")

                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        Label(LocalizedLabel(ptBR: "Fontes", en: "Sources").text(store.language), systemImage: "point.3.connected.trianglepath.dotted")
                            .font(.headline)
                        ForEach(store.accounts) { account in
                            IntegrationRow(account: account)
                        }
                    }
                    .padding(18)
                    .glassSurface()

                    VStack(alignment: .leading, spacing: 14) {
                        Label(LocalizedLabel(ptBR: "Politica", en: "Policy").text(store.language), systemImage: "shield.checkered")
                            .font(.headline)
                        PolicyRow(symbol: "archivebox", title: LocalizedLabel(ptBR: "Snapshot obrigatorio", en: "Required snapshot").text(store.language), detail: LocalizedLabel(ptBR: "Antes de qualquer escrita no Palm", en: "Before any Palm write").text(store.language))
                        PolicyRow(symbol: "arrow.left.arrow.right", title: LocalizedLabel(ptBR: "Merge por origem", en: "Merge by source").text(store.language), detail: LocalizedLabel(ptBR: "Palm, local, Google e iCloud mantem cursores", en: "Palm, local, Google, and iCloud keep cursors").text(store.language))
                        PolicyRow(symbol: "exclamationmark.bubble", title: LocalizedLabel(ptBR: "Conflito visivel", en: "Visible conflict").text(store.language), detail: LocalizedLabel(ptBR: "Nada e sobrescrito sem revisao", en: "Nothing is overwritten without review").text(store.language))
                    }
                    .padding(18)
                    .glassSurface()
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label(LocalizedLabel(ptBR: "Historico", en: "History").text(store.language), systemImage: "clock")
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        @Bindable var store = store

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HeaderView(
                    title: LocalizedLabel(ptBR: "Ajustes", en: "Settings").text(store.language),
                    subtitle: LocalizedLabel(ptBR: "Preferencias do piloto macOS", en: "macOS pilot preferences").text(store.language),
                    symbol: "gearshape"
                )

                VStack(alignment: .leading, spacing: 18) {
                    Picker(LocalizedLabel(ptBR: "Idioma", en: "Language").text(store.language), selection: $store.language) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.title).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)

                    LabeledContent(LocalizedLabel(ptBR: "Versao", en: "Version").text(store.language), value: AppVersionInfo.displayVersion)
                    LabeledContent("Build", value: "\(AppVersionInfo.build)")

                    Toggle(isOn: $automaticBackup) {
                        Label(LocalizedLabel(ptBR: "Backup automatico antes do HotSync", en: "Automatic backup before HotSync").text(store.language), systemImage: "archivebox")
                    }

                    Picker(LocalizedLabel(ptBR: "Conflitos", en: "Conflicts").text(store.language), selection: $conflictMode) {
                        Text(LocalizedLabel(ptBR: "Perguntar", en: "Ask").text(store.language)).tag("Perguntar")
                        Text(LocalizedLabel(ptBR: "Preferir Palm", en: "Prefer Palm").text(store.language)).tag("Preferir Palm")
                        Text(LocalizedLabel(ptBR: "Preferir local", en: "Prefer local").text(store.language)).tag("Preferir local")
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedLabel(ptBR: "Colecoes", en: "Collections").text(store.language))
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
                    Label(LocalizedLabel(ptBR: "Contas configuradas", en: "Configured accounts").text(store.language), systemImage: "person.badge.key")
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

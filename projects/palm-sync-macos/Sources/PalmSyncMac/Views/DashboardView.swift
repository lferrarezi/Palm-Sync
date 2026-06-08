import SwiftUI

struct DashboardView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HeaderView(
                    title: "Palm Sync",
                    subtitle: LocalizedLabel(ptBR: "Desktop sync para Palm OS, Google, iCloud e banco local", en: "Desktop sync for Palm OS, Google, iCloud, and local storage").text(store.language),
                    symbol: "palm"
                )

                if #available(macOS 26.0, *) {
                    GlassEffectContainer(spacing: 18) {
                        metrics
                    }
                } else {
                    metrics
                }

                HStack(alignment: .top, spacing: 18) {
                    DeviceFocusPanel()
                        .frame(maxWidth: .infinity)
                    SyncTimelinePanel()
                        .frame(maxWidth: .infinity)
                }

                CollectionOverviewPanel()
            }
            .frame(maxWidth: PalmTheme.contentWidth)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var metrics: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
            MetricTile(title: LocalizedLabel(ptBR: "Eventos", en: "Events").text(store.language), value: "\(store.events.count)", symbol: "calendar", tint: .blue)
            MetricTile(title: LocalizedLabel(ptBR: "Contatos", en: "Contacts").text(store.language), value: "\(store.contacts.count)", symbol: "person.2", tint: .green)
            MetricTile(title: LocalizedLabel(ptBR: "Tarefas", en: "Tasks").text(store.language), value: "\(store.tasks.count)", symbol: "checklist", tint: .orange)
            MetricTile(title: LocalizedLabel(ptBR: "Notas", en: "Memos").text(store.language), value: "\(store.memos.count)", symbol: "note.text", tint: .purple)
        }
    }
}

struct HeaderView: View {
    var title: String
    var subtitle: String
    var symbol: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(PalmTheme.sidebarTint)
                .frame(width: 64, height: 64)
                .glassSurface(interactive: false, tint: PalmTheme.sidebarTint.opacity(0.12))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.largeTitle.weight(.semibold))
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

private struct DeviceFocusPanel: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(LocalizedLabel(ptBR: "Dispositivo ativo", en: "Active device").text(store.language), systemImage: "externaldrive.connected.to.line.below")
                .font(.headline)

            if let device = store.selectedDevice {
                HStack(alignment: .center, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(device.name)
                            .font(.title2.weight(.semibold))
                        Text(device.model)
                            .foregroundStyle(.secondary)
                        Text(device.connection)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 10) {
                        StatusPill(state: device.state)
                        Text(device.lastSync?.formatted(date: .abbreviated, time: .shortened) ?? LocalizedLabel(ptBR: "Sem sync", en: "No sync").text(store.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(18)
        .glassSurface()
    }
}

private struct SyncTimelinePanel: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(LocalizedLabel(ptBR: "Ultimos sincronismos", en: "Recent syncs").text(store.language), systemImage: "clock.arrow.circlepath")
                .font(.headline)

            ForEach(store.syncRuns.prefix(3)) { run in
                HStack(spacing: 12) {
                    Image(systemName: run.status == .ready ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(run.status.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(run.title.text(store.language))
                            .font(.subheadline.weight(.medium))
                        Text(run.summary.text(store.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(run.changes)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 3)
            }
        }
        .padding(18)
        .glassSurface()
    }
}

private struct CollectionOverviewPanel: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(LocalizedLabel(ptBR: "Colecoes classicas", en: "Classic collections").text(store.language), systemImage: "rectangle.stack")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                CollectionCard(title: LocalizedLabel(ptBR: "Agenda", en: "Calendar").text(store.language), count: store.events.count, symbol: "calendar", tint: .blue)
                CollectionCard(title: LocalizedLabel(ptBR: "Contatos", en: "Contacts").text(store.language), count: store.contacts.count, symbol: "person.crop.circle", tint: .green)
                CollectionCard(title: LocalizedLabel(ptBR: "Tarefas", en: "Tasks").text(store.language), count: store.tasks.count, symbol: "checklist", tint: .orange)
                CollectionCard(title: LocalizedLabel(ptBR: "Notas", en: "Memos").text(store.language), count: store.memos.count, symbol: "note.text", tint: .purple)
            }
        }
        .padding(18)
        .glassSurface()
    }
}

private struct CollectionCard: View {
    @Environment(AppStore.self) private var store
    var title: String
    var count: Int
    var symbol: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .font(.title2)
            Text(title)
                .font(.subheadline.weight(.medium))
            Text("\(count) \(LocalizedLabel(ptBR: "itens", en: "items").text(store.language))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassSurface(interactive: true, tint: tint.opacity(0.08), cornerRadius: PalmTheme.compactCorner)
    }
}

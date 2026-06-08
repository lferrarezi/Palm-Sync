import SwiftUI

struct DashboardView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HeaderView(
                    title: "Palm Sync",
                    subtitle: "Desktop sync para Palm OS, Google, iCloud e banco local",
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
    }

    private var metrics: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
            MetricTile(title: "Eventos", value: "\(store.events.count)", symbol: "calendar", tint: .blue)
            MetricTile(title: "Contatos", value: "\(store.contacts.count)", symbol: "person.2", tint: .green)
            MetricTile(title: "Tarefas", value: "\(store.tasks.count)", symbol: "checklist", tint: .orange)
            MetricTile(title: "Notas", value: "\(store.memos.count)", symbol: "note.text", tint: .purple)
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
            Label("Dispositivo ativo", systemImage: "externaldrive.connected.to.line.below")
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
                        Text(device.lastSync?.formatted(date: .abbreviated, time: .shortened) ?? "Sem sync")
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
            Label("Ultimos sincronismos", systemImage: "clock.arrow.circlepath")
                .font(.headline)

            ForEach(store.syncRuns.prefix(3)) { run in
                HStack(spacing: 12) {
                    Image(systemName: run.status == .ready ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(run.status.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(run.title)
                            .font(.subheadline.weight(.medium))
                        Text(run.summary)
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
            Label("Colecoes classicas", systemImage: "rectangle.stack")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                CollectionCard(title: "Agenda", count: store.events.count, symbol: "calendar", tint: .blue)
                CollectionCard(title: "Contatos", count: store.contacts.count, symbol: "person.crop.circle", tint: .green)
                CollectionCard(title: "Tarefas", count: store.tasks.count, symbol: "checklist", tint: .orange)
                CollectionCard(title: "Notas", count: store.memos.count, symbol: "note.text", tint: .purple)
            }
        }
        .padding(18)
        .glassSurface()
    }
}

private struct CollectionCard: View {
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
            Text("\(count) itens")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassSurface(interactive: true, tint: tint.opacity(0.08), cornerRadius: PalmTheme.compactCorner)
    }
}


import SwiftUI

struct AgendaView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ContentListShell(title: LocalizedLabel(ptBR: "Agenda", en: "Calendar").text(store.language), subtitle: "DatebookDB, Google Calendar e iCloud / DatebookDB, Google Calendar, and iCloud", symbol: "calendar") {
            ForEach(store.events) { event in
                HStack(spacing: 14) {
                    VStack {
                        Text(event.date.formatted(.dateTime.day()))
                            .font(.title3.weight(.semibold))
                        Text(event.date.formatted(.dateTime.month(.abbreviated)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 54, height: 54)
                    .glassSurface(tint: .blue.opacity(0.10), cornerRadius: PalmTheme.compactCorner)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(event.title)
                                .font(.headline)
                            if event.needsReview {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                        Text("\(event.date.formatted(date: .omitted, time: .shortened)) • \(event.durationMinutes) min • \(event.location)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    SourceBadge(source: event.source)
                }
                .padding(14)
                .glassSurface()
            }
        }
    }
}

struct ContactsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ContentListShell(title: LocalizedLabel(ptBR: "Contatos", en: "Contacts").text(store.language), subtitle: "AddressDB, Google People e CardDAV / AddressDB, Google People, and CardDAV", symbol: "person.crop.circle") {
            ForEach(store.contacts) { contact in
                HStack(spacing: 14) {
                    Circle()
                        .fill(contact.source.tint.gradient)
                        .frame(width: 42, height: 42)
                        .overlay {
                            Text(initials(contact.name))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(contact.name)
                                .font(.headline)
                            if contact.needsReview {
                                Image(systemName: "person.crop.circle.badge.exclamationmark")
                                    .foregroundStyle(.orange)
                            }
                        }
                        Text(contact.company)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(contact.phone) • \(contact.email)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    SourceBadge(source: contact.source)
                }
                .padding(14)
                .glassSurface()
            }
        }
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
    }
}

struct TasksView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store

        ContentListShell(title: LocalizedLabel(ptBR: "Tarefas", en: "Tasks").text(store.language), subtitle: LocalizedLabel(ptBR: "ToDoDB com prioridades e vencimentos", en: "ToDoDB with priorities and due dates").text(store.language), symbol: "checklist") {
            ForEach(store.tasks) { task in
                Button {
                    store.toggleTask(task)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(task.isDone ? .green : .secondary)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.headline)
                                .strikethrough(task.isDone)
                            Text(task.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? LocalizedLabel(ptBR: "Sem vencimento", en: "No due date").text(store.language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("P\(task.priority)")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .glassSurface(tint: .orange.opacity(0.10), cornerRadius: PalmTheme.compactCorner)
                        SourceBadge(source: task.source)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(14)
                .glassSurface(interactive: true)
            }
        }
    }
}

struct MemosView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ContentListShell(title: LocalizedLabel(ptBR: "Notas", en: "Memos").text(store.language), subtitle: LocalizedLabel(ptBR: "MemoDB preservado com categorias", en: "MemoDB preserved with categories").text(store.language), symbol: "note.text") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 2), spacing: 14) {
                ForEach(store.memos) { memo in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(memo.title)
                                .font(.headline)
                            Spacer()
                            SourceBadge(source: memo.source)
                        }
                        Text(memo.body)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(4)
                        HStack {
                            Text(memo.category)
                            Spacer()
                            Text(memo.updatedAt.formatted(date: .abbreviated, time: .omitted))
                        }
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    }
                    .frame(minHeight: 150, alignment: .top)
                    .padding(16)
                    .glassSurface(interactive: true, tint: .purple.opacity(0.08))
                }
            }
        }
    }
}

struct ContentListShell<Content: View>: View {
    var title: String
    var subtitle: String
    var symbol: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HeaderView(title: title, subtitle: subtitle, symbol: symbol)
                VStack(spacing: 12) {
                    content
                }
            }
            .frame(maxWidth: PalmTheme.contentWidth)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

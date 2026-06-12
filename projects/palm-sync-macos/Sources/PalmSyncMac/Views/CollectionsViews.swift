import SwiftUI

struct AgendaView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ContentListShell(title: LocalizedLabel(ptBR: "Agenda", en: "Calendar").text(store.language), subtitle: LocalizedLabel(ptBR: "DatebookDB, Google Calendar e iCloud", en: "DatebookDB, Google Calendar, and iCloud").text(store.language), symbol: "calendar") {
            ForEach(store.filteredEvents) { event in
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
                            Text(event.title.text(store.language))
                                .font(.headline)
                            if event.needsReview {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                        Text(eventDetails(event))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let notes = event.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                    SourceBadge(source: event.source)
                }
                .padding(14)
                .glassSurface()
            }
        }
    }

    private func eventDetails(_ event: CalendarItem) -> String {
        var parts = [event.date.formatted(date: .omitted, time: .shortened)]
        if event.durationMinutes > 0 {
            parts.append("\(event.durationMinutes) min")
        }
        if !event.location.isEmpty {
            parts.append(event.location)
        }
        return parts.joined(separator: " • ")
    }
}

struct ContactsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ContentListShell(title: LocalizedLabel(ptBR: "Contatos", en: "Contacts").text(store.language), subtitle: LocalizedLabel(ptBR: "AddressDB, Google People e CardDAV", en: "AddressDB, Google People, and CardDAV").text(store.language), symbol: "person.crop.circle") {
            ForEach(store.filteredContacts) { contact in
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
                        Text(contact.company.text(store.language))
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
            ForEach(store.filteredTasks) { task in
                Button {
                    store.toggleTask(task)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(task.isDone ? .green : .secondary)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title.text(store.language))
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
                ForEach(store.filteredMemos) { memo in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(memo.title.text(store.language))
                                .font(.headline)
                            Spacer()
                            SourceBadge(source: memo.source)
                        }
                        Text(memo.body.text(store.language))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(4)
                        HStack {
                            Text(memo.category.text(store.language))
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

//import SwiftUI
//
//struct JournalView: View {
//    @ObservedObject var store: JournalStore
//
//    @State private var draft = ""
//    @FocusState private var focusComposer: Bool
//    @State private var expanded: Set<UUID> = []   // which sessions are expanded
//
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 16) {
//
//                // Composer for the CURRENT session
//                VStack(alignment: .leading, spacing: 10) {
//                    HStack {
//                        Text("New Entry")
//                            .font(.headline)
//                        Spacer()
//                        // Show which session we're writing to
//                        if let s = store.currentSession {
//                            Text(s.startedAt.formatted(date: .abbreviated, time: .shortened))
//                                .font(.caption).foregroundStyle(.secondary)
//                                .padding(.horizontal, 10)
//                                .padding(.vertical, 6)
//                                .background(Capsule().fill(Color(.tertiarySystemBackground)))
//                        }
//                    }
//
//                    ZStack(alignment: .topLeading) {
//                        TextEditor(text: $draft)
//                            .frame(minHeight: 120)
//                            .padding(10)
//                            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
//                            .focused($focusComposer)
//
//                        if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//                            Text("Feel free to write privately about your emotions and feelings…")
//                                .foregroundStyle(.secondary)
//                                .padding(.top, 16).padding(.leading, 16)
//                                .allowsHitTesting(false)
//                        }
//                    }
//
//                    HStack(spacing: 10) {
//                        Button {
//                            store.startNewSession()
//                            draft = ""
//                            focusComposer = true
//                        } label: {
//                            Label("New Session", systemImage: "plus.circle.fill")
//                                .font(.subheadline.weight(.semibold))
//                        }
//                        .buttonStyle(.bordered)
//
//                        Spacer()
//
//                        Button {
//                            store.add(draft)
//                            draft = ""
//                            focusComposer = false
//                        } label: {
//                            Text("Add Entry")
//                                .font(.headline)
//                                .padding(.horizontal, 18)
//                                .padding(.vertical, 10)
//                        }
//                        .buttonStyle(.borderedProminent)
//                        .tint(.btAccent)
//                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
//                    }
//                }
//                .padding(16)
//                .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
//                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.06), lineWidth: 0.5))
//
//                // Session log (collapsible)
//                VStack(spacing: 10) {
//                    ForEach(store.sessions) { session in
//                        SessionCard(
//                            session: session,
//                            isExpanded: expanded.contains(session.id),
//                            onToggle: {
//                                if expanded.contains(session.id) { expanded.remove(session.id) }
//                                else { expanded.insert(session.id) }
//                            },
//                            onMakeCurrent: { store.selectSession(session.id) },
//                            onDeleteSession: { store.deleteSession(session.id) },
//                            onDeleteEntries: { offsets in store.deleteEntries(in: session.id, at: offsets) }
//                        )
//                    }
//
//                    if store.sessions.isEmpty {
//                        ContentUnavailableView("No journal yet",
//                                               systemImage: "square.and.pencil",
//                                               description: Text("Start a new session above to begin writing."))
//                            .frame(maxWidth: .infinity)
//                    }
//                }
//            }
//            .padding(.horizontal)
//            .padding(.bottom, 16)
//        }
//        .navigationTitle("Journal")
//        .navigationBarTitleDisplayMode(.inline)
//        .onAppear {
//            if store.currentSession == nil { store.startNewSession() }
//            if store.currentSession?.entries.isEmpty == true { focusComposer = true }
//        }
//    }
//}
//
//// MARK: - Session Card
//
//private struct SessionCard: View {
//    let session: JournalStore.Session
//    let isExpanded: Bool
//    let onToggle: () -> Void
//    let onMakeCurrent: () -> Void
//    let onDeleteSession: () -> Void
//    let onDeleteEntries: (IndexSet) -> Void
//
//    var body: some View {
//        VStack(spacing: 0) {
//            // Header row
//            HStack(spacing: 12) {
//                Button(action: onToggle) {
//                    Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
//                        .font(.title3)
//                }
//                .buttonStyle(.plain)
//
//                VStack(alignment: .leading, spacing: 2) {
//                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
//                        .font(.headline)
//                    Text("\(session.entries.count) entr\(session.entries.count == 1 ? "y" : "ies")")
//                        .font(.caption).foregroundStyle(.secondary)
//                }
//
//                Spacer()
//
//                Menu {
//                    Button("Set as Current", action: onMakeCurrent)
//                    Divider()
//                    Button(role: .destructive, action: onDeleteSession) {
//                        Label("Delete Session", systemImage: "trash")
//                    }
//                } label: {
//                    Image(systemName: "ellipsis.circle")
//                        .font(.title3)
//                }
//            }
//            .padding(14)
//
//            if isExpanded {
//                Divider()
//
//                if session.entries.isEmpty {
//                    Text("No entries in this session yet.")
//                        .font(.subheadline).foregroundStyle(.secondary)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .padding(14)
//                } else {
//                    // List-like area
//                    VStack(spacing: 0) {
//                        ForEach(Array(session.entries.enumerated()), id: \.element.id) { idx, e in
//                            VStack(alignment: .leading, spacing: 6) {
//                                Text(e.createdAt.formatted(date: .abbreviated, time: .shortened))
//                                    .font(.caption).foregroundStyle(.secondary)
//                                Text(e.text)
//                            }
//                            .padding(14)
//
//                            if idx < session.entries.count - 1 {
//                                Divider()
//                            }
//                        }
//                    }
//                    .background(Color(.systemBackground))
//                    .overlay(
//                        // Swipe-to-delete affordance via context menu (simple & cross-platform)
//                        RoundedRectangle(cornerRadius: 0)
//                            .fill(Color.clear)
//                            .contextMenu {
//                                Button(role: .destructive) {
//                                    // delete last entry as a simple example (use onDeleteEntries with IndexSet for custom UI)
//                                    if let last = session.entries.first {
//                                        if let idx = session.entries.firstIndex(where: { $0.id == last.id }) {
//                                            onDeleteEntries(IndexSet(integer: idx))
//                                        }
//                                    }
//                                } label: {
//                                    Label("Delete Most Recent Entry", systemImage: "trash")
//                                }
//                            }
//                    )
//                }
//            }
//        }
//        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
//        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 0.5))
//    }
//}


import SwiftUI

struct JournalView: View {
    @ObservedObject var store: JournalStore

    @State private var draft = ""
    @FocusState private var isFocused: Bool
    @State private var expanded: Set<UUID> = []  // which entries are expanded

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Composer card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.pencil") // notepad/pen icon
                            .font(.title2)
                            .foregroundStyle(Color.btAccent)
                        Text("New Entry")
                            .font(.headline)
                        Spacer()
                    }

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $draft)
                            .frame(minHeight: 120)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
                            .focused($isFocused)

                        if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Feel free to write privately about your emotions and feelings…")
                                .foregroundStyle(.secondary)
                                .padding(.top, 16).padding(.leading, 16)
                                .allowsHitTesting(false)
                        }
                    }

                    HStack {
                        Spacer()
                        Button {
                            store.add(draft)
                            draft = ""
                            isFocused = false
                        } label: {
                            Label("Add Entry", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.btAccent)
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.06), lineWidth: 0.5))

                // Log of entries (expandable)
                if store.entries.isEmpty {
                    ContentUnavailableView(
                        "No journal entries yet",
                        systemImage: "note.text",
                        description: Text("Your reflections will appear here.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                } else {
                    VStack(spacing: 10) {
                        ForEach(store.entries) { entry in
                            EntryRow(
                                entry: entry,
                                isExpanded: expanded.contains(entry.id),
                                onToggle: {
                                    if expanded.contains(entry.id) { expanded.remove(entry.id) }
                                    else { expanded.insert(entry.id) }
                                },
                                onDelete: { store.delete(IndexSet(integer: store.entries.firstIndex(of: entry)!)) }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if store.entries.isEmpty { isFocused = true } }
    }
}

// MARK: - Entry Row

// MARK: - Entry Row

private struct EntryRow: View {
    let entry: JournalStore.Entry
    let isExpanded: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void

    // A nice, non-revealing title
    private var title: String {
        let df = DateFormatter()
        df.dateFormat = "EEE, MMM d • h:mm a"
        return "Journal Entry — \(df.string(from: entry.createdAt))"
    }

    // Small, helpful meta without exposing content
    private var meta: String {
        let wc = entry.text
            .split { $0.isWhitespace || $0.isNewline }
            .count
        return wc > 0 ? "\(wc) words" : "Empty"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: isExpanded ? "chevron.down.circle.fill"
                                                 : "chevron.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(meta)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete Entry", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)

            // Revealed content
            if isExpanded {
                Divider()
                Text(entry.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            }
        }
        .background(RoundedRectangle(cornerRadius: 16)
            .fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(Color.white.opacity(0.05), lineWidth: 0.5))
    }
}

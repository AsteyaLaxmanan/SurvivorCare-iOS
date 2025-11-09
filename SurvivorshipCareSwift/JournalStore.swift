//import Foundation
//import Combine
//
//@MainActor
//final class JournalStore: ObservableObject {
//
//    // MARK: - Models (namespaced)
//    struct Entry: Codable, Identifiable, Equatable {
//        let id: UUID
//        let createdAt: Date
//        var text: String
//
//        init(id: UUID = UUID(), createdAt: Date = Date(), text: String) {
//            self.id = id
//            self.createdAt = createdAt
//            self.text = text
//        }
//    }
//
//    struct Session: Codable, Identifiable, Equatable {
//        let id: UUID
//        let startedAt: Date
//        var entries: [Entry]
//
//        init(id: UUID = UUID(), startedAt: Date = Date(), entries: [Entry] = []) {
//            self.id = id
//            self.startedAt = startedAt
//            self.entries = entries
//        }
//    }
//
//    // MARK: - State
//
//    /// All known sessions (most recent first)
//    @Published private(set) var sessions: [Session] = []
//
//    /// The session you are currently writing to
//    @Published var currentSessionID: UUID?
//
//    // MARK: - File I/O
//
//    private var docsURL: URL {
//        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//    }
//
//    private func fileURL(for session: Session) -> URL {
//        let stamp = Int(session.startedAt.timeIntervalSince1970)
//        return docsURL.appendingPathComponent("journal-\(stamp).json")
//    }
//
//    private func loadSessionsFromDisk() {
//        do {
//            let files = try FileManager.default.contentsOfDirectory(at: docsURL,
//                                                                    includingPropertiesForKeys: nil,
//                                                                    options: [.skipsHiddenFiles])
//                .filter { $0.lastPathComponent.hasPrefix("journal-") && $0.pathExtension == "json" }
//
//            var loaded: [Session] = []
//            let dec = JSONDecoder()
//            dec.dateDecodingStrategy = .iso8601
//
//            for url in files {
//                if let data = try? Data(contentsOf: url),
//                   let sess = try? dec.decode(Session.self, from: data) {
//                    loaded.append(sess)
//                }
//            }
//
//            // newest first
//            loaded.sort { $0.startedAt > $1.startedAt }
//            self.sessions = loaded
//
//            // pick latest as current, or create one
//            if currentSessionID == nil {
//                currentSessionID = sessions.first?.id
//            }
//            if currentSessionID == nil {
//                startNewSession()
//            }
//        } catch {
//            print("[Journal] Load directory error:", error.localizedDescription)
//            if currentSessionID == nil { startNewSession() }
//        }
//    }
//
//    private func save(_ session: Session) {
//        do {
//            let enc = JSONEncoder()
//            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
//            enc.dateEncodingStrategy = .iso8601
//            let data = try enc.encode(session)
//            try data.write(to: fileURL(for: session), options: .atomic)
//        } catch {
//            print("[Journal] Save error:", error.localizedDescription)
//        }
//    }
//
//    // MARK: - API
//
//    init() {
//        loadSessionsFromDisk()
//    }
//
//    func startNewSession() {
//        let s = Session()
//        sessions.insert(s, at: 0)
//        currentSessionID = s.id
//        save(s)
//    }
//
//    func selectSession(_ id: UUID) {
//        currentSessionID = id
//    }
//
//    private func indexFor(_ id: UUID) -> Int? {
//        sessions.firstIndex(where: { $0.id == id })
//    }
//
//    func add(_ text: String) {
//        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmed.isEmpty, let id = currentSessionID, let idx = indexFor(id) else { return }
//        sessions[idx].entries.insert(Entry(text: trimmed), at: 0)
//        save(sessions[idx])
//    }
//
//    func deleteEntries(in sessionID: UUID, at offsets: IndexSet) {
//        guard let idx = indexFor(sessionID) else { return }
//        for i in offsets.sorted(by: >) {
//            if sessions[idx].entries.indices.contains(i) {
//                sessions[idx].entries.remove(at: i)
//            }
//        }
//        save(sessions[idx])
//    }
//
//    func deleteSession(_ sessionID: UUID) {
//        guard let idx = indexFor(sessionID) else { return }
//        // remove file
//        let url = fileURL(for: sessions[idx])
//        try? FileManager.default.removeItem(at: url)
//        // remove from memory
//        sessions.remove(at: idx)
//        // pick a new current
//        currentSessionID = sessions.first?.id
//        if currentSessionID == nil { startNewSession() }
//    }
//
//    // helpers for UI
//    var currentSession: Session? {
//        guard let id = currentSessionID else { return nil }
//        return sessions.first(where: { $0.id == id })
//    }
//}


import Foundation
import Combine
import SwiftUI

@MainActor
final class JournalStore: ObservableObject {

    // Namespaced model to avoid collisions
    struct Entry: Codable, Identifiable, Equatable {
        let id: UUID
        let createdAt: Date
        var text: String

        init(id: UUID = UUID(), createdAt: Date = Date(), text: String) {
            self.id = id
            self.createdAt = createdAt
            self.text = text
        }
    }

    @Published private(set) var entries: [Entry] = []

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("journal-entries.json")
    }()

    init() { load() }

    // MARK: - CRUD

    func add(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        entries.insert(Entry(text: trimmed), at: 0) // newest on top
        save()
    }

    func update(_ entry: Entry, text: String) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[idx].text = text
        save()
    }

    func delete(_ offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([Entry].self, from: data)
            self.entries = decoded.sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("[Journal] Load error:", error.localizedDescription)
        }
    }

    private func save() {
        do {
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
            enc.dateEncodingStrategy = .iso8601
            let data = try enc.encode(entries)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[Journal] Save error:", error.localizedDescription)
        }
    }
}

////
////  JournalStore.swift
////  SurvivorshipCareSwift
////
////  Created by Asteya Laxmanan on 11/9/25.
////
//import Foundation
//import Combine
//
//struct JournalEntry: Codable, Identifiable, Equatable {
//    let id: UUID
//    let createdAt: Date
//    var text: String
//
//    init(id: UUID = UUID(), createdAt: Date = Date(), text: String) {
//        self.id = id
//        self.createdAt = createdAt
//        self.text = text
//    }
//}
//
//final class JournalStore: ObservableObject {
//    @Published private(set) var entries: [JournalEntry] = []
//
//    private let fileURL: URL = {
//        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        return docs.appendingPathComponent("journal-entries.json")
//    }()
//
//    init() {
//        load()
//    }
//
//    func add(_ text: String) {
//        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmed.isEmpty else { return }
//        entries.insert(JournalEntry(text: trimmed), at: 0)
//        save()
//    }
//
//    func delete(at offsets: IndexSet) {
//        entries.remove(atOffsets: offsets)
//        save()
//    }
//
//    // MARK: - Persistence
//    func load() {
//        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
//        do {
//            let data = try Data(contentsOf: fileURL)
//            let decoded = try JSONDecoder().decode([JournalEntry].self, from: data)
//            self.entries = decoded.sorted { $0.createdAt > $1.createdAt }
//        } catch {
//            print("[Journal] Load error: \(error)")
//        }
//    }
//
//    func save() {
//        do {
//            let enc = JSONEncoder()
//            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
//            enc.dateEncodingStrategy = .iso8601
//            let data = try enc.encode(entries)
//            try data.write(to: fileURL, options: .atomic)
//        } catch {
//            print("[Journal] Save error: \(error)")
//        }
//    }
//}
//


import Foundation
import Combine
import SwiftUI

final class JournalStore: ObservableObject {

    // Namespaced model to avoid collisions with other files
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

    init() {
        load()
    }

    // MARK: - CRUD

    func add(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        entries.insert(Entry(text: trimmed), at: 0)
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
            print("[Journal] Load error: \(error)")
        }
    }

    private func save() {
        do {
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
            enc.dateEncodingStrategy = .iso8601
            let data = try enc.encode(entries)
            try data.write(to: fileURL, options: Data.WritingOptions.atomic)
        } catch {
            print("[Journal] Save error: \(error)")
        }
    }
}

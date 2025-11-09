//
//  JournalEntry.swift
//  SurvivorshipCareSwift
//
//  Created by Asteya Laxmanan on 11/8/25.
//


import Foundation

struct JournalEntry: Codable, Identifiable {
    let id = UUID()
    let createdAt = Date()
    var text: String
    var wordCount: Int { text.split { $0.isWhitespace || $0.isNewline }.count }
}

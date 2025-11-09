//
//  CognitiveSessionMeta.swift
//  SurvivorshipCareSwift
//
//  Created by Asteya Laxmanan on 11/8/25.
//


import Foundation

// MARK: - Common types

struct CognitiveSessionMeta: Codable {
    var startedAt: Date = Date()
    var endedAt: Date? = nil
    var durationSec: Int? {
        guard let end = endedAt else { return nil }
        return Int(end.timeIntervalSince(startedAt).rounded())
    }
}

// MARK: - Memory

struct MemoryMetrics: Codable {
    var mode: String           // "digits" | "words"
    var challenge: String      // "forward" | "backward"
    var sequence: [String]     // shown
    var expected: [String]     // expected order
    var response: [String]     // user entry
    var correct: Int
    var total: Int
    var accuracy: Double       // 0..1
    var omissions: Int
    var substitutions: Int
    var latencies: [Int]       // ms per entry
    var avgLatency: Int        // ms
}

func memoryScore(_ m: MemoryMetrics) -> Double {
    // Simple scale: accuracy is primary, latency small penalty
    // You can tune weights. Rough: 80% accuracy + 20% speed
    let acc = m.accuracy           // 0..1
    let rt = Double(m.avgLatency)  // ms
    let speed = max(0, 1.0 - (rt / 2500.0)) // ~2.5s avg -> zero
    let score = (acc * 0.8 + speed * 0.2) * 100.0
    return max(0, min(100, score))
}

// MARK: - Attention

struct AttentionMetrics: Codable {
    var mode: String            // "gonogo" | "nback"
    var total: Int              // 30
    // go/no-go:
    var targets: Int?           // number of targets (X)
    var goHits: Int?            // hits on targets
    // 1-back:
    var matches: Int?           // number of 1-back matches
    var correct: Int?           // correct responses on matches
    // both:
    var omissions: Int
    var commissions: Int
    var accuracy: Double        // 0..1
    var reactionTimes: [Int]    // ms
    var avgRt: Int              // ms
}

func attentionScore(_ a: AttentionMetrics) -> Double {
    let acc = a.accuracy
    let rt = Double(a.avgRt)
    // Similar to above: 75% accuracy + 25% speed
    let speed = max(0, 1.0 - (rt / 1200.0)) // ~1.2s RT -> zero
    let score = (acc * 0.75 + speed * 0.25) * 100.0
    return max(0, min(100, score))
}

// MARK: - Composite

struct CognitiveScores: Codable {
    var memory: Double
    var attention: Double
    var composite: Double
}

func compositeScore(memory: Double, attention: Double) -> Double {
    // even weighting
    let score = (memory + attention) / 2.0
    return max(0, min(100, score))
}

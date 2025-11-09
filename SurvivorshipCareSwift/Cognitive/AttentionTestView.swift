//
//  AttentionTestView.swift
//  SurvivorshipCareSwift
//
//  Created by Asteya Laxmanan on 11/8/25.
//


//import SwiftUI
//
//struct AttentionTestView: View {
//    let onComplete: (AttentionMetrics) -> Void
//
//    @State private var started = false
//    @State private var mode: String = (Bool.random() ? "gonogo" : "nback") // 50/50 like web
//    @State private var stream: [String] = []
//    @State private var index: Int = -1
//    @State private var progress: Double = 0
//    @State private var results: [(i:Int, type:String, rt:Int)] = []
//    @State private var onsetMs: Int = 0
//    @State private var reactedForIndex = Set<Int>()
//
//    // timing like web: ~900ms on + 300ms gap ≈ 1.2s per item
//    private let totalItems = 30
//    private let showMs = 0.9
//    private let isiMs = 0.3
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("Attention Test").font(.title2).fontWeight(.semibold)
//
//            if !started {
//                Group {
//                    if mode == "gonogo" {
//                        Text("Press when you see **X**. Ignore other letters.").foregroundStyle(.secondary)
//                    } else {
//                        Text("1-Back: Press when current letter matches the **previous** letter.").foregroundStyle(.secondary)
//                    }
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//
//                HStack(spacing: 12) {
//                    Button("Begin") {
//                        buildStream()
//                        started = true
//                        startTicker()
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .tint(Color.btAccent)
//                    Text("Mode: \(mode)").foregroundStyle(.secondary)
//                    Text("Items: \(totalItems)").foregroundStyle(.secondary)
//                }
//            }
//
//            if started {
//                ProgressBarView(progress: progress)
//                Text(stream[safe: index] ?? "…")
//                    .font(.system(size: 56, weight: .bold, design: .rounded))
//                    .frame(maxWidth: .infinity, alignment: .center)
//                    .padding(.vertical, 10)
//
//                Button(mode == "gonogo" ? "React to X" : "Match (1-back)") {
//                    react()
//                }
//                .buttonStyle(.bordered)
//                .frame(maxWidth: .infinity)
//            }
//        }
//        .padding()
//    }
//
//    // MARK: - logic
//
//    private func buildStream() {
//        if mode == "gonogo" {
//            // ≈65% targets 'X'
//            var arr: [String] = []
//            let letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ").map { String($0) }
//            for _ in 0..<totalItems {
//                if Double.random(in: 0...1) < 0.65 { arr.append("X") }
//                else { arr.append(letters.randomElement()!) }
//            }
//            stream = arr
//        } else {
//            // 1-back ~30% matches
//            let letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ").map { String($0) }
//            var out: [String] = []
//            for i in 0..<totalItems {
//                if i > 0 && Double.random(in: 0...1) < 0.30 { out.append(out[i-1]) }
//                else { out.append(letters.randomElement()!) }
//            }
//            stream = out
//        }
//    }
//
//    private func startTicker() {
//        index = -1; progress = 0; results = []; reactedForIndex.removeAll()
//        var step = -1
//        let total = stream.count
//        func tick() {
//            step += 1
//            if step >= total {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { finish() }
//                return
//            }
//            index = step
//            progress = Double(step + 1) / Double(max(1,total))
//            onsetMs = nowMs()
//            DispatchQueue.main.asyncAfter(deadline: .now() + showMs + isiMs) { tick() }
//        }
//        tick()
//    }
//
//    private func react() {
//        guard started, index >= 0, index < stream.count else { return }
//        if reactedForIndex.contains(index) { return }
//        reactedForIndex.insert(index)
//        let rt = nowMs() - onsetMs
//
//        if mode == "gonogo" {
//            let isTarget = stream[index] == "X"
//            results.append((i:index, type: isTarget ? "hit" : "commission", rt: rt))
//        } else {
//            let prev = index > 0 ? stream[index-1] : nil
//            let isMatch = prev != nil && stream[index] == prev
//            results.append((i:index, type: isMatch ? "correct" : "commission", rt: rt))
//        }
//    }
//
//    private func finish() {
//        if mode == "gonogo" {
//            var targets = 0, goHits = 0, commissions = 0
//            var rts: [Int] = []
//            for (i, ch) in stream.enumerated() { if ch == "X" { targets += 1 } }
//            results.forEach { r in
//                if r.type == "hit" { goHits += 1; rts.append(r.rt) }
//                if r.type == "commission" { commissions += 1 }
//            }
//            let omissions = max(0, targets - goHits)
//            let total = stream.count
//            let correct = goHits + (total - targets - commissions)
//            let accuracy = total > 0 ? Double(correct) / Double(total) : 0
//            let avgRt = rts.isEmpty ? 0 : Int(Double(rts.reduce(0,+)) / Double(rts.count))
//            onComplete(AttentionMetrics(
//                mode: mode, total: total, targets: targets, goHits: goHits,
//                matches: nil, correct: nil, omissions: omissions, commissions: commissions,
//                accuracy: accuracy, reactionTimes: rts, avgRt: avgRt
//            ))
//        } else {
//            var matches = 0, correct = 0, commissions = 0
//            var rts: [Int] = []
//            for i in 1..<stream.count { if stream[i] == stream[i-1] { matches += 1 } }
//            results.forEach { r in
//                if r.type == "correct" { correct += 1; rts.append(r.rt) }
//                if r.type == "commission" { commissions += 1 }
//            }
//            let omissions = max(0, matches - correct)
//            let total = stream.count - 1
//            let trueNegatives = max(0, total - matches - commissions)
//            let accNumerator = correct + trueNegatives
//            let accuracy = total > 0 ? Double(accNumerator) / Double(total) : 0
//            let avgRt = rts.isEmpty ? 0 : Int(Double(rts.reduce(0,+)) / Double(rts.count))
//            onComplete(AttentionMetrics(
//                mode: mode, total: total, targets: nil, goHits: nil,
//                matches: matches, correct: correct, omissions: omissions, commissions: commissions,
//                accuracy: accuracy, reactionTimes: rts, avgRt: avgRt
//            ))
//        }
//    }
//}
//
//fileprivate func nowMs() -> Int {
//    Int((Date().timeIntervalSince1970 * 1000).rounded())
//}
//
//fileprivate extension Array {
//    subscript(safe index: Int) -> Element? {
//        indices.contains(index) ? self[index] : nil
//    }
//}


import SwiftUI

struct AttentionTestView: View {
    let onComplete: (AttentionMetrics) -> Void

    @State private var started = false
    @State private var mode: String = (Bool.random() ? "gonogo" : "nback") // 50/50 like web
    @State private var stream: [String] = []
    @State private var index: Int = -1
    @State private var progress: Double = 0
    @State private var results: [(i:Int, type:String, rt:Int)] = []
    @State private var onsetMs: Int = 0
    @State private var reactedForIndex = Set<Int>()

    // timing like web: ~900ms on + 300ms gap ≈ 1.2s per item
    private let totalItems = 30
    private let showMs = 0.9
    private let isiMs = 0.3

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Heading
            Text("Attention Test")
                .font(.title2)
                .fontWeight(.semibold)

            // ✅ Clean intro: simple instruction + Begin button (no Mode/Items line)
            if !started {
                VStack(alignment: .leading, spacing: 14) {
                    if mode == "gonogo" {
                        Text("Press the button whenever you see the letter **X**. Ignore all other letters.")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("**1-Back:** Press the button when the current letter matches the **previous** letter.")
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        buildStream()
                        started = true
                        startTicker()
                    } label: {
                        Text("Begin")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.btAccent)
                    .padding(.top, 2)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                )
            }

            // Running state
            if started {
                ProgressBarView(progress: progress)

                Text(stream[safe: index] ?? "…")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)

                Button(mode == "gonogo" ? "React to X" : "Match (previous)") {
                    react()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }

    // MARK: - logic

    private func buildStream() {
        if mode == "gonogo" {
            // ≈65% targets 'X'
            var arr: [String] = []
            let letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ").map { String($0) }
            for _ in 0..<totalItems {
                if Double.random(in: 0...1) < 0.65 { arr.append("X") }
                else { arr.append(letters.randomElement()!) }
            }
            stream = arr
        } else {
            // 1-back ~30% matches
            let letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ").map { String($0) }
            var out: [String] = []
            for i in 0..<totalItems {
                if i > 0 && Double.random(in: 0...1) < 0.30 { out.append(out[i-1]) }
                else { out.append(letters.randomElement()!) }
            }
            stream = out
        }
    }

    private func startTicker() {
        index = -1; progress = 0; results = []; reactedForIndex.removeAll()
        var step = -1
        let total = stream.count
        func tick() {
            step += 1
            if step >= total {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { finish() }
                return
            }
            index = step
            progress = Double(step + 1) / Double(max(1,total))
            onsetMs = nowMs()
            DispatchQueue.main.asyncAfter(deadline: .now() + showMs + isiMs) { tick() }
        }
        tick()
    }

    private func react() {
        guard started, index >= 0, index < stream.count else { return }
        if reactedForIndex.contains(index) { return }
        reactedForIndex.insert(index)
        let rt = nowMs() - onsetMs

        if mode == "gonogo" {
            let isTarget = stream[index] == "X"
            results.append((i:index, type: isTarget ? "hit" : "commission", rt: rt))
        } else {
            let prev = index > 0 ? stream[index-1] : nil
            let isMatch = prev != nil && stream[index] == prev
            results.append((i:index, type: isMatch ? "correct" : "commission", rt: rt))
        }
    }

    private func finish() {
        if mode == "gonogo" {
            var targets = 0, goHits = 0, commissions = 0
            var rts: [Int] = []
            for ch in stream { if ch == "X" { targets += 1 } }
            results.forEach { r in
                if r.type == "hit" { goHits += 1; rts.append(r.rt) }
                if r.type == "commission" { commissions += 1 }
            }
            let omissions = max(0, targets - goHits)
            let total = stream.count
            let correct = goHits + (total - targets - commissions)
            let accuracy = total > 0 ? Double(correct) / Double(total) : 0
            let avgRt = rts.isEmpty ? 0 : Int(Double(rts.reduce(0,+)) / Double(rts.count))
            onComplete(AttentionMetrics(
                mode: mode, total: total, targets: targets, goHits: goHits,
                matches: nil, correct: nil, omissions: omissions, commissions: commissions,
                accuracy: accuracy, reactionTimes: rts, avgRt: avgRt
            ))
        } else {
            var matches = 0, correct = 0, commissions = 0
            var rts: [Int] = []
            for i in 1..<stream.count { if stream[i] == stream[i-1] { matches += 1 } }
            results.forEach { r in
                if r.type == "correct" { correct += 1; rts.append(r.rt) }
                if r.type == "commission" { commissions += 1 }
            }
            let omissions = max(0, matches - correct)
            let total = stream.count - 1
            let trueNegatives = max(0, total - matches - commissions)
            let accNumerator = correct + trueNegatives
            let accuracy = total > 0 ? Double(accNumerator) / Double(total) : 0
            let avgRt = rts.isEmpty ? 0 : Int(Double(rts.reduce(0,+)) / Double(rts.count))
            onComplete(AttentionMetrics(
                mode: mode, total: total, targets: nil, goHits: nil,
                matches: matches, correct: correct, omissions: omissions, commissions: commissions,
                accuracy: accuracy, reactionTimes: rts, avgRt: avgRt
            ))
        }
    }
}

// MARK: - helpers

fileprivate func nowMs() -> Int {
    Int((Date().timeIntervalSince1970 * 1000).rounded())
}

fileprivate extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

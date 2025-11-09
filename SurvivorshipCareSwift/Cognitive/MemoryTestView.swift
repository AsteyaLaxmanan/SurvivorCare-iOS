//
//  MemoryTestView.swift
//  SurvivorshipCareSwift
//
//  Created by Asteya Laxmanan on 11/8/25.
//


//import SwiftUI
//
//fileprivate func nowMs() -> Int { Int((Date().timeIntervalSince1970 * 1000).rounded()) }
//
//struct MemoryTestView: View {
//    // CONFIG (mirrors your web test: 5–7 items, words or digits, forward/backward) 
//    let seed: String
//    let onComplete: (MemoryMetrics) -> Void
//
//    @State private var started = false
//    @State private var phase: String = "show"     // show -> input -> done
//    @State private var items: [String] = []
//    @State private var mode: String = "words"     // "digits" | "words"
//    @State private var challenge: String = "forward"
//    @State private var index: Int = -1
//    @State private var progress: Double = 0
//    @State private var entered: [String] = []
//    @State private var inputValue: String = ""
//    @State private var latencies: [Int] = []
//    @State private var startEntryMs: Int = 0
//    @State private var displayMs: Int = 1500
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("Memory Test").font(.title2).fontWeight(.semibold)
//
//            if !started {
//                let subtitle = "You will see a sequence of \(mode == "words" ? "words" : "digits"). Memorize them in \(challenge) order."
//                Text(subtitle).foregroundStyle(.secondary)
//                HStack(spacing: 10) {
//                    Button("Begin") {
//                        configure()
//                        started = true
//                        startShowPhase()
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .tint(Color.btAccent)
//
//                    Text("Mode: \(mode)").foregroundStyle(.secondary)
//                    Text("Order: \(challenge)").foregroundStyle(.secondary)
//                    Text("Length: \(items.count)").foregroundStyle(.secondary)
//                }
//            }
//
//            if started && phase == "show" {
//                ProgressBarView(progress: progress)
//                Text(items[safe: index] ?? "…")
//                    .font(.system(size: 36, weight: .bold, design: .rounded))
//                    .frame(maxWidth: .infinity, alignment: .center)
//                    .padding(.vertical, 24)
//                Text("Memorize the sequence. Input starts shortly…")
//                    .font(.footnote).foregroundStyle(.secondary)
//                    .frame(maxWidth: .infinity, alignment: .center)
//            }
//
//            if started && phase == "input" {
//                HStack {
//                    Text("Enter items in \(challenge) order")
//                    Spacer()
//                    Text("\(entered.count) / \(expected.count)").foregroundStyle(.secondary)
//                }
//                HStack {
//                    TextField(mode == "digits" ? "Digit" : "Word", text: $inputValue)
//                        .textInputAutocapitalization(.never)
//                        .autocorrectionDisabled()
//                    Button("Add") { addToken() }
//                    Button("Undo") {
//                        if !entered.isEmpty {
//                            entered.removeLast()
//                            if !latencies.isEmpty { latencies.removeLast() }
//                        }
//                    }
//                    .disabled(entered.isEmpty)
//                    Button("Submit") { submit() }
//                        .disabled(entered.isEmpty)
//                        .buttonStyle(.borderedProminent)
//                        .tint(Color.btAccent)
//                }
//                FlowTokensView(tokens: entered)
//            }
//        }
//        .padding()
//    }
//
//    // MARK: - logic
//
//    private var expected: [String] {
//        var base = items
//        if challenge == "backward" { base.reverse() }
//        return base
//    }
//
//    private func configure() {
//        // Randomize like web: 50/50 words vs digits; length 5–7; 50/50 forward/backward; displayMs
//        let useWords = Bool.random()
//        let len = 5 + Int.random(in: 0...2)
//        let forward = Bool.random()
//        self.mode = useWords ? "words" : "digits"
//        self.challenge = forward ? "forward" : "backward"
//        self.displayMs = useWords ? (1500 + Int.random(in: 0...500)) : 1000
//        if useWords {
//            // a tiny fixed list (replace with your own)
//            let base = ["river","apple","sky","stone","green","music","light","water","leaf","cloud"].shuffled()
//            self.items = Array(base.prefix(len))
//        } else {
//            self.items = (0..<len).map { _ in String(Int.random(in: 0...9)) }
//        }
//    }
//
//    private func startShowPhase() {
//        phase = "show"
//        index = -1
//        progress = 0
//        var shown = 0
//        let total = items.count
//        Timer.scheduledTimer(withTimeInterval: TimeInterval(displayMs) / 1000.0, repeats: true) { timer in
//            shown += 1
//            index = shown - 1
//            progress = min(1.0, Double(shown) / Double(max(1,total)))
//            if shown >= total {
//                timer.invalidate()
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
//                    phase = "input"
//                    startEntryMs = nowMs()
//                }
//            }
//        }
//    }
//
//    private func addToken() {
//        let trimmed = inputValue.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmed.isEmpty else { return }
//        let t = nowMs() - startEntryMs
//        entered.append(trimmed)
//        latencies.append(t)
//        inputValue = ""
//    }
//
//    private func submit() {
//        let target = expected
//        let given = entered
//        let L = target.count
//        var correct = 0
//        var omissions = 0
//        var substitutions = 0
//        for i in 0..<L {
//            if i >= given.count { omissions += 1; continue }
//            if given[i].lowercased() == target[i].lowercased() { correct += 1 }
//            else { substitutions += 1 }
//        }
//        let accuracy = L == 0 ? 0 : Double(correct) / Double(L)
//        let avgLatency = latencies.isEmpty ? 0 : Int(Double(latencies.reduce(0,+)) / Double(latencies.count))
//        let metrics = MemoryMetrics(
//            mode: mode, challenge: challenge, sequence: items, expected: target,
//            response: given, correct: correct, total: L, accuracy: accuracy,
//            omissions: omissions, substitutions: substitutions,
//            latencies: latencies, avgLatency: avgLatency
//        )
//        onComplete(metrics)
//    }
//}
//
//// helper
//fileprivate struct FlowTokensView: View {
//    let tokens: [String]
//    var body: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack {
//                ForEach(Array(tokens.enumerated()), id: \.offset) { _, t in
//                    Text(t).padding(.horizontal, 10).padding(.vertical, 6)
//                        .background(Capsule().fill(.secondary.opacity(0.15)))
//                }
//            }
//        }
//    }
//}
//
//fileprivate extension Array {
//    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
//}

//
//  MemoryTestView.swift
//  SurvivorshipCareSwift
//
//  Created by Asteya Laxmanan on 11/8/25.
//

import SwiftUI

fileprivate func nowMs() -> Int { Int((Date().timeIntervalSince1970 * 1000).rounded()) }

struct MemoryTestView: View {
    // CONFIG (mirrors your web test: 5–7 items, words or digits, forward/backward)
    let seed: String
    let onComplete: (MemoryMetrics) -> Void

    // --- Planned config (decided once for intro copy AND actual run) ---
    @State private var plannedMode: String = (Bool.random() ? "words" : "digits")         // "words" | "digits"
    @State private var plannedChallenge: String = (Bool.random() ? "forward" : "backward")// "forward" | "backward"
    @State private var plannedLength: Int = 5 + Int.random(in: 0...2)

    // Runtime state
    @State private var started = false
    @State private var phase: String = "show"     // show -> input -> done
    @State private var items: [String] = []
    @State private var mode: String = "words"     // bound to plannedMode when starting
    @State private var challenge: String = "forward"
    @State private var index: Int = -1
    @State private var progress: Double = 0
    @State private var entered: [String] = []
    @State private var inputValue: String = ""
    @State private var latencies: [Int] = []
    @State private var startEntryMs: Int = 0
    @State private var displayMs: Int = 1500

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Heading
            Text("Memory Test")
                .font(.title2)
                .fontWeight(.semibold)

            // ✅ Clean intro: simple instruction + Begin button (uses planned config)
            if !started {
                VStack(alignment: .leading, spacing: 14) {
                    Text(introText)
                        .foregroundStyle(.secondary)

                    Button {
                        configureFromPlanned()
                        started = true
                        startShowPhase()
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

            // SHOW phase
            if started && phase == "show" {
                ProgressBarView(progress: progress)
                Text(items[safe: index] ?? "…")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                Text("Memorize the sequence. Input starts shortly…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            // INPUT phase
            if started && phase == "input" {
                HStack {
                    Text("Enter items in \(challenge) order")
                    Spacer()
                    Text("\(entered.count) / \(expected.count)")
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    TextField(mode == "digits" ? "Digit" : "Word", text: $inputValue)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(mode == "digits" ? .numberPad : .default)
                        .onChange(of: inputValue) { _, newVal in
                            guard mode == "digits" else { return }
                            let onlyDigits = newVal.filter(\.isNumber)
                            // keep at most 1 digit
                            inputValue = String(onlyDigits.prefix(1))
                        }
                    Button("Add") { addToken() }

                    Button("Undo") {
                        if !entered.isEmpty {
                            entered.removeLast()
                            if !latencies.isEmpty { latencies.removeLast() }
                        }
                    }
                    .disabled(entered.isEmpty)

                    Button("Submit") { submit() }
                        .disabled(entered.isEmpty)
                        .buttonStyle(.borderedProminent)
                        .tint(Color.btAccent)
                }

                FlowTokensView(tokens: entered)
            }
        }
        .padding()
    }

    // MARK: - derived text

    private var introText: String {
        let thing = (plannedMode == "words") ? "words" : "digits"
        let order = (plannedChallenge == "forward") ? "**same order**" : "**reverse order**"
        return "You’ll see a short list of \(thing). Try to remember them in the \(order). Tap **Begin** when you’re ready."
    }

    // MARK: - logic

    private var expected: [String] {
        var base = items
        if challenge == "backward" { base.reverse() }
        return base
    }

    private func configureFromPlanned() {
        // Bind runtime to planned config so intro and actual test match
        self.mode = plannedMode
        self.challenge = plannedChallenge
        let len = plannedLength

        // display timing
        self.displayMs = (mode == "words") ? (1500 + Int.random(in: 0...500)) : 1000

        if mode == "words" {
            let base = ["river","apple","sky","stone","green","music","light","water","leaf","cloud"].shuffled()
            self.items = Array(base.prefix(len))
        } else {
            self.items = (0..<len).map { _ in String(Int.random(in: 0...9)) }
        }
    }

    private func startShowPhase() {
        phase = "show"
        index = -1
        progress = 0
        var shown = 0
        let total = items.count
        Timer.scheduledTimer(withTimeInterval: TimeInterval(displayMs) / 1000.0, repeats: true) { timer in
            shown += 1
            index = shown - 1
            progress = min(1.0, Double(shown) / Double(max(1,total)))
            if shown >= total {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    phase = "input"
                    startEntryMs = nowMs()
                }
            }
        }
    }

    private func addToken() {
        var trimmed = inputValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if mode == "digits" {
            // Accept only a single digit
            guard trimmed.count == 1, trimmed.first?.isNumber == true else { return }
        } else {
            // For words, collapse internal spaces and keep a single token
            trimmed = trimmed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        }
        guard !trimmed.isEmpty else { return }

        let t = nowMs() - startEntryMs
        entered.append(trimmed)
        latencies.append(t)
        inputValue = ""
    }

    private func submit() {
        let target = expected
        let given = entered
        let L = target.count
        var correct = 0
        var omissions = 0
        var substitutions = 0
        for i in 0..<L {
            if i >= given.count { omissions += 1; continue }
            if given[i].lowercased() == target[i].lowercased() { correct += 1 }
            else { substitutions += 1 }
        }
        let accuracy = L == 0 ? 0 : Double(correct) / Double(L)
        let avgLatency = latencies.isEmpty ? 0 : Int(Double(latencies.reduce(0,+)) / Double(latencies.count))
        let metrics = MemoryMetrics(
            mode: mode, challenge: challenge, sequence: items, expected: target,
            response: given, correct: correct, total: L, accuracy: accuracy,
            omissions: omissions, substitutions: substitutions,
            latencies: latencies, avgLatency: avgLatency
        )
        onComplete(metrics)
    }
}

// helper
fileprivate struct FlowTokensView: View {
    let tokens: [String]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Array(tokens.enumerated()), id: \.offset) { _, t in
                    Text(t)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.secondary.opacity(0.15)))
                }
            }
        }
    }
}

fileprivate extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}

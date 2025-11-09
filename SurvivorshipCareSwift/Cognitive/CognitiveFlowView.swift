//
//  CognitiveFlowView.swift
//  SurvivorshipCareSwift
//
//  Created by Asteya Laxmanan on 11/8/25.
//


// CognitiveFlowView.swift
//import SwiftUI
//
//struct CognitiveFlowView: View {
//    /// Called when results are ready (still saves JSON).
//    let onDone: (_ memory: MemoryMetrics, _ attention: AttentionMetrics,
//                 _ scores: CognitiveScores, _ meta: CognitiveSessionMeta) -> Void
//    /// Called to immediately generate report (parent handles Ollama).
//    let onGenerate: (_ memory: MemoryMetrics, _ attention: AttentionMetrics,
//                     _ scores: CognitiveScores, _ meta: CognitiveSessionMeta) -> Void
//
//    @State private var phase: String = "intro"
//    @State private var memoryMetrics: MemoryMetrics?
//    @State private var attentionMetrics: AttentionMetrics?
//    @State private var scores: CognitiveScores?
//    @State private var meta = CognitiveSessionMeta()
//
//    var body: some View {
//        VStack(spacing: 16) {
//            StepChips(current: phase)
//
//            if phase == "intro" {
//                GroupBox {
//                    Text("Cognitive Assessment").font(.title2).fontWeight(.semibold)
//                    Text("Two short tasks: Memory → Attention")
//                        .foregroundStyle(.secondary)
//                    Button("Start Assessment") {
//                        meta.startedAt = Date()
//                        phase = "memory"
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .tint(.btAccent)
//                    .padding(.top, 8)
//                }
//            }
//
//            if phase == "memory" {
//                MemoryTestView(seed: UUID().uuidString) { m in
//                    memoryMetrics = m
//                    phase = "attention"
//                }
//            }
//
//            if phase == "attention" {
//                AttentionTestView { a in
//                    guard let m = memoryMetrics else { return }
//                    attentionMetrics = a
//                    let mem = memoryScore(m)
//                    let att = attentionScore(a)
//                    let comp = compositeScore(memory: mem, attention: att)
//                    scores = CognitiveScores(memory: mem, attention: att, composite: comp)
//                    meta.endedAt = Date()
//                    phase = "results"
//                }
//            }
//
//            if phase == "results",
//               let mem = memoryMetrics,
//               let att = attentionMetrics,
//               let s = scores {
//
//                GroupBox("Assessment Results") {
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Memory Score: \(Int(s.memory))")
//                        Text("Attention Score: \(Int(s.attention))")
//                        Text("Composite: \(Int(s.composite))")
//                        Divider()
//                        Text("Memory accuracy: \((mem.accuracy*100).rounded())% · Avg latency: \(mem.avgLatency) ms")
//                        Text("Attention accuracy: \((att.accuracy*100).rounded())% · Avg RT: \(att.avgRt) ms")
//                    }
//                }
//
//                // Primary CTA: Generate report NOW
//                Button {
//                    onDone(mem, att, s, meta)   // persist JSON
//                    onGenerate(mem, att, s, meta)
//                } label: {
//                    Text("Generate Report").bold().frame(maxWidth: .infinity)
//                }
//                .buttonStyle(.borderedProminent)
//                .tint(.btAccent)
//
//                // Secondary: just save & return
//                Button("Save & Return") {
//                    onDone(mem, att, s, meta)
//                }
//                .buttonStyle(.bordered)
//            }
//        }
//        .padding()
//        .navigationTitle("Cognitive Test")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//}
//
//// little step chips UI
//fileprivate struct StepChips: View {
//    let current: String
//    var body: some View {
//        HStack(spacing: 6) {
//            Chip("Intro", active: current == "intro")
//            Chip("Memory", active: current == "memory")
//            Chip("Attention", active: current == "attention")
//            Chip("Results", active: current == "results")
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//    }
//    struct Chip: View {
//        let label: String; let active: Bool
//        init(_ label: String, active: Bool) { self.label = label; self.active = active }
//        var body: some View {
//            Text(label)
//                .font(.footnote).bold(active)
//                .padding(.horizontal, 10).padding(.vertical, 6)
//                .background(Capsule().fill(active ? Color.btAccent.opacity(0.15)
//                                                  : Color.secondary.opacity(0.12)))
//        }
//    }
//}



import SwiftUI

struct CognitiveFlowView: View {
    // Callbacks you already use
    let onDone: (_ memory: MemoryMetrics, _ attention: AttentionMetrics,
                 _ scores: CognitiveScores, _ meta: CognitiveSessionMeta) -> Void
    let onGenerate: (_ memory: MemoryMetrics, _ attention: AttentionMetrics,
                     _ scores: CognitiveScores, _ meta: CognitiveSessionMeta) -> Void

    // New: to pop back after tapping Generate
    @Environment(\.dismiss) private var dismiss

    // Flow state (kept as String to avoid touching your other code)
    @State private var phase: String = "intro"
    @State private var memoryMetrics: MemoryMetrics?
    @State private var attentionMetrics: AttentionMetrics?
    @State private var scores: CognitiveScores?
    @State private var meta = CognitiveSessionMeta()

    // Order for header/progress
    private let phaseOrder = ["intro", "memory", "attention", "results"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // --- Step header (chips + progress) ---
                StepHeader(
                    titles: ["Intro", "Memory", "Attention", "Results"],
                    currentIndex: phaseOrder.firstIndex(of: phase) ?? 0
                )

                // --- Phase content in a card, pinned near the top ---
                Group {
                    if phase == "intro" {
                        IntroCard(
                            title: "Cognitive Assessment",
                            subtitle: "Two short tasks: Memory → Attention",
                            primaryTitle: "Start Assessment"
                        ) {
                            meta.startedAt = Date()
                            withAnimation(.spring()) { phase = "memory" }
                        }
                    }

                    if phase == "memory" {
                        MemoryTestView(seed: UUID().uuidString) { m in
                            memoryMetrics = m
                            withAnimation(.easeInOut) { phase = "attention" }
                        }
                    }

                    if phase == "attention" {
                        AttentionTestView { a in
                            guard let m = memoryMetrics else { return }
                            attentionMetrics = a
                            let mem = memoryScore(m)
                            let att = attentionScore(a)
                            let comp = compositeScore(memory: mem, attention: att)
                            scores = CognitiveScores(memory: mem, attention: att, composite: comp)
                            meta.endedAt = Date()
                            withAnimation(.easeInOut) { phase = "results" }
                        }
                    }

                    if phase == "results",
                       let mem = memoryMetrics,
                       let att = attentionMetrics,
                       let s = scores {

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Assessment Results")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)

                            VStack(alignment: .leading, spacing: 6) {
                                Label("Memory Score: \(Int(s.memory))", systemImage: "brain.head.profile")
                                Label("Attention Score: \(Int(s.attention))", systemImage: "bolt.badge.clock")
                                Label("Composite: \(Int(s.composite))", systemImage: "sum")
                            }
                            .font(.body)

                            Divider().padding(.vertical, 6)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Memory accuracy: \((mem.accuracy*100).rounded())% · Avg latency: \(mem.avgLatency) ms")
                                    .foregroundStyle(.secondary)
                                Text("Attention accuracy: \((att.accuracy*100).rounded())% · Avg RT: \(att.avgRt) ms")
                                    .foregroundStyle(.secondary)
                            }

                            // Primary CTA – Generate now and return
                            Button {
                                onDone(mem, att, s, meta)      // persist JSON
                                onGenerate(mem, att, s, meta)  // parent starts generation
                                // pop back to Daily Check-in
                                DispatchQueue.main.async { dismiss() }
                            } label: {
                                Text("Generate Report")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.btAccent)
                            .padding(.top, 8)

                            // Secondary – Save & return (no generation)
                            Button("Save & Return") {
                                onDone(mem, att, s, meta)
                                DispatchQueue.main.async { dismiss() }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .fullWidthCard()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .navigationTitle("Cognitive Test")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}

// --- StepHeader / StepTag / fullWidthCard / IntroCard unchanged ---

// MARK: - Header (chips + progress)
private struct StepHeader: View {
    let titles: [String]
    let currentIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ForEach(titles.indices, id: \.self) { i in
                    StepTag(label: titles[i], selected: i == currentIndex)
                }
            }

            GeometryReader { geo in
                let width = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15)).frame(height: 4)
                    Capsule().fill(Color.btAccent).frame(
                        width: width * CGFloat(max(1, currentIndex + 1)) / CGFloat(titles.count),
                        height: 4
                    )
                }
            }
            .frame(height: 4)
        }
    }
}

private struct StepTag: View {
    let label: String
    let selected: Bool
    var body: some View {
        Text(label)
            .font(.system(size: selected ? 14 : 12,
                          weight: selected ? .bold : .semibold,
                          design: .rounded))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(
                    selected ? Color.btAccent.opacity(0.20)
                             : Color.secondary.opacity(0.12)
                )
            )
            .overlay(
                Capsule().stroke(selected ? Color.btAccent : .clear, lineWidth: 1)
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: selected)
    }
}

// MARK: - Cards & Intro
private extension View {
    func fullWidthCard() -> some View {
        self
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
}

private struct IntroCard: View {
    let title: String
    let subtitle: String
    let primaryTitle: String
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)

            Text(subtitle)
                .foregroundStyle(.secondary)

            Button(action: onStart) {
                Text(primaryTitle)
                    .bold()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.btAccent)
            .padding(.top, 4)
        }
    }
}

//// ContentView.swift
//import SwiftUI
//
//struct ContentView: View {
//    // NEW: journal tab state lives inside the view
//    @StateObject private var journal = JournalStore()
//
//    private enum SubTab { case physical, cognitive, journal }
//    @State private var subTab: SubTab = .physical
//    private let healthStore = HealthStore()
//
//    @State private var stage: CheckInStage = .landing
//    @State private var statusMessage = "Tap Begin Daily Check-in to get started."
//    @State private var summary = HealthSummary()
//    @State private var savedFileURL: URL?
//
//    // ---- Ollama integration ----
//    @AppStorage("ollamaBaseURL") private var ollamaBaseURL: String = "http://172.20.10.3:11434" // your Mac IP
//    @AppStorage("ollamaModel")   private var ollamaModel: String   = "llama3"
//    @State private var reportText: String?
//    @State private var isGenerating = false
//    @State private var showReport = false
//
//    // ---- Cognitive results ----
//    @State private var memoryOut: MemoryMetrics?
//    @State private var attentionOut: AttentionMetrics?
//    @State private var cogScores: CognitiveScores?
//    @State private var cogFileURL: URL?
//
//    private let survivorshipPrompt = """
//    You are BioTwin, an intelligent healthcare companion specialized in cancer survivorship.
//    Goal: produce a thorough, descriptive, clinician-readable report that synthesizes physical, cognitive, and emotional data, highlighting notable patterns and potential signs while respecting privacy and avoiding diagnosis.
//
//    Audience: clinician. Style: clear, structured, professional, concise where appropriate. Use non-diagnostic language ("may be consistent with", "could indicate", "suggests").
//
//    Guiding principles:
//    - Privacy first (assume local runtime). No PII. Do not invent data.
//    - Transparency and precision: reference provided metrics and baselines.
//    - Empathy in tone is secondary; prioritize clinical clarity.
//    - Educational, not prescriptive. No medical orders or medication advice.
//    - When 'Reference snippets (RAG)' are provided, treat them as primary evidence (they may include DSM-5 criteria and survivorship literature). Ground observations and considerations in these snippets. Use concise bracket citations that match snippet indices (e.g., [1], [2]) where relevant.
//    - Journal entries (if any) summarize daily mood/affect, themes, and stressors. Extract patterns and sentiment trends without quoting sensitive content verbatim.
//
//    Your analysis should:
//    - Summarize overall state (physical, cognitive, emotional).
//    - Identify patterns/deviations vs baseline (fatigue, sleep decline, cognitive dip, sentiment shifts).
//    - Call out potential signs/risk considerations (non-diagnostic), especially when multiple domains align.
//    - Provide brief, practical self-care guidance suitable for survivorship.
//    - Assign qualitative risk: green (stable), amber (mild decline), red (notable concern).
//    """
//
//    var body: some View {
//        NavigationStack {
//            if stage == .landing {
//                ParallaxHeaderScroll(headerHeight: 320) {
//                    // --- Hero header ---
//                    ZStack {
//                        LinearGradient(
//                            colors: [Color.btAccent.opacity(0.9), Color.btAccent.opacity(0.5)],
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
//                        VStack(spacing: 10) {
//                            Text("BioTwin").btTitle().foregroundStyle(.white)
//                            Text("Personalized daily check-ins powered by HealthKit.")
//                                .multilineTextAlignment(.center)
//                                .foregroundStyle(.white.opacity(0.9))
//                                .padding(.horizontal)
//                        }
//                        .padding(.top, 8)
//                    }
//                } content: {
//                    // --- Landing content ---
//                    VStack(spacing: 22) {
//                        Button {
//                            beginCheckInTapped()
//                        } label: {
//                            HStack(spacing: 10) {
//                                IconSymbol(name: "waveform.path.ecg", size: 20, color: .white)
//                                Text("Begin Daily Check-in").bold()
//                            }
//                            .frame(maxWidth: .infinity)
//                            .padding(.vertical, 16)
//                        }
//                        .buttonStyle(.borderedProminent)
//                        .tint(Color.btAccent)
//                        .padding(.top, 12)
//                        .contentShape(Rectangle())
//                        .disabled(stage != .landing)
//
//                        Collapsible {
//                            HStack(spacing: 8) {
//                                IconSymbol(name: "questionmark.circle.fill", size: 18, color: .btAccent)
//                                Text("What gets collected?").btSubtitle()
//                            }
//                        } content: {
//                            Text("Steps, distance, active/basal energy, flights, exercise minutes, and latest heart rate. Data is saved locally as JSON for your report.")
//                                .foregroundStyle(Color.btMuted)
//                                .font(.subheadline)
//                        }
//
//                        Text(statusMessage)
//                            .font(.footnote)
//                            .foregroundStyle(Color.btMuted)
//                            .padding(.top, 4)
//
//                        // Ollama quick settings row
//                        HStack {
//                            Text("Ollama: ").font(.footnote).foregroundStyle(Color.btMuted)
//                            Text(ollamaModel).font(.footnote).foregroundStyle(Color.btAccent)
//                            Text("@ ").font(.footnote).foregroundStyle(Color.btMuted)
//                            Text(ollamaBaseURL).font(.footnote).foregroundStyle(Color.btAccent)
//                            Spacer()
//                            NavigationLink("Edit") {
//                                OllamaSettingsView(ollamaBaseURL: $ollamaBaseURL, ollamaModel: $ollamaModel)
//                            }
//                        }
//                        .font(.footnote)
//                        .padding(.top, 4)
//                    }
//                }
//                .toolbar(.hidden, for: .navigationBar)
//                .sheet(isPresented: $showReport) {
//                    if let reportText {
//                        NavigationStack { ReportView(text: reportText) }
//                    }
//                }
//            } else {
//                // --- Check-in flow screens ---
//                ScrollView {
//                    VStack(spacing: 24) {
//                        statusHeader
//
//                        if stage == .authorizing || stage == .loading {
//                            ProgressView()
//                                .progressViewStyle(.circular)
//                                .scaleEffect(1.3)
//                                .padding(.top, 12)
//                        }
//
//                        if stage == .complete {
//                            // --- sub-tabs header ---
//                            VStack(spacing: 8) {
//                                HStack(spacing: 6) {
//                                    Tag("Physical", active: subTab == .physical)
//                                        .onTapGesture { subTab = .physical }
//                                    Tag("Journal", active: subTab == .journal)
//                                        .onTapGesture { subTab = .journal }
//                                }
//                                .frame(maxWidth: .infinity, alignment: .leading)
//
//                                // underline cue
//                                Rectangle()
//                                    .fill(Color.btAccent.opacity(0.6))
//                                    .frame(height: 3)
//                                    .frame(maxWidth: subTab == .physical ? 80 : 70, alignment: .leading)
//                                    .animation(.easeInOut(duration: 0.2), value: subTab)
//                            }
//
//                            // --- tab content ---
//                            if subTab == .physical {
//                                // Physical summary + CTAs
//                                summarySection
//
//                                if let savedFileURL {
//                                    // Proceed to Cognitive Test
//                                    NavigationLink("Proceed to Cognitive Test") {
//                                        CognitiveFlowView { mem, att, scores, meta in
//                                            // onDone: persist results
//                                            self.memoryOut = mem
//                                            self.attentionOut = att
//                                            self.cogScores  = scores
//                                            self.cogFileURL = persistCognitive(mem: mem, att: att, scores: scores, meta: meta)
//                                        } onGenerate: { mem, att, scores, meta in
//                                            // persist, then auto-generate report
//                                            self.memoryOut = mem
//                                            self.attentionOut = att
//                                            self.cogScores  = scores
//                                            self.cogFileURL = persistCognitive(mem: mem, att: att, scores: scores, meta: meta)
//                                            Task { await generateAndOpenReport() }
//                                        }
//                                    }
//                                    .buttonStyle(.borderedProminent)
//                                    .tint(Color.btAccent)
//
//                                    // Cognitive JSON info, if any
//                                    if let cogFileURL {
//                                        VStack(alignment: .leading, spacing: 6) {
//                                            Text("Cognitive results saved").font(.headline)
//                                            Text(cogFileURL.lastPathComponent).foregroundStyle(.secondary)
//                                            ShareLink("Share Cognitive JSON", item: cogFileURL)
//                                        }
//                                        .frame(maxWidth: .infinity, alignment: .leading)
//                                    }
//
//                                    // Generate combined report
//                                    Button {
//                                        Task { await generateWithOllama(using: savedFileURL) }
//                                    } label: {
//                                        HStack {
//                                            if isGenerating { ProgressView().padding(.trailing, 6) }
//                                            Text(isGenerating ? "Generating…" : "Generate Report").bold()
//                                        }
//                                        .frame(maxWidth: .infinity)
//                                    }
//                                    .buttonStyle(.borderedProminent)
//                                    .tint(Color.btAccent)
//                                    .disabled(isGenerating)
//
//                                    if let reportText {
//                                        NavigationLink("View Report") { ReportView(text: reportText) }
//                                            .buttonStyle(.bordered)
//                                    }
//                                }
//                            } else {
//                                // Journal tab content
//                                JournalView(store: journal)
//                            }
//                        } else if stage == .error {
//                            Button("Try Again", action: resetToLanding)
//                                .buttonStyle(.borderedProminent)
//                                .tint(.btAccent)
//                        } else {
//                            Button("Cancel", action: resetToLanding)
//                                .buttonStyle(.bordered)
//                        }
//                    }
//                    .padding()
//                    .animation(.easeInOut, value: stage)
//                }
//                .navigationTitle("Daily Check-in")
//                .navigationBarTitleDisplayMode(.inline)
//            }
//        }
//    }
//
//    // MARK: - Sections
//
//    private var statusHeader: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack(spacing: 8) {
//                IconSymbol(name: "heart.fill", size: 20, color: .btAccent)
//                Text("Daily Check-in").font(.title2).fontWeight(.semibold)
//            }
//            Text(statusMessage)
//                .foregroundStyle(stage == .error ? Color.red : .btMuted)
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//    }
//
//    private var summarySection: some View {
//        VStack(spacing: 16) {
//            GroupBox("Activity") {
//                MetricRow(label: "Steps Today", value: format(summary.steps, suffix: ""))
//                MetricRow(label: "Walking + Running Distance",
//                          value: summary.distanceKm > 0 ? String(format: "%.2f km", summary.distanceKm) : "—")
//                MetricRow(label: "Active Energy",
//                          value: summary.activeKcal > 0 ? String(format: "%.0f kcal", summary.activeKcal) : "—")
//                MetricRow(label: "Basal Energy",
//                          value: summary.basalKcal > 0 ? String(format: "%.0f kcal", summary.basalKcal) : "—")
//                MetricRow(label: "Flights Climbed", value: format(summary.flights, suffix: ""))
//                MetricRow(label: "Exercise Minutes", value: format(summary.exerciseMinutes, suffix: ""))
//            }
//            GroupBox("Cardio") {
//                MetricRow(label: "Latest HR",
//                          value: summary.heartRate.isNaN ? "—" : String(format: "%.0f bpm", summary.heartRate))
//            }
//        }
//    }
//
//    private func savedFileInfo(url: URL) -> some View {
//        VStack(alignment: .leading, spacing: 6) {
//            Text("Check-in saved").font(.headline)
//            Text(url.lastPathComponent).font(.subheadline).foregroundStyle(Color.btMuted)
//            Text("Find it under Files ▸ On My iPhone ▸ BioTwin (or share from here).")
//                .font(.footnote).foregroundStyle(Color.btMuted)
//            ShareLink("Share JSON", item: url)
//                .buttonStyle(.bordered)
//                .tint(.btAccent)
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//    }
//
//    // MARK: - Flow
//
//    @MainActor
//    private func beginCheckInTapped() {
//        print("[BioTwin] Begin tapped")
//        statusMessage = "Starting check-in…"
//        // Watchdog hint if the Health permission sheet never appears/returns
//        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
//            if stage == .landing || stage == .authorizing {
//                statusMessage = "Still waiting on Health permissions… If you didn’t see a sheet, check Settings ▸ Health ▸ Apps ▸ BioTwin."
//            }
//        }
//        startCheckIn()
//    }
//
//    private func startCheckIn() {
//        print("[BioTwin] >>> ENTER startCheckIn")
//        savedFileURL = nil
//        statusMessage = "Requesting Health permissions…"
//        stage = .authorizing
//        print("[BioTwin] Requesting HealthKit authorization…)")
//
//        healthStore.requestAuthorization { result in
//            switch result {
//            case .success:
//                print("[BioTwin] HealthKit auth SUCCESS")
//                statusMessage = "Permissions granted. Gathering today's metrics…"
//                fetchAndPersistSummary()
//            case .failure(let error):
//                print("[BioTwin] HealthKit auth FAILED: \(error.localizedDescription)")
//                statusMessage = "Permission error: \(error.localizedDescription)"
//                stage = .error
//            }
//        }
//    }
//
//    private func fetchAndPersistSummary() {
//        print("[BioTwin] >>> ENTER fetchAndPersistSummary")
//        stage = .loading
//        healthStore.fetchTodaySummary { summary in
//            print("[BioTwin] Summary fetched: steps=\(summary.steps), hr=\(summary.heartRate)")
//            self.summary = summary
//            do {
//                let url = try self.healthStore.persist(summary: summary)
//                self.savedFileURL = url
//                self.statusMessage = "Daily check-in saved to \(url.lastPathComponent)."
//                self.stage = .complete
//                print("[BioTwin] JSON saved at \(url.path)")
//            } catch {
//                self.statusMessage = "Failed to save check-in: \(error.localizedDescription)"
//                self.stage = .error
//                print("[BioTwin] Save failed: \(error.localizedDescription)")
//            }
//        }
//    }
//
//    private func resetToLanding() {
//        stage = .landing
//        statusMessage = "Tap Begin Daily Check-in to get started."
//        savedFileURL = nil
//        reportText = nil
//        isGenerating = false
//        memoryOut = nil
//        attentionOut = nil
//        cogScores = nil
//        cogFileURL = nil
//    }
//
//    // MARK: - Ollama
//
//    /// Combines Health JSON + Cognitive JSON (if available) into one file and sends that.
//    private func generateWithOllama(using healthURL: URL) async {
//        isGenerating = true
//        defer { isGenerating = false }
//        do {
//            guard let base = URL(string: ollamaBaseURL) else {
//                statusMessage = "Invalid Ollama URL in Settings."; return
//            }
//
//            // Build a combined JSON object
//            let healthData = try Data(contentsOf: healthURL)
//            let healthObj = try JSONSerialization.jsonObject(with: healthData) as? [String: Any] ?? [:]
//
//            var combined: [String: Any] = ["health": healthObj]
//
//            if let mem = memoryOut, let att = attentionOut, let scores = cogScores {
//                let enc = JSONEncoder()
//                enc.dateEncodingStrategy = .iso8601
//                enc.outputFormatting = .prettyPrinted
//                let memObj = try JSONSerialization.jsonObject(with: enc.encode(mem))
//                let attObj = try JSONSerialization.jsonObject(with: enc.encode(att))
//                let scObj  = try JSONSerialization.jsonObject(with: enc.encode(scores))
//                combined["cognitive"] = ["memory": memObj, "attention": attObj, "scores": scObj]
//            }
//
//            // Write combined to a temp file
//            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//            let comboURL = docs.appendingPathComponent("combined-checkin-\(Int(Date().timeIntervalSince1970)).json")
//            let combinedData = try JSONSerialization.data(withJSONObject: combined, options: [.prettyPrinted, .sortedKeys])
//            try combinedData.write(to: comboURL, options: .atomic)
//
//            let client = OllamaClient(config: .init(baseURL: base, model: ollamaModel))
//            statusMessage = "Contacting Ollama…"
//            let text = try await client.generateReport(for: comboURL, systemPrompt: survivorshipPrompt)
//            self.reportText = text
//            statusMessage = "Report ready."
//            self.showReport = true
//        } catch {
//            statusMessage = "Ollama error: \(error.localizedDescription)"
//        }
//    }
//    
//    private func generateAndOpenReport() async {
//        guard let url = savedFileURL else { return }
//        await generateWithOllama(using: url)
//        await MainActor.run { showReport = true }   // optional: auto-open the report sheet
//    }
//
//
//    // MARK: - Helpers
//
//    private func persistCognitive(mem: MemoryMetrics, att: AttentionMetrics, scores: CognitiveScores, meta: CognitiveSessionMeta) -> URL? {
//        struct CogPayload: Codable {
//            let id = UUID()
//            let createdAt = Date()
//            let memory: MemoryMetrics
//            let attention: AttentionMetrics
//            let scores: CognitiveScores
//            let meta: CognitiveSessionMeta
//        }
//        do {
//            let payload = CogPayload(memory: mem, attention: att, scores: scores, meta: meta)
//            let enc = JSONEncoder()
//            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
//            enc.dateEncodingStrategy = .iso8601
//            let data = try enc.encode(payload)
//            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//            let url = docs.appendingPathComponent("cognitive-\(Int(Date().timeIntervalSince1970)).json")
//            try data.write(to: url, options: .atomic)
//            return url
//        } catch {
//            statusMessage = "Failed to save cognitive results: \(error.localizedDescription)"
//            return nil
//        }
//    }
//
//    private func format(_ value: Double, suffix: String) -> String {
//        guard value > 0 else { return "—" }
//        return String(format: "%.0f%@", value, suffix)
//    }
//
//    private enum CheckInStage { case landing, authorizing, loading, complete, error }
//}
//
//// Simple metric row
//struct MetricRow: View {
//    let label: String
//    let value: String
//    var body: some View {
//        HStack {
//            Text(label)
//            Spacer()
//            Text(value).font(.system(.body, design: .monospaced))
//        }
//    }
//}
//
//struct Tag: View {
//    let label: String
//    let active: Bool
//
//    init(_ label: String, active: Bool) {
//        self.label = label
//        self.active = active
//    }
//
//    var body: some View {
//        Text(label)
//            .font(.system(size: active ? 15 : 12,
//                          weight: active ? .bold : .regular,
//                          design: .rounded))
//            .padding(.horizontal, 10)
//            .padding(.vertical, 6)
//            .background(
//                Capsule().fill(
//                    active
//                    ? Color.btAccent.opacity(0.15)
//                    : Color.secondary.opacity(0.12)
//                )
//            )
//            .scaleEffect(active ? 1.06 : 1.0)
//            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: active)
//    }
//}

// ContentView.swift
import SwiftUI

struct ContentView: View {
    // Journal state lives here
    @StateObject private var journal = JournalStore()

    private enum SubTab { case physical, cognitive, journal }
    @State private var subTab: SubTab = .physical

    private let healthStore = HealthStore()

    @State private var stage: CheckInStage = .landing
    @State private var statusMessage = "Tap Begin Daily Check-in to get started."
    @State private var summary = HealthSummary()
    @State private var savedFileURL: URL?

    // ---- Ollama integration ----
    @AppStorage("ollamaBaseURL") private var ollamaBaseURL: String = "http://172.20.10.3:11434"
    @AppStorage("ollamaModel")   private var ollamaModel: String   = "llama3"
    @State private var reportText: String?
    @State private var isGenerating = false
    @State private var showReport = false

    // ---- Cognitive results ----
    @State private var memoryOut: MemoryMetrics?
    @State private var attentionOut: AttentionMetrics?
    @State private var cogScores: CognitiveScores?
    @State private var cogFileURL: URL?

    private let survivorshipPrompt = """
    You are BioTwin, an intelligent healthcare companion specialized in cancer survivorship.
    Goal: produce a thorough, descriptive, clinician-readable report that synthesizes physical, cognitive, and emotional data, highlighting notable patterns and potential signs while respecting privacy and avoiding diagnosis.

    Audience: clinician. Style: clear, structured, professional, concise where appropriate. Use non-diagnostic language ("may be consistent with", "could indicate", "suggests").

    Guiding principles:
    - Privacy first (assume local runtime). No PII. Do not invent data.
    - Transparency and precision: reference provided metrics and baselines.
    - Empathy in tone is secondary; prioritize clinical clarity.
    - Educational, not prescriptive. No medical orders or medication advice.
    - When 'Reference snippets (RAG)' are provided, treat them as primary evidence (they may include DSM-5 criteria and survivorship literature). Ground observations and considerations in these snippets. Use concise bracket citations that match snippet indices (e.g., [1], [2]) where relevant.
    - Journal entries (if any) summarize daily mood/affect, themes, and stressors. Extract patterns and sentiment trends without quoting sensitive content verbatim.

    Your analysis should:
    - Summarize overall state (physical, cognitive, emotional).
    - Identify patterns/deviations vs baseline (fatigue, sleep decline, cognitive dip, sentiment shifts).
    - Call out potential signs/risk considerations (non-diagnostic), especially when multiple domains align.
    - Provide brief, practical self-care guidance suitable for survivorship.
    - Assign qualitative risk: green (stable), amber (mild decline), red (notable concern).
    """

    var body: some View {
        NavigationStack {
            if stage == .landing {
                ParallaxHeaderScroll(headerHeight: 320) {
                    // --- Hero header ---
                    ZStack {
                        LinearGradient(
                            colors: [Color.btAccent.opacity(0.9), Color.btAccent.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        VStack(spacing: 10) {
                            Text("BioTwin").btTitle().foregroundStyle(.white)
                            Text("Personalized daily check-ins powered by HealthKit.")
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal)
                        }
                        .padding(.top, 8)
                    }
                } content: {
                    // --- Landing content ---
                    VStack(spacing: 22) {
                        Button {
                            beginCheckInTapped()
                        } label: {
                            HStack(spacing: 10) {
                                IconSymbol(name: "waveform.path.ecg", size: 20, color: .white)
                                Text("Begin Daily Check-in").bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.btAccent)
                        .padding(.top, 12)
                        .contentShape(Rectangle())
                        .disabled(stage != .landing)

                        Collapsible {
                            HStack(spacing: 8) {
                                IconSymbol(name: "questionmark.circle.fill", size: 18, color: .btAccent)
                                Text("What gets collected?").btSubtitle()
                            }
                        } content: {
                            Text("Steps, distance, active/basal energy, flights, exercise minutes, and latest heart rate. Data is saved locally as JSON for your report.")
                                .foregroundStyle(Color.btMuted)
                                .font(.subheadline)
                        }

                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(Color.btMuted)
                            .padding(.top, 4)

                        // Ollama quick settings row
                        HStack {
                            Text("Ollama: ").font(.footnote).foregroundStyle(Color.btMuted)
                            Text(ollamaModel).font(.footnote).foregroundStyle(Color.btAccent)
                            Text("@ ").font(.footnote).foregroundStyle(Color.btMuted)
                            Text(ollamaBaseURL).font(.footnote).foregroundStyle(Color.btAccent)
                            Spacer()
                            NavigationLink("Edit") {
                                OllamaSettingsView(ollamaBaseURL: $ollamaBaseURL, ollamaModel: $ollamaModel)
                            }
                        }
                        .font(.footnote)
                        .padding(.top, 4)
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $showReport) {
                    if let reportText {
                        NavigationStack { FancyReportView(text: reportText) }
                    }
                }

            } else {
                // --- Check-in flow screens ---
                ScrollView {
                    VStack(spacing: 24) {
                        statusHeader

                        if stage == .authorizing || stage == .loading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(1.3)
                                .padding(.top, 12)
                        }

                        if stage == .complete {
                            // --- sub-tabs header ---
                            VStack(spacing: 10) {
                                HStack(spacing: 8) {
                                    Tag("Physical",  active: subTab == .physical)
                                        .onTapGesture { subTab = .physical }
                                    Tag("Cognitive", active: subTab == .cognitive)
                                        .onTapGesture { subTab = .cognitive }
                                    Tag("Journal",   active: subTab == .journal)
                                        .onTapGesture { subTab = .journal }
                                    Spacer()
                                }
                                Divider().padding(.top, 2) // keeps the chips visually anchored
                            }

                            // --- tab content ---
                            Group {
                                switch subTab {
                                case .physical:
                                    // Physical summary
                                    summarySection

                                    if let savedFileURL {
                                        // (Removed the "Proceed to Cognitive Test" button)

                                        // Cognitive JSON info, if any
                                        if let cogFileURL {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text("Cognitive results saved").font(.headline)
                                                Text(cogFileURL.lastPathComponent).foregroundStyle(.secondary)
                                                ShareLink("Share Cognitive JSON", item: cogFileURL)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }

                                        // Generate combined report — centered pill
                                        HStack {
                                            Spacer()
                                            Button {
                                                Task { await generateWithOllama(using: savedFileURL) }
                                            } label: {
                                                HStack(spacing: 10) {
                                                    if isGenerating { ProgressView() }
                                                    Text(isGenerating ? "Generating…" : "Generate Report")
                                                }
                                            }
                                            .buttonStyle(PillButtonStyle())
                                            .disabled(isGenerating)
                                            Spacer()
                                        }
                                        .padding(.top, 4)

                                        // View report
                                        if let reportText {
                                            NavigationLink("View Report") {
                                                FancyReportView(text: reportText)
                                            }
                                            .buttonStyle(.bordered) // nice secondary look
                                        }
                                    }
                                case .cognitive:
                                    CognitiveStartView {
                                        // onStart: nothing extra needed; the view below pushes itself
                                    } content: {
                                        CognitiveFlowView { mem, att, scores, meta in
                                            self.memoryOut = mem
                                            self.attentionOut = att
                                            self.cogScores  = scores
                                            self.cogFileURL = persistCognitive(mem: mem, att: att, scores: scores, meta: meta)
                                        } onGenerate: { mem, att, scores, meta in
                                            self.memoryOut = mem
                                            self.attentionOut = att
                                            self.cogScores  = scores
                                            self.cogFileURL = persistCognitive(mem: mem, att: att, scores: scores, meta: meta)
                                            Task { await generateAndOpenReport() }
                                        }
                                    }

                                case .journal:
                                    JournalView(store: journal)
                                }
                            }
                            .animation(.easeInOut, value: subTab)

                        } else if stage == .error {
                            Button("Try Again", action: resetToLanding)
                                .buttonStyle(.borderedProminent)
                                .tint(.btAccent)
                        } else {
                            Button("Cancel", action: resetToLanding)
                                .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .animation(.easeInOut, value: stage)
                }
                .navigationTitle("Daily Check-in")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    // MARK: - Sections

    private var statusHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                IconSymbol(name: "heart.fill", size: 20, color: .btAccent)
                Text("Daily Check-in").font(.title2).fontWeight(.semibold)
            }
            Text(statusMessage)
                .foregroundStyle(stage == .error ? Color.red : .btMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var summarySection: some View {
        VStack(spacing: 16) {
            GroupBox("Activity") {
                MetricRow(label: "Steps Today", value: format(summary.steps, suffix: ""))
                MetricRow(label: "Walking + Running Distance",
                          value: summary.distanceKm > 0 ? String(format: "%.2f km", summary.distanceKm) : "—")
                MetricRow(label: "Active Energy",
                          value: summary.activeKcal > 0 ? String(format: "%.0f kcal", summary.activeKcal) : "—")
                MetricRow(label: "Basal Energy",
                          value: summary.basalKcal > 0 ? String(format: "%.0f kcal", summary.basalKcal) : "—")
                MetricRow(label: "Flights Climbed", value: format(summary.flights, suffix: ""))
                MetricRow(label: "Exercise Minutes", value: format(summary.exerciseMinutes, suffix: ""))
            }
            GroupBox("Cardio") {
                MetricRow(label: "Latest HR",
                          value: summary.heartRate.isNaN ? "—" : String(format: "%.0f bpm", summary.heartRate))
            }
        }
    }

    // MARK: - Flow

    @MainActor
    private func beginCheckInTapped() {
        statusMessage = "Starting check-in…"
        // Watchdog hint if the Health permission sheet never appears/returns
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if stage == .landing || stage == .authorizing {
                statusMessage = "Still waiting on Health permissions… If you didn’t see a sheet, check Settings ▸ Health ▸ Apps ▸ BioTwin."
            }
        }
        startCheckIn()
    }

    private func startCheckIn() {
        savedFileURL = nil
        statusMessage = "Requesting Health permissions…"
        stage = .authorizing

        healthStore.requestAuthorization { result in
            switch result {
            case .success:
                statusMessage = "Permissions granted. Gathering today's metrics…"
                fetchAndPersistSummary()
            case .failure(let error):
                statusMessage = "Permission error: \(error.localizedDescription)"
                stage = .error
            }
        }
    }

    private func fetchAndPersistSummary() {
        stage = .loading
        healthStore.fetchTodaySummary { summary in
            self.summary = summary
            do {
                let url = try self.healthStore.persist(summary: summary)
                self.savedFileURL = url
                self.statusMessage = "Daily check-in saved to \(url.lastPathComponent)."
                self.stage = .complete
            } catch {
                self.statusMessage = "Failed to save check-in: \(error.localizedDescription)"
                self.stage = .error
            }
        }
    }

    private func resetToLanding() {
        stage = .landing
        statusMessage = "Tap Begin Daily Check-in to get started."
        savedFileURL = nil
        reportText = nil
        isGenerating = false
        memoryOut = nil
        attentionOut = nil
        cogScores = nil
        cogFileURL = nil
    }

    // MARK: - Ollama

    /// Combines Health JSON + Cognitive JSON (if available) into one file and sends that.
    private func generateWithOllama(using healthURL: URL) async {
        isGenerating = true
        defer { isGenerating = false }
        do {
            guard let base = URL(string: ollamaBaseURL) else {
                statusMessage = "Invalid Ollama URL in Settings."; return
            }

            // Build a combined JSON object
            let healthData = try Data(contentsOf: healthURL)
            let healthObj = try JSONSerialization.jsonObject(with: healthData) as? [String: Any] ?? [:]

            var combined: [String: Any] = ["health": healthObj]

            if let mem = memoryOut, let att = attentionOut, let scores = cogScores {
                let enc = JSONEncoder()
                enc.dateEncodingStrategy = .iso8601
                enc.outputFormatting = .prettyPrinted
                let memObj = try JSONSerialization.jsonObject(with: enc.encode(mem))
                let attObj = try JSONSerialization.jsonObject(with: enc.encode(att))
                let scObj  = try JSONSerialization.jsonObject(with: enc.encode(scores))
                combined["cognitive"] = ["memory": memObj, "attention": attObj, "scores": scObj]
            }

            // Write combined to a temp file
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let comboURL = docs.appendingPathComponent("combined-checkin-\(Int(Date().timeIntervalSince1970)).json")
            let combinedData = try JSONSerialization.data(withJSONObject: combined, options: [.prettyPrinted, .sortedKeys])
            try combinedData.write(to: comboURL, options: .atomic)

            let client = OllamaClient(config: .init(baseURL: base, model: ollamaModel))
            statusMessage = "Contacting Ollama…"
            let text = try await client.generateReport(for: comboURL, systemPrompt: survivorshipPrompt)
            self.reportText = text
            statusMessage = "Report ready."
            self.showReport = true
        } catch {
            statusMessage = "Ollama error: \(error.localizedDescription)"
        }
    }

    private func generateAndOpenReport() async {
        guard let url = savedFileURL else { return }
        await generateWithOllama(using: url)
        await MainActor.run { showReport = true }
    }

    // MARK: - Helpers

    private func persistCognitive(mem: MemoryMetrics, att: AttentionMetrics, scores: CognitiveScores, meta: CognitiveSessionMeta) -> URL? {
        struct CogPayload: Codable {
            let id = UUID()
            let createdAt = Date()
            let memory: MemoryMetrics
            let attention: AttentionMetrics
            let scores: CognitiveScores
            let meta: CognitiveSessionMeta
        }
        do {
            let payload = CogPayload(memory: mem, attention: att, scores: scores, meta: meta)
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
            enc.dateEncodingStrategy = .iso8601
            let data = try enc.encode(payload)
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let url = docs.appendingPathComponent("cognitive-\(Int(Date().timeIntervalSince1970)).json")
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            statusMessage = "Failed to save cognitive results: \(error.localizedDescription)"
            return nil
        }
    }

    private func format(_ value: Double, suffix: String) -> String {
        guard value > 0 else { return "—" }
        return String(format: "%.0f%@", value, suffix)
    }

    private enum CheckInStage { case landing, authorizing, loading, complete, error }
}

// MARK: - Shared UI bits

struct MetricRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).font(.system(.body, design: .monospaced))
        }
    }
}

struct Tag: View {
    let label: String
    let active: Bool

    init(_ label: String, active: Bool) {
        self.label = label
        self.active = active
    }

    var body: some View {
        Text(label)
            .font(.system(size: active ? 15 : 12,
                          weight: active ? .bold : .regular,
                          design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(
                    active
                    ? Color.btAccent.opacity(0.15)
                    : Color.secondary.opacity(0.12)
                )
            )
            .scaleEffect(active ? 1.06 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: active)
    }
}

// MARK: - Cognitive start + Fancy report

struct CognitiveStartView<Content: View>: View {
    let onStart: () -> Void
    @ViewBuilder var content: Content
    @State private var go = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                LinearGradient(colors: [.btAccent.opacity(0.18), .btAccent.opacity(0.06)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                VStack(spacing: 10) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(Color.btAccent)
                    Text("Cognitive Assessment")
                        .font(.title2).fontWeight(.semibold)
                    Text("A short memory & attention check. Takes ~3–4 minutes.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            NavigationLink(isActive: $go) { content } label: {
                Button {
                    onStart()
                    go = true
                } label: {
                    Text("Begin").bold().frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.btAccent)
            }
            .buttonStyle(.plain)

            Text("Your results are stored locally and used only to generate your report.")
                .font(.footnote).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .padding()
    }
}

struct FancyReportView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Survivorship Report")
                        .font(.title2).fontWeight(.semibold)
                    Text("Generated locally with your latest check-in")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))

                VStack(alignment: .leading, spacing: 12) {
                    Text(.init(text)) // Markdown rendering
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .textSelection(.enabled)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))

                HStack {
                    ShareLink("Share", item: text)
                    Button("Copy") { UIPasteboard.general.string = text }
                        .buttonStyle(.bordered)
                    Spacer()
                    Button("Done") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .tint(.btAccent)
                }
            }
            .padding()
        }
        .navigationTitle("Report")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(width: 260, height: 52)               // <- less wide, taller
            .background(Color.btAccent.opacity(configuration.isPressed ? 0.85 : 1))
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: configuration.isPressed ? 0 : 6, y: 3)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: configuration.isPressed)
    }
}

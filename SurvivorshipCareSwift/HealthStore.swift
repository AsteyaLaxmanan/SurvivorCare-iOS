//import Foundation
//import HealthKit
//
//
//final class HealthStore {
//    private let healthStore = HKHealthStore()
//    private var readTypes: Set<HKObjectType> = []
//    private static let fileDateFormatter: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
//        return formatter
//    }()
//    private let bpmUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
//    
//    init() {
//        guard HKHealthStore.isHealthDataAvailable() else { return }
//        readTypes = [
//            HKObjectType.quantityType(forIdentifier: .heartRate)!,
//            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
//            HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage)!,
//            HKObjectType.quantityType(forIdentifier: .stepCount)!,
//            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
//            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
//            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
//            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
//            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!
//        ]
//    }
//
//    func requestAuthorization(completion: @escaping (Result<Void, Error>) -> Void) {
//        guard HKHealthStore.isHealthDataAvailable() else {
//            completion(.failure(NSError(domain: "HealthKit", code: 0, userInfo: [NSLocalizedDescriptionKey: "HealthKit not available"])))
//            return
//        }
//
//        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
//            DispatchQueue.main.async {
//                if success {
//                    completion(.success(()))
//                } else {
//                    completion(.failure(error ?? NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Authorization failed"])))
//                }
//            }
//        }
//    }
//    
//    func persist(summary: HealthSummary) throws -> URL {
//        let checkIn = DailyCheckIn(summary: summary)
//        let encoder = JSONEncoder()
//        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
//        encoder.dateEncodingStrategy = .iso8601
//        let data = try encoder.encode(checkIn)
//
//        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let fileName = "checkin-\(HealthStore.fileDateFormatter.string(from: checkIn.timestamp)).json"
//        let url = documents.appendingPathComponent(fileName)
//        try data.write(to: url, options: .atomic)
//        return url
//    }
//
//
//    func fetchTodaySummary(completion: @escaping (HealthSummary) -> Void) {
//        func runWindow(from start: Date, to end: Date, done: @escaping (HealthSummary) -> Void) {
//            let dispatchGroup = DispatchGroup()
//            var summary = HealthSummary()
//
//            func runQuery(
//                quantityTypeIdentifier: HKQuantityTypeIdentifier,
//                unit: HKUnit,
//                reducer: @escaping (Double) -> Void
//            ) {
//                guard let type = HKQuantityType.quantityType(forIdentifier: quantityTypeIdentifier) else { return }
//                dispatchGroup.enter()
//                let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
//                let query = HKStatisticsQuery(quantityType: type,
//                                              quantitySamplePredicate: predicate,
//                                              options: .cumulativeSum) { _, stats, _ in
//                    if let value = stats?.sumQuantity()?.doubleValue(for: unit) {
//                        DispatchQueue.main.async { reducer(value) }
//                    }
//                    dispatchGroup.leave()
//                }
//                healthStore.execute(query)
//            }
//
//            runQuery(quantityTypeIdentifier: .stepCount,              unit: .count())        { summary.steps = $0 }
//            runQuery(quantityTypeIdentifier: .distanceWalkingRunning, unit: .meter())        { summary.distanceKm = $0 / 1000 }
//            runQuery(quantityTypeIdentifier: .activeEnergyBurned,     unit: .kilocalorie())  { summary.activeKcal = $0 }
//            runQuery(quantityTypeIdentifier: .basalEnergyBurned,      unit: .kilocalorie())  { summary.basalKcal = $0 }
//            runQuery(quantityTypeIdentifier: .flightsClimbed,         unit: .count())        { summary.flights = $0 }
//            runQuery(quantityTypeIdentifier: .appleExerciseTime,      unit: .minute())       { summary.exerciseMinutes = $0 }
//
//            // Latest heart rate sample (past 7 days)
//            dispatchGroup.enter()
//            if let heartType = HKObjectType.quantityType(forIdentifier: .heartRate) {
//                let hrStart = Calendar.current.date(byAdding: .day, value: -7, to: end)!
//                let predicate = HKQuery.predicateForSamples(withStart: hrStart, end: end, options: .strictStartDate)
//                let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
//                let query = HKSampleQuery(sampleType: heartType,
//                                          predicate: predicate,
//                                          limit: 1,
//                                          sortDescriptors: [sort]) { _, samples, _ in
//                    if let q = (samples?.first as? HKQuantitySample)?.quantity {
//                        let bpm = q.doubleValue(for: self.bpmUnit)
//                        DispatchQueue.main.async { summary.heartRate = bpm }
//                    }
//                    dispatchGroup.leave()
//                }
//                healthStore.execute(query)
//            } else {
//                dispatchGroup.leave()
//            }
//
//            dispatchGroup.notify(queue: .main) { done(summary) }
//        }
//
//        // 1) Try TODAY (midnight → now)
//        let now = Date()
//        let todayStart = Calendar.current.startOfDay(for: now)
//        runWindow(from: todayStart, to: now) { today in
//            let looksEmpty =
//                today.steps == 0 &&
//                today.distanceKm == 0 &&
//                today.activeKcal == 0 &&
//                today.basalKcal == 0 &&
//                today.flights == 0 &&
//                today.exerciseMinutes == 0 &&
//                today.heartRate.isNaN
//
//            if !looksEmpty {
//                completion(today)
//                return
//            }
//
//            // 2) Fallback: last 24 hours (now-24h → now)
//            let last24hStart = Calendar.current.date(byAdding: .hour, value: -24, to: now)!
//            runWindow(from: last24hStart, to: now) { last24 in
//                completion(last24)
//            }
//        }
//    }
//}
//
//struct HealthSummary: Codable, Equatable {
//    // Activity (you already had most of these)
//    var steps: Double = 0
//    var distanceKm: Double = 0
//    var activeKcal: Double = 0
//    var basalKcal: Double = 0
//    var flights: Double = 0
//    var exerciseMinutes: Double = 0
//
//    // Cardio (existing + new)
//    var heartRate: Double = .nan          // latest HR
//    var restingHR: Double?                // bpm
//    var walkingHRAvgBPM: Double?          // bpm
//    var workoutAvgHRToday: Double?        // bpm
//    var workoutMaxHRToday: Double?        // bpm
//    var hrvSDNNms: Double?                // ms
//    var vo2Max: Double?                   // ml/kg·min
//
//    // Respiratory / oxygen
//    var oxygenSatPct: Double?             // %
//
//    // Body & vitals
//    var bodyMassKg: Double?
//    var systolicBP: Double?               // mmHg
//    var diastolicBP: Double?              // mmHg
//
//    // Sleep
//    var lastSleepSummary: String?         // e.g., “6.8 h asleep (last 2 nights window)”
//}
//
//
//struct DailyCheckIn: Codable, Identifiable {
//    let id = UUID()
//    let timestamp = Date()
//    let summary: HealthSummary
//}


import Foundation
import HealthKit

final class HealthStore {
    private let healthStore = HKHealthStore()
    private var readTypes: Set<HKObjectType> = []
    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter
    }()
    private let bpmUnit = HKUnit.count().unitDivided(by: HKUnit.minute())

    init() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        // Quantity helpers
        func q(_ id: HKQuantityTypeIdentifier) -> HKObjectType? {
            HKObjectType.quantityType(forIdentifier: id)
        }
        // Category helpers
        func c(_ id: HKCategoryTypeIdentifier) -> HKObjectType? {
            HKObjectType.categoryType(forIdentifier: id)
        }

        // --- Activity ---
        let activity: [HKObjectType?] = [
            q(.stepCount),
            q(.distanceWalkingRunning),
            q(.activeEnergyBurned),
            q(.basalEnergyBurned),
            q(.flightsClimbed),
            q(.appleExerciseTime),
            HKObjectType.workoutType()
        ]

        // --- Cardio / performance ---
        let cardio: [HKObjectType?] = [
            q(.heartRate),
            q(.restingHeartRate),
            q(.walkingHeartRateAverage),
            q(.heartRateVariabilitySDNN),
            q(.vo2Max)
        ]

        // --- Respiratory / oxygen ---
        let resp: [HKObjectType?] = [
            q(.oxygenSaturation)
        ]

        // --- Body & vitals ---
        let body: [HKObjectType?] = [
            q(.bodyMass),
            q(.bloodPressureSystolic),
            q(.bloodPressureDiastolic)
        ]

        // --- Sleep ---
        let sleep: [HKObjectType?] = [
            c(.sleepAnalysis)
        ]

        readTypes = Set((activity + cardio + resp + body + sleep).compactMap { $0 })
    }

    // MARK: - Authorization
    func requestAuthorization(completion: @escaping (Result<Void, Error>) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(.failure(NSError(domain: "HealthKit", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "HealthKit not available"])))
            return
        }

        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else {
                    completion(.failure(error ?? NSError(domain: "HealthKit", code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Authorization failed"])))
                }
            }
        }
    }

    // MARK: - Persistence (unchanged)
    func persist(summary: HealthSummary) throws -> URL {
        let checkIn = DailyCheckIn(summary: summary)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(checkIn)

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "checkin-\(HealthStore.fileDateFormatter.string(from: checkIn.timestamp)).json"
        let url = documents.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: - Summary
    func fetchTodaySummary(completion: @escaping (HealthSummary) -> Void) {
        func runWindow(from start: Date, to end: Date, done: @escaping (HealthSummary) -> Void) {
            let group = DispatchGroup()
            var summary = HealthSummary()

            // Helpers
            func todaySum(_ id: HKQuantityTypeIdentifier, unit: HKUnit, apply: @escaping (Double) -> Void) {
                guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return }
                group.enter()
                let pred = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
                let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: pred, options: .cumulativeSum) {
                    _, stats, _ in
                    let v = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                    DispatchQueue.main.async { apply(v) }
                    group.leave()
                }
                healthStore.execute(q)
            }

            func latest(_ id: HKQuantityTypeIdentifier, unit: HKUnit, apply: @escaping (Double) -> Void) {
                guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return }
                group.enter()
                let pred: NSPredicate? = nil // latest overall
                let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
                let q = HKSampleQuery(sampleType: type, predicate: pred, limit: 1, sortDescriptors: [sort]) {
                    _, samples, _ in
                    if let s = samples?.first as? HKQuantitySample {
                        let v = s.quantity.doubleValue(for: unit)
                        DispatchQueue.main.async { apply(v) }
                    }
                    group.leave()
                }
                healthStore.execute(q)
            }

            // --- Activity (sums over window) ---
            todaySum(.stepCount,              unit: .count())       { summary.steps = $0 }
            todaySum(.distanceWalkingRunning, unit: .meter())       { summary.distanceKm = $0 / 1000.0 }
            todaySum(.activeEnergyBurned,     unit: .kilocalorie()) { summary.activeKcal = $0 }
            todaySum(.basalEnergyBurned,      unit: .kilocalorie()) { summary.basalKcal  = $0 }
            todaySum(.flightsClimbed,         unit: .count())       { summary.flights    = $0 }
            todaySum(.appleExerciseTime,      unit: .minute())      { summary.exerciseMinutes = $0 }

            // --- Cardio (latest) ---
            latest(.heartRate,                unit: bpmUnit)        { summary.heartRate = $0 }
            latest(.restingHeartRate,         unit: bpmUnit)        { summary.restingHR = $0 }
            latest(.walkingHeartRateAverage,  unit: bpmUnit)        { summary.walkingHRAvgBPM = $0 }
            latest(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli)) { summary.hrvSDNNms = $0 }
            latest(.vo2Max,                   unit: HKUnit(from: "ml/kg*min")) { summary.vo2Max = $0 }

            // --- Oxygen (latest) ---
            latest(.oxygenSaturation,         unit: .percent())     { summary.oxygenSatPct = $0 * 100.0 }

            // --- Body & vitals (latest) ---
            latest(.bodyMass,                 unit: .gramUnit(with: .kilo))       { summary.bodyMassKg = $0 }
            latest(.bloodPressureSystolic,    unit: .millimeterOfMercury())       { summary.systolicBP = $0 }
            latest(.bloodPressureDiastolic,   unit: .millimeterOfMercury())       { summary.diastolicBP = $0 }

            // --- Sleep (simple 2-day window summary) ---
            if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                group.enter()
                let twoDays = Calendar.current.date(byAdding: .day, value: -2, to: end)!
                let pred  = HKQuery.predicateForSamples(withStart: twoDays, end: end, options: [])
                let sort  = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
                let q = HKSampleQuery(sampleType: sleepType, predicate: pred, limit: 200, sortDescriptors: [sort]) {
                    _, samples, _ in
                    defer { group.leave() }
                    let asleep = (samples as? [HKCategorySample])?
                        .filter {
                            $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                            $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                            $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue
                        } ?? []
                    let total = asleep.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                    DispatchQueue.main.async {
                        summary.lastSleepSummary = String(format: "%.1f h asleep (last 2 nights window)", total/3600.0)
                    }
                }
                healthStore.execute(q)
            }

            // --- Workout HR (avg / max across today’s workouts) ---
            if let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
                group.enter()
                let dayStart = Calendar.current.startOfDay(for: end)
                let pred = HKQuery.predicateForSamples(withStart: dayStart, end: end, options: .strictStartDate)
                let wq = HKSampleQuery(sampleType: HKObjectType.workoutType(),
                                       predicate: pred,
                                       limit: HKObjectQueryNoLimit,
                                       sortDescriptors: nil) { [weak self] _, samples, _ in
                    guard let self = self, let workouts = samples as? [HKWorkout], !workouts.isEmpty else {
                        DispatchQueue.main.async {
                            summary.workoutAvgHRToday = nil
                            summary.workoutMaxHRToday = nil
                        }
                        group.leave()
                        return
                    }

                    let inner = DispatchGroup()
                    var avgSum = 0.0, avgCount = 0.0, maxHR = 0.0

                    for w in workouts {
                        inner.enter()
                        let p = HKQuery.predicateForSamples(withStart: w.startDate, end: w.endDate, options: .strictStartDate)
                        let stats = HKStatisticsQuery(quantityType: hrType,
                                                      quantitySamplePredicate: p,
                                                      options: [.discreteAverage, .discreteMax]) { _, st, _ in
                            if let a = st?.averageQuantity()?.doubleValue(for: self.bpmUnit) {
                                avgSum += a; avgCount += 1
                            }
                            if let m = st?.maximumQuantity()?.doubleValue(for: self.bpmUnit) {
                                maxHR = max(maxHR, m)
                            }
                            inner.leave()
                        }
                        self.healthStore.execute(stats)
                    }

                    inner.notify(queue: .main) {
                        if avgCount > 0 { summary.workoutAvgHRToday = avgSum / avgCount }
                        if maxHR > 0    { summary.workoutMaxHRToday = maxHR }
                        group.leave()
                    }
                }
                healthStore.execute(wq)
            }

            // --- Latest HR within last 7 days (kept from your version; harmless redundancy) ---
            group.enter()
            if let heartType = HKObjectType.quantityType(forIdentifier: .heartRate) {
                let hrStart = Calendar.current.date(byAdding: .day, value: -7, to: end)!
                let predicate = HKQuery.predicateForSamples(withStart: hrStart, end: end, options: .strictStartDate)
                let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
                let query = HKSampleQuery(sampleType: heartType, predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                    if let q = (samples?.first as? HKQuantitySample)?.quantity {
                        let bpm = q.doubleValue(for: self.bpmUnit)
                        DispatchQueue.main.async { summary.heartRate = bpm }
                    }
                    group.leave()
                }
                healthStore.execute(query)
            } else {
                group.leave()
            }

            group.notify(queue: .main) { done(summary) }
        }

        // Try today's window first, then fallback to last 24h
        let now = Date()
        let todayStart = Calendar.current.startOfDay(for: now)
        runWindow(from: todayStart, to: now) { today in
            let looksEmpty =
                today.steps == 0 &&
                today.distanceKm == 0 &&
                today.activeKcal == 0 &&
                today.basalKcal == 0 &&
                today.flights == 0 &&
                today.exerciseMinutes == 0 &&
                today.heartRate.isNaN
            if !looksEmpty {
                completion(today)
            } else {
                let last24hStart = Calendar.current.date(byAdding: .hour, value: -24, to: now)!
                runWindow(from: last24hStart, to: now, done: completion)
            }
        }
    }
}

// MARK: - Models (unchanged from your message)

struct HealthSummary: Codable, Equatable {
    // Activity
    var steps: Double = 0
    var distanceKm: Double = 0
    var activeKcal: Double = 0
    var basalKcal: Double = 0
    var flights: Double = 0
    var exerciseMinutes: Double = 0

    // Cardio / performance
    var heartRate: Double = .nan
    var restingHR: Double?
    var walkingHRAvgBPM: Double?
    var workoutAvgHRToday: Double?
    var workoutMaxHRToday: Double?
    var hrvSDNNms: Double?
    var vo2Max: Double?

    // Respiratory / oxygen
    var oxygenSatPct: Double?

    // Body & vitals
    var bodyMassKg: Double?
    var systolicBP: Double?
    var diastolicBP: Double?

    // Sleep
    var lastSleepSummary: String?
}

struct DailyCheckIn: Codable, Identifiable {
    let id = UUID()
    let timestamp = Date()
    let summary: HealthSummary
}

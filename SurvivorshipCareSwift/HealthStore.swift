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
        readTypes = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!
        ]
    }

    func requestAuthorization(completion: @escaping (Result<Void, Error>) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(.failure(NSError(domain: "HealthKit", code: 0, userInfo: [NSLocalizedDescriptionKey: "HealthKit not available"])))
            return
        }

        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else {
                    completion(.failure(error ?? NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Authorization failed"])))
                }
            }
        }
    }
    
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


    func fetchTodaySummary(completion: @escaping (HealthSummary) -> Void) {
        func runWindow(from start: Date, to end: Date, done: @escaping (HealthSummary) -> Void) {
            let dispatchGroup = DispatchGroup()
            var summary = HealthSummary()

            func runQuery(
                quantityTypeIdentifier: HKQuantityTypeIdentifier,
                unit: HKUnit,
                reducer: @escaping (Double) -> Void
            ) {
                guard let type = HKQuantityType.quantityType(forIdentifier: quantityTypeIdentifier) else { return }
                dispatchGroup.enter()
                let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
                let query = HKStatisticsQuery(quantityType: type,
                                              quantitySamplePredicate: predicate,
                                              options: .cumulativeSum) { _, stats, _ in
                    if let value = stats?.sumQuantity()?.doubleValue(for: unit) {
                        DispatchQueue.main.async { reducer(value) }
                    }
                    dispatchGroup.leave()
                }
                healthStore.execute(query)
            }

            runQuery(quantityTypeIdentifier: .stepCount,              unit: .count())        { summary.steps = $0 }
            runQuery(quantityTypeIdentifier: .distanceWalkingRunning, unit: .meter())        { summary.distanceKm = $0 / 1000 }
            runQuery(quantityTypeIdentifier: .activeEnergyBurned,     unit: .kilocalorie())  { summary.activeKcal = $0 }
            runQuery(quantityTypeIdentifier: .basalEnergyBurned,      unit: .kilocalorie())  { summary.basalKcal = $0 }
            runQuery(quantityTypeIdentifier: .flightsClimbed,         unit: .count())        { summary.flights = $0 }
            runQuery(quantityTypeIdentifier: .appleExerciseTime,      unit: .minute())       { summary.exerciseMinutes = $0 }

            // Latest heart rate sample (past 7 days)
            dispatchGroup.enter()
            if let heartType = HKObjectType.quantityType(forIdentifier: .heartRate) {
                let hrStart = Calendar.current.date(byAdding: .day, value: -7, to: end)!
                let predicate = HKQuery.predicateForSamples(withStart: hrStart, end: end, options: .strictStartDate)
                let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
                let query = HKSampleQuery(sampleType: heartType,
                                          predicate: predicate,
                                          limit: 1,
                                          sortDescriptors: [sort]) { _, samples, _ in
                    if let q = (samples?.first as? HKQuantitySample)?.quantity {
                        let bpm = q.doubleValue(for: self.bpmUnit)
                        DispatchQueue.main.async { summary.heartRate = bpm }
                    }
                    dispatchGroup.leave()
                }
                healthStore.execute(query)
            } else {
                dispatchGroup.leave()
            }

            dispatchGroup.notify(queue: .main) { done(summary) }
        }

        // 1) Try TODAY (midnight → now)
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
                return
            }

            // 2) Fallback: last 24 hours (now-24h → now)
            let last24hStart = Calendar.current.date(byAdding: .hour, value: -24, to: now)!
            runWindow(from: last24hStart, to: now) { last24 in
                completion(last24)
            }
        }
    }
}

struct HealthSummary: Codable, Equatable {
    // Activity (you already had most of these)
    var steps: Double = 0
    var distanceKm: Double = 0
    var activeKcal: Double = 0
    var basalKcal: Double = 0
    var flights: Double = 0
    var exerciseMinutes: Double = 0

    // Cardio (existing + new)
    var heartRate: Double = .nan          // latest HR
    var restingHR: Double?                // bpm
    var walkingHRAvgBPM: Double?          // bpm
    var workoutAvgHRToday: Double?        // bpm
    var workoutMaxHRToday: Double?        // bpm
    var hrvSDNNms: Double?                // ms
    var vo2Max: Double?                   // ml/kg·min

    // Respiratory / oxygen
    var oxygenSatPct: Double?             // %

    // Body & vitals
    var bodyMassKg: Double?
    var systolicBP: Double?               // mmHg
    var diastolicBP: Double?              // mmHg

    // Sleep
    var lastSleepSummary: String?         // e.g., “6.8 h asleep (last 2 nights window)”
}


struct DailyCheckIn: Codable, Identifiable {
    let id = UUID()
    let timestamp = Date()
    let summary: HealthSummary
}

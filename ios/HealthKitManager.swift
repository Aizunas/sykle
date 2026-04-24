//
//  HealthKitManager.swift
//  Sykle
//
//  Handles all HealthKit interactions - requesting permissions and reading cycling data
//  Updated for iOS 18 compatibility
//

import Foundation
import HealthKit

// MARK: - Cycling Workout Model
struct CyclingWorkout: Identifiable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let distanceKm: Double
    let durationMinutes: Double
    let caloriesBurned: Double?
    
    // Calculate points: (km × 100) + (min × 10)
    var pointsEarned: Int {
        let distancePoints = Int(distanceKm * 100)
        let durationPoints = Int(durationMinutes * 10)
        return distancePoints + durationPoints
    }
    
    // Calculate CO2 saved (150g per km vs car)
    var co2SavedGrams: Double {
        return distanceKm * 150
    }
}

// MARK: - HealthKit Manager
class HealthKitManager: ObservableObject {
    
    // Published properties that the UI will observe
    @Published var isAuthorized = false
    @Published var authorizationStatus: String = "Not Requested"
    
    // All cycling workouts (all time)
    @Published var allWorkouts: [CyclingWorkout] = []
    
    // Weekly workouts (last 7 days)
    @Published var weeklyWorkouts: [CyclingWorkout] = []
    
    // All time stats (for points and CO2)
    @Published var totalPoints: Int = 0
    @Published var totalCO2SavedGrams: Double = 0
    
    // Weekly stats (for km and minutes)
    @Published var weeklyDistanceKm: Double = 0
    @Published var weeklyMinutes: Double = 0
    
    // All time totals (kept for reference)
    @Published var totalDistanceKm: Double = 0
    @Published var totalMinutes: Double = 0
    
    // Last sync info
    @Published var lastSyncDate: Date?
    @Published var lastSyncPoints: Int = 0
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var onWorkoutsFetched: (([CyclingWorkout]) -> Void)?
    
    // HealthKit store
    private let healthStore = HKHealthStore()
    
    init() {
        checkExistingAuthorization()
    }
    
    private func checkExistingAuthorization() {
        guard isHealthKitAvailable else { return }
        
        // Check read authorization status for workout type
        let workoutType = HKObjectType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)
        
        // For read-only access, notDetermined means we haven't asked yet
        // sharingDenied means the user explicitly denied — but we should still try to read
        // Apple doesn't expose read authorization status directly for privacy reasons
        // So we just attempt to fetch and see if data comes back
        DispatchQueue.main.async {
            self.isAuthorized = true  // Assume authorized if we've been through onboarding
            self.authorizationStatus = "Authorized ✓"
            self.fetchAllData()
        }
    }
    
    // MARK: - Check if HealthKit is available
    var isHealthKitAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    // MARK: - Request Authorization
    func requestAuthorization() {
        guard isHealthKitAvailable else {
            DispatchQueue.main.async {
                self.authorizationStatus = "HealthKit not available on this device"
                self.errorMessage = "HealthKit is not available. Please use a real iPhone."
            }
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                // Always set authorized to true — Apple won't tell us read status
                self.isAuthorized = true
                self.authorizationStatus = "Authorized ✓"
                self.errorMessage = nil
                self.fetchAllData()
            }
        }
    }
    
    // MARK: - Fetch All Data (All Time + Weekly)
    func fetchAllData() {
        fetchCyclingWorkouts(daysBack: nil) // All time
    }
    
    // MARK: - Fetch Cycling Workouts
    // daysBack: nil = all time, or specify number of days
    func fetchCyclingWorkouts(daysBack: Int? = nil) {
        print("🏃 fetchCyclingWorkouts called, isAuthorized: \(isAuthorized)")
        guard isAuthorized else {
            errorMessage = "Please authorize HealthKit access first"
            return
        }
        
        var onWorkoutsFetched: (([CyclingWorkout]) -> Void)?
        
        isLoading = true
        errorMessage = nil
        
        let calendar = Calendar.current
        let endDate = Date()
        
        // For all time, go back 10 years (effectively all data)
        let startDate: Date
        if let days = daysBack {
            startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        } else {
            startDate = calendar.date(byAdding: .year, value: -10, to: endDate) ?? endDate
        }
        
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let workoutTypePredicate = HKQuery.predicateForWorkouts(with: .cycling)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, workoutTypePredicate])
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: compoundPredicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] query, samples, error in
            
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Error fetching workouts: \(error.localizedDescription)"
                    return
                }
                
                guard let workouts = samples as? [HKWorkout] else {
                    self?.errorMessage = "No cycling workouts found"
                    self?.allWorkouts = []
                    self?.weeklyWorkouts = []
                    return
                }
                
                // Convert to CyclingWorkout model
                let cyclingWorkouts = workouts.map { workout in
                    let distanceKm = self?.getWorkoutDistance(workout) ?? 0
                    let durationMinutes = workout.duration / 60
                    let calories = self?.getWorkoutCalories(workout)
                    
                    return CyclingWorkout(
                        id: workout.uuid,
                        startDate: workout.startDate,
                        endDate: workout.endDate,
                        distanceKm: distanceKm,
                        durationMinutes: durationMinutes,
                        caloriesBurned: calories
                    )
                }
                
                // Store all workouts
                self?.allWorkouts = cyclingWorkouts
                
                // Filter for weekly workouts (last 7 days)
                let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                self?.weeklyWorkouts = cyclingWorkouts.filter { $0.startDate >= sevenDaysAgo }
                
                // Calculate stats
                self?.calculateStats()
                
                DispatchQueue.main.async {
                    self?.onWorkoutsFetched?(self?.allWorkouts ?? [])
                }
                
                if let workouts = self?.allWorkouts {
                    self?.onWorkoutsFetched?(workouts)
                }
                
                // Set last sync info (most recent workout)
                if let mostRecent = cyclingWorkouts.first {
                    self?.lastSyncDate = mostRecent.startDate
                    self?.lastSyncPoints = mostRecent.pointsEarned
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Calculate Stats
    private func calculateStats() {
        // All time stats (points and CO2)
        totalPoints = allWorkouts.reduce(0) { $0 + $1.pointsEarned }
        totalCO2SavedGrams = allWorkouts.reduce(0) { $0 + $1.co2SavedGrams }
        totalDistanceKm = allWorkouts.reduce(0) { $0 + $1.distanceKm }
        totalMinutes = allWorkouts.reduce(0) { $0 + $1.durationMinutes }
        
        // Weekly stats (km and minutes)
        weeklyDistanceKm = weeklyWorkouts.reduce(0) { $0 + $1.distanceKm }
        weeklyMinutes = weeklyWorkouts.reduce(0) { $0 + $1.durationMinutes }
        
        print("🚴 Total workouts found: \(allWorkouts.count)")
        print("🚴 Weekly workouts: \(weeklyWorkouts.count)")
        print("🚴 Workouts: \(allWorkouts.count), Points: \(totalPoints)")

    }
    
    // MARK: - Get Workout Distance (iOS 18 compatible)
    private func getWorkoutDistance(_ workout: HKWorkout) -> Double {
        if let stats = workout.statistics(for: HKQuantityType(.distanceCycling)) {
            return stats.sumQuantity()?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0
        }
        
        if let distance = workout.totalDistance {
            return distance.doubleValue(for: .meterUnit(with: .kilo))
        }
        
        return 0
    }
    
    // MARK: - Get Workout Calories (iOS 18 compatible)
    private func getWorkoutCalories(_ workout: HKWorkout) -> Double? {
        if let stats = workout.statistics(for: HKQuantityType(.activeEnergyBurned)) {
            return stats.sumQuantity()?.doubleValue(for: .kilocalorie())
        }
        
        let energyType = HKQuantityType(.activeEnergyBurned)
        if let allStats = workout.allStatistics[energyType] {
            return allStats.sumQuantity()?.doubleValue(for: .kilocalorie())
        }
        
        return nil
    }
    
    // MARK: - Refresh Data
    func refresh() {
        fetchAllData()
    }
}

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
    @Published var cyclingWorkouts: [CyclingWorkout] = []
    @Published var totalPoints: Int = 0
    @Published var totalDistanceKm: Double = 0
    @Published var totalCO2SavedGrams: Double = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // HealthKit store
    private let healthStore = HKHealthStore()
    
    // MARK: - Check if HealthKit is available
    var isHealthKitAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    // MARK: - Request Authorization
    func requestAuthorization() {
        // Check if HealthKit is available on this device
        guard isHealthKitAvailable else {
            DispatchQueue.main.async {
                self.authorizationStatus = "HealthKit not available on this device"
                self.errorMessage = "HealthKit is not available. Please use a real iPhone."
            }
            return
        }
        
        // Define the data types we want to read
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),                                          // Workouts (cycling)
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!,        // Cycling distance
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!      // Calories
        ]
        
        // Request authorization
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isAuthorized = true
                    self.authorizationStatus = "Authorized ✓"
                    self.errorMessage = nil
                    
                    // Automatically fetch workouts after authorization
                    self.fetchCyclingWorkouts()
                } else {
                    self.isAuthorized = false
                    self.authorizationStatus = "Authorization Denied"
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    // MARK: - Fetch Cycling Workouts
    func fetchCyclingWorkouts(daysBack: Int = 30) {
        guard isAuthorized else {
            errorMessage = "Please authorize HealthKit access first"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Calculate the start date (e.g., 30 days ago)
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -daysBack, to: endDate) else {
            return
        }
        
        // Create a predicate to filter workouts by date and type
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let workoutTypePredicate = HKQuery.predicateForWorkouts(with: .cycling)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, workoutTypePredicate])
        
        // Sort by start date (most recent first)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        // Create the query
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
                    self?.cyclingWorkouts = []
                    return
                }
                
                // Convert HKWorkout to our CyclingWorkout model
                self?.cyclingWorkouts = workouts.map { workout in
                    // Get distance - use the new API
                    let distanceKm = self?.getWorkoutDistance(workout) ?? 0
                    
                    // Get duration
                    let durationMinutes = workout.duration / 60
                    
                    // Get calories - use the new API for iOS 18+
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
                
                // Calculate totals
                self?.calculateTotals()
            }
        }
        
        // Execute the query
        healthStore.execute(query)
    }
    
    // MARK: - Get Workout Distance (iOS 18 compatible)
    private func getWorkoutDistance(_ workout: HKWorkout) -> Double {
        // Try the new iOS 16+ API first
        if let stats = workout.statistics(for: HKQuantityType(.distanceCycling)) {
            return stats.sumQuantity()?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0
        }
        
        // Fallback to the older API for older iOS versions
        if let distance = workout.totalDistance {
            return distance.doubleValue(for: .meterUnit(with: .kilo))
        }
        
        return 0
    }
    
    // MARK: - Get Workout Calories (iOS 18 compatible)
    private func getWorkoutCalories(_ workout: HKWorkout) -> Double? {
        // Try the new iOS 16+ API first
        if let stats = workout.statistics(for: HKQuantityType(.activeEnergyBurned)) {
            return stats.sumQuantity()?.doubleValue(for: .kilocalorie())
        }
        
        // Fallback to the older API for older iOS versions
        // Using a workaround to avoid deprecation warning
        let energyType = HKQuantityType(.activeEnergyBurned)
        if let allStats = workout.allStatistics[energyType] {
            return allStats.sumQuantity()?.doubleValue(for: .kilocalorie())
        }
        
        return nil
    }
    
    // MARK: - Calculate Totals
    private func calculateTotals() {
        totalPoints = cyclingWorkouts.reduce(0) { $0 + $1.pointsEarned }
        totalDistanceKm = cyclingWorkouts.reduce(0) { $0 + $1.distanceKm }
        totalCO2SavedGrams = cyclingWorkouts.reduce(0) { $0 + $1.co2SavedGrams }
    }
    
    // MARK: - Refresh Data
    func refresh() {
        fetchCyclingWorkouts()
    }
}

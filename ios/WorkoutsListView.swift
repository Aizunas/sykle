//
//  WorkoutsListView.swift
//  Sykle
//
//  Created by Sanuzia Jorge on 18/01/2026.
//

//
//  WorkoutsListView.swift
//  Sykle
//
//  Shows all cycling workouts synced from HealthKit
//

import SwiftUI

struct WorkoutsListView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        NavigationView {
            Group {
                if healthKitManager.isLoading {
                    // Loading state
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Syncing workouts...")
                            .foregroundColor(.gray)
                    }
                } else if healthKitManager.cyclingWorkouts.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "bicycle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No cycling workouts found")
                            .font(.system(size: 18, weight: .medium))
                        
                        Text("Your cycling workouts from Apple Health will appear here")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            healthKitManager.refresh()
                        }) {
                            Text("Refresh")
                                .fontWeight(.medium)
                                .foregroundColor(Color("SykleBlue"))
                        }
                        .padding(.top, 8)
                    }
                } else {
                    // Workouts list
                    List {
                        // Summary section
                        Section {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(healthKitManager.cyclingWorkouts.count)")
                                        .font(.system(size: 32, weight: .bold))
                                    Text("Total Rides")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("\(healthKitManager.totalPoints)")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(Color("SykleBlue"))
                                    Text("Total Sykles")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        
                        // Workouts section
                        Section(header: Text("Last 30 Days")) {
                            ForEach(healthKitManager.cyclingWorkouts) { workout in
                                WorkoutDetailRow(workout: workout)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .refreshable {
                        healthKitManager.refresh()
                    }
                }
            }
            .navigationTitle("My Rides")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        healthKitManager.refresh()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

// MARK: - Workout Detail Row
struct WorkoutDetailRow: View {
    let workout: CyclingWorkout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date and points
            HStack {
                Text(formatDate(workout.startDate))
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    Text("+\(workout.pointsEarned) sykles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color("SykleBlue"))
                }
            }
            
            // Stats row
            HStack(spacing: 20) {
                StatItem(icon: "arrow.right", value: String(format: "%.2f km", workout.distanceKm), label: "Distance")
                StatItem(icon: "clock", value: "\(Int(workout.durationMinutes)) min", label: "Duration")
                if let calories = workout.caloriesBurned {
                    StatItem(icon: "flame.fill", value: "\(Int(calories)) kcal", label: "Calories")
                }
                StatItem(icon: "leaf.fill", value: String(format: "%.0fg", workout.co2SavedGrams), label: "CO₂ Saved")
            }
            
            // Points breakdown
            HStack {
                Text("Points: ")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text("(\(String(format: "%.1f", workout.distanceKm)) km × 100) + (\(Int(workout.durationMinutes)) min × 10) = \(workout.pointsEarned)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d 'at' h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 12, weight: .medium))
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Preview
struct WorkoutsListView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutsListView()
            .environmentObject(HealthKitManager())
    }
}

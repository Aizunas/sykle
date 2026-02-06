//
//  Untitled.swift
//  Sykle
//
//  Created by Sanuzia Jorge on 18/01/2026.
//

//
//  HomeView.swift
//  Sykle
//
//  Home screen showing points balance and featured rewards
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Points Balance Card
                    PointsBalanceCard(points: healthKitManager.totalPoints)
                    
                    // Stats Row
                    HStack(spacing: 16) {
                        StatCard(
                            icon: "leaf.fill",
                            value: String(format: "%.0fg", healthKitManager.totalCO2SavedGrams),
                            label: "CO₂ Saved",
                            color: .green
                        )
                        
                        StatCard(
                            icon: "bicycle",
                            value: String(format: "%.1f km", healthKitManager.totalDistanceKm),
                            label: "Distance",
                            color: Color("SykleBlue")
                        )
                        
                        StatCard(
                            icon: "flame.fill",
                            value: "\(healthKitManager.cyclingWorkouts.count)",
                            label: "Rides",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                    
                    // Featured Rewards Section (placeholder)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Featured Rewards")
                                .font(.system(size: 18, weight: .semibold))
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Placeholder reward cards
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                RewardCard(
                                    name: "Free Coffee",
                                    partner: "Local Cafe",
                                    points: 500,
                                    canAfford: healthKitManager.totalPoints >= 500
                                )
                                RewardCard(
                                    name: "Pastry",
                                    partner: "Bakery",
                                    points: 750,
                                    canAfford: healthKitManager.totalPoints >= 750
                                )
                                RewardCard(
                                    name: "Lunch Deal",
                                    partner: "Deli",
                                    points: 1500,
                                    canAfford: healthKitManager.totalPoints >= 1500
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Recent Activity
                    if !healthKitManager.cyclingWorkouts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Activity")
                                .font(.system(size: 18, weight: .semibold))
                                .padding(.horizontal)
                            
                            ForEach(healthKitManager.cyclingWorkouts.prefix(3)) { workout in
                                WorkoutRow(workout: workout)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.top)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("sykle.")
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

// MARK: - Points Balance Card
struct PointsBalanceCard: View {
    let points: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Your Balance")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
            
            // Pill-shaped points display
            Text("\(points)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
            
            Text("sykles")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            LinearGradient(
                colors: [Color("SykleBlue"), Color("SykleBlue").opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .padding(.horizontal)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Reward Card (Placeholder)
struct RewardCard: View {
    let name: String
    let partner: String
    let points: Int
    let canAfford: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Placeholder image
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 140, height: 80)
                .overlay(
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.gray.opacity(0.5))
                )
            
            Text(name)
                .font(.system(size: 14, weight: .semibold))
            
            Text(partner)
                .font(.system(size: 12))
                .foregroundColor(.gray)
            
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)
                Text("\(points) sykles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(canAfford ? Color("SykleBlue") : .gray)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .opacity(canAfford ? 1.0 : 0.6)
    }
}

// MARK: - Workout Row
struct WorkoutRow: View {
    let workout: CyclingWorkout
    
    var body: some View {
        HStack {
            // Bike icon
            ZStack {
                Circle()
                    .fill(Color("SykleBlue").opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "bicycle")
                    .foregroundColor(Color("SykleBlue"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(workout.startDate))
                    .font(.system(size: 14, weight: .medium))
                
                Text("\(String(format: "%.1f", workout.distanceKm)) km • \(Int(workout.durationMinutes)) min")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Points earned
            VStack(alignment: .trailing) {
                Text("+\(workout.pointsEarned)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color("SykleBlue"))
                
                Text("sykles")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(HealthKitManager())
    }
}

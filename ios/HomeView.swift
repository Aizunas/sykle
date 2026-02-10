//
//  HomeView.swift
//  Sykle
//
//  Home screen with points balance and sync functionality
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @StateObject private var userManager = UserManager.shared
    
    @State private var showingLoginSheet = false
    @State private var isConnected = false
    @State private var isCheckingConnection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Connection warning
                    if !isConnected && userManager.isLoggedIn {
                        ConnectionBanner(isChecking: $isCheckingConnection) {
                            checkConnection()
                        }
                    }
                    
                    // Login prompt
                    if !userManager.isLoggedIn {
                        LoginPromptCard {
                            showingLoginSheet = true
                        }
                    }
                    
                    // Points Balance
                    PointsBalanceCard(
                        points: userManager.isLoggedIn ? userManager.serverPoints : healthKitManager.totalPoints,
                        isLoggedIn: userManager.isLoggedIn
                    )
                    
                    // Sync Button
                    if userManager.isLoggedIn {
                        SyncButton(
                            isSyncing: userManager.isSyncing,
                            lastResult: userManager.lastSyncResult
                        ) {
                            Task {
                                await userManager.syncRides(workouts: healthKitManager.cyclingWorkouts)
                            }
                        }
                    }
                    
                    // Stats Row
                    HStack(spacing: 16) {
                        StatCard(
                            icon: "leaf.fill",
                            value: formatCO2(userManager.isLoggedIn ? userManager.serverCO2SavedG : healthKitManager.totalCO2SavedGrams),
                            label: "CO₂ Saved",
                            color: .green
                        )
                        
                        StatCard(
                            icon: "bicycle",
                            value: String(format: "%.1f km", userManager.isLoggedIn ? userManager.serverDistanceKm : healthKitManager.totalDistanceKm),
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
                    
                    // Error message
                    if let error = userManager.errorMessage {
                        ErrorBanner(message: error)
                    }
                    
                    // Recent rides
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
                    Button(action: { healthKitManager.refresh() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingLoginSheet) {
                LoginSheet()
            }
            .onAppear {
                checkConnection()
            }
        }
    }
    
    private func formatCO2(_ grams: Double) -> String {
        if grams >= 1000 {
            return String(format: "%.1f kg", grams / 1000)
        }
        return String(format: "%.0fg", grams)
    }
    
    private func checkConnection() {
        isCheckingConnection = true
        Task {
            let connected = await NetworkManager.shared.checkConnection()
            await MainActor.run {
                isConnected = connected
                isCheckingConnection = false
            }
        }
    }
}

// MARK: - Supporting Views

struct LoginPromptCard: View {
    let onLogin: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(Color("SykleBlue"))
            
            Text("Sign in to sync your rides")
                .font(.system(size: 16, weight: .medium))
            
            Text("Save your points to the cloud and redeem rewards")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: onLogin) {
                Text("Sign In")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color("SykleBlue"))
                    .cornerRadius(10)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct ConnectionBanner: View {
    @Binding var isChecking: Bool
    let onRetry: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "wifi.slash")
                .foregroundColor(.orange)
            Text("Cannot connect to server")
                .font(.system(size: 14))
            Spacer()
            if isChecking {
                ProgressView().scaleEffect(0.8)
            } else {
                Button("Retry", action: onRetry)
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.red)
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct SyncButton: View {
    let isSyncing: Bool
    let lastResult: String?
    let onSync: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: onSync) {
                HStack {
                    if isSyncing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text(isSyncing ? "Syncing..." : "Sync Rides to Cloud")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSyncing ? Color.gray : Color("SykleBlue"))
                .cornerRadius(12)
            }
            .disabled(isSyncing)
            
            if let result = lastResult {
                Text(result)
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal)
    }
}

struct PointsBalanceCard: View {
    let points: Int
    let isLoggedIn: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                if isLoggedIn {
                    Image(systemName: "checkmark.icloud.fill")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 14))
                }
            }
            .padding(.horizontal, 8)
            
            Text("Your Balance")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
            
            Text("\(points)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
            
            Text("sykles")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            if !isLoggedIn {
                Text("(local only)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
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

struct WorkoutRow: View {
    let workout: CyclingWorkout
    
    var body: some View {
        HStack {
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

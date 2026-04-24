//
//  ContentView.swift
//  Sykle
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @StateObject private var userManager = UserManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = true
    @State private var isCheckingAuth = true

    var body: some View {
        Group {
            if isCheckingAuth {
                ZStack {
                    Color.white.ignoresSafeArea()
                    Text("sykle.")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color("SykleBlue"))
                }
            } else if hasCompletedOnboarding && userManager.isLoggedIn {
                MainTabView()
            } else {
                OnboardingCarouselView(showOnboarding: $showOnboarding)
                    .onChange(of: showOnboarding) { newValue in
                        if !newValue {
                            hasCompletedOnboarding = true
                        }
                    }
            }
        }
        .onAppear {
            // If no saved user ID, no need to wait
            if UserDefaults.standard.string(forKey: "sykle_user_id") == nil {
                isCheckingAuth = false
                return
            }
            // Otherwise wait for UserManager to finish loading
            // Use a max timeout of 3 seconds as fallback
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                isCheckingAuth = false
            }
        }
        .onChange(of: userManager.isLoggedIn) { loggedIn in
            if loggedIn {
                isCheckingAuth = false
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            LeaderboardView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Leaderboard")
                }
            MapView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .tint(Color("SykleBlue"))
        .task {
            healthKitManager.fetchAllData()
            for _ in 0..<10 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !healthKitManager.allWorkouts.isEmpty {
                    break
                }
            }
            print("🔄 Auto-syncing \(healthKitManager.allWorkouts.count) workouts")
            await UserManager.shared.syncRides(workouts: healthKitManager.allWorkouts)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(HealthKitManager())
    }
}

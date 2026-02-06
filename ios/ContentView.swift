//
//  ContentView.swift
//  Sykle
//
//  Created by Sanuzia Jorge on 18/01/2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        // Check if authorized - show onboarding or main app
        if healthKitManager.isAuthorized {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

// MARK: - Main Tab View (shown after authorization)
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            WorkoutsListView()
                .tabItem {
                    Image(systemName: "bicycle")
                    Text("Rides")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .tint(Color("SykleBlue"))
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(HealthKitManager())
    }
}

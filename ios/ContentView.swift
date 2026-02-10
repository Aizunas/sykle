//
//  ContentView.swift
//  Sykle
//
//  Main content view with tab navigation
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        if healthKitManager.isAuthorized {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            PartnersView()
                .tabItem {
                    Image(systemName: "cup.and.saucer.fill")
                    Text("Partners")
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(HealthKitManager())
    }
}

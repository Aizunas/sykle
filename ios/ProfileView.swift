//
//  ProfileView.swift
//  Sykle
//
//  Created by Sanuzia Jorge on 18/01/2026.
//

//
//  ProfileView.swift
//  Sykle
//
//  User profile showing stats and settings
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        NavigationView {
            List {
                // Profile Header
                Section {
                    HStack(spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color("SykleBlue"))
                                .frame(width: 70, height: 70)
                            
                            Text("👤")
                                .font(.system(size: 30))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cyclist")
                                .font(.system(size: 20, weight: .semibold))
                            
                            HStack {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.yellow)
                                Text("\(healthKitManager.totalPoints) sykles")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color("SykleBlue"))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Stats Section
                Section(header: Text("Your Impact")) {
                    StatRow(
                        icon: "leaf.fill",
                        iconColor: .green,
                        title: "CO₂ Saved",
                        value: formatCO2(healthKitManager.totalCO2SavedGrams)
                    )
                    
                    StatRow(
                        icon: "bicycle",
                        iconColor: Color("SykleBlue"),
                        title: "Total Distance",
                        value: String(format: "%.1f km", healthKitManager.totalDistanceKm)
                    )
                    
                    StatRow(
                        icon: "flame.fill",
                        iconColor: .orange,
                        title: "Total Rides",
                        value: "\(healthKitManager.cyclingWorkouts.count)"
                    )
                    
                    StatRow(
                        icon: "star.fill",
                        iconColor: .yellow,
                        title: "Points Earned",
                        value: "\(healthKitManager.totalPoints) sykles"
                    )
                }
                
                // Account Section
                Section(header: Text("Account")) {
                    NavigationLink(destination: Text("Edit Profile")) {
                        Label("Edit Profile", systemImage: "person.fill")
                    }
                    
                    NavigationLink(destination: Text("Past Orders")) {
                        Label("Past Orders", systemImage: "bag.fill")
                    }
                    
                    NavigationLink(destination: Text("Notifications")) {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                }
                
                // Health Section
                Section(header: Text("Health Data")) {
                    HStack {
                        Label("Apple Health", systemImage: "heart.fill")
                            .foregroundColor(.red)
                        Spacer()
                        Text("Connected")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                    }
                    
                    Button(action: {
                        healthKitManager.refresh()
                    }) {
                        Label("Sync Now", systemImage: "arrow.clockwise")
                    }
                }
                
                // App Info Section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Beta)")
                            .foregroundColor(.gray)
                    }
                    
                    NavigationLink(destination: Text("Privacy Policy")) {
                        Text("Privacy Policy")
                    }
                    
                    NavigationLink(destination: Text("Terms of Service")) {
                        Text("Terms of Service")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Profile")
        }
    }
    
    func formatCO2(_ grams: Double) -> String {
        if grams >= 1000 {
            return String(format: "%.1f kg", grams / 1000)
        } else {
            return String(format: "%.0f g", grams)
        }
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(title)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(HealthKitManager())
    }
}

//
//  SykleApp.swift
//  Sykle
//
//  Created by Sanuzia Jorge on 18/01/2026.
//

import SwiftUI

@main
struct SykleApp: App {
    // Create the HealthKit manager as a shared instance
    @StateObject private var healthKitManager = HealthKitManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKitManager)
        }
    }
}

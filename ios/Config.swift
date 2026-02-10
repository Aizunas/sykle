//
//  Config.swift
//  Sykle
//
//  App configuration - safe to push to GitHub
//

import Foundation

struct Config {
    
    // ===========================================
    // API URL
    // ===========================================
    
    #if DEBUG
        // Development - uses IP from Secrets.swift
        static let apiBaseURL = "http://\(Secrets.macIPAddress):3000/api"
    #else
        // Production - update this when you deploy
        static let apiBaseURL = "https://your-deployed-api.com/api"
    #endif
    
    // ===========================================
    // Points Settings
    // ===========================================
    
    static let pointsPerKm = 100
    static let pointsPerMinute = 10
    static let co2SavedPerKm = 150.0  // grams vs car
}

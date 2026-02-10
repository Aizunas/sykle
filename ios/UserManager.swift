//
//  UserManager.swift
//  Sykle
//
//  Manages user state, authentication, and syncing with backend
//

import Foundation

class UserManager: ObservableObject {
    
    static let shared = UserManager()
    
    // MARK: - Published Properties
    
    @Published var currentUser: APIUser?
    @Published var isLoggedIn = false
    @Published var isSyncing = false
    @Published var lastSyncResult: String?
    @Published var errorMessage: String?
    
    // Points from server (more accurate than local)
    @Published var serverPoints: Int = 0
    @Published var serverDistanceKm: Double = 0
    @Published var serverCO2SavedG: Double = 0
    
    // MARK: - Private Properties
    
    private let networkManager = NetworkManager.shared
    private let userIdKey = "sykle_user_id"
    private let userEmailKey = "sykle_user_email"
    
    // MARK: - Initialization
    
    init() {
        // Check if user was previously logged in
        if let userId = UserDefaults.standard.string(forKey: userIdKey) {
            loadUser(id: userId)
        }
    }
    
    // MARK: - User ID Storage
    
    var savedUserId: String? {
        return UserDefaults.standard.string(forKey: userIdKey)
    }
    
    private func saveUserId(_ id: String, email: String) {
        UserDefaults.standard.set(id, forKey: userIdKey)
        UserDefaults.standard.set(email, forKey: userEmailKey)
    }
    
    func clearUser() {
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        currentUser = nil
        isLoggedIn = false
        serverPoints = 0
    }
    
    // MARK: - Login / Register
    
    /// Create or login user with email
    func loginOrRegister(email: String, name: String?) async {
        do {
            let user = try await networkManager.createUser(email: email, name: name)
            
            await MainActor.run {
                self.currentUser = user
                self.isLoggedIn = true
                self.serverPoints = user.totalPoints
                self.serverDistanceKm = user.totalDistanceKm
                self.serverCO2SavedG = user.totalCo2SavedG
                self.errorMessage = nil
                self.saveUserId(user.id, email: email)
            }
            
            print("✅ Logged in as: \(user.email) (ID: \(user.id))")
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            print("❌ Login failed: \(error)")
        }
    }
    
    /// Load existing user by ID
    func loadUser(id: String) {
        Task {
            do {
                let user = try await networkManager.getUser(id: id)
                
                await MainActor.run {
                    self.currentUser = user
                    self.isLoggedIn = true
                    self.serverPoints = user.totalPoints
                    self.serverDistanceKm = user.totalDistanceKm
                    self.serverCO2SavedG = user.totalCo2SavedG
                }
                
                print("✅ Loaded user: \(user.email)")
                
            } catch {
                await MainActor.run {
                    // User not found on server, clear local data
                    self.clearUser()
                }
                print("❌ Failed to load user: \(error)")
            }
        }
    }
    
    // MARK: - Sync Rides
    
    /// Sync cycling workouts from HealthKit to the backend
    func syncRides(workouts: [CyclingWorkout]) async {
        guard let userId = currentUser?.id else {
            await MainActor.run {
                self.errorMessage = "Please log in first"
            }
            return
        }
        
        guard !workouts.isEmpty else {
            await MainActor.run {
                self.lastSyncResult = "No rides to sync"
            }
            return
        }
        
        await MainActor.run {
            self.isSyncing = true
            self.errorMessage = nil
        }
        
        do {
            let response = try await networkManager.syncRides(userId: userId, workouts: workouts)
            
            await MainActor.run {
                self.isSyncing = false
                self.serverPoints = response.user.totalPoints
                self.serverDistanceKm = response.user.totalDistanceKm
                self.serverCO2SavedG = Double(response.user.totalCO2SavedGrams)
                
                if response.summary.newRidesSynced > 0 {
                    self.lastSyncResult = "Synced \(response.summary.newRidesSynced) rides! +\(response.summary.pointsEarned) sykles"
                } else {
                    self.lastSyncResult = "All rides already synced"
                }
            }
            
            print("✅ Sync complete: \(response.message)")
            
        } catch {
            await MainActor.run {
                self.isSyncing = false
                self.errorMessage = error.localizedDescription
                self.lastSyncResult = nil
            }
            print("❌ Sync failed: \(error)")
        }
    }
    
    // MARK: - Refresh User Data
    
    func refreshUser() async {
        guard let userId = currentUser?.id else { return }
        
        do {
            let user = try await networkManager.getUser(id: userId)
            
            await MainActor.run {
                self.currentUser = user
                self.serverPoints = user.totalPoints
                self.serverDistanceKm = user.totalDistanceKm
                self.serverCO2SavedG = user.totalCo2SavedG
            }
            
        } catch {
            print("❌ Failed to refresh user: \(error)")
        }
    }
}

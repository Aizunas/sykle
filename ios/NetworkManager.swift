//
//  NetworkManager.swift
//  Sykle
//
//  Handles all communication with the backend API
//

import Foundation

// MARK: - Network Errors

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(String)
    case networkUnavailable
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        case .networkUnavailable:
            return "Cannot connect to server. Make sure your Mac is running the backend and you're on the same WiFi."
        case .timeout:
            return "Request timed out"
        }
    }
}

// MARK: - Network Manager

class NetworkManager: ObservableObject {
    
    static let shared = NetworkManager()
    
    @Published var isLoading = false
    @Published var lastError: String?
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Base URL
    
    private var baseURL: String {
        return Config.apiBaseURL
    }
    
    // MARK: - Generic Request Method
    
    private func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = body
        }
        
        print("📡 \(method) \(url.absoluteString)")
        if let body = body, let bodyString = String(data: body, encoding: .utf8) {
            print("📦 Body: \(bodyString)")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.noData
            }
            
            print("📥 Response: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Data: \(responseString.prefix(500))")
            }
            
            // Check for error responses
            if httpResponse.statusCode >= 400 {
                if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    throw NetworkError.serverError(errorResponse.error)
                }
                throw NetworkError.serverError("Server error: \(httpResponse.statusCode)")
            }
            
            // Decode successful response
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                print("❌ Decoding error: \(error)")
                throw NetworkError.decodingError(error)
            }
            
        } catch let error as NetworkError {
            throw error
        } catch {
            print("❌ Network error: \(error)")
            if (error as NSError).code == NSURLErrorNotConnectedToInternet ||
               (error as NSError).code == NSURLErrorCannotConnectToHost {
                throw NetworkError.networkUnavailable
            }
            if (error as NSError).code == NSURLErrorTimedOut {
                throw NetworkError.timeout
            }
            throw error
        }
    }
    
    // MARK: - User API
    
    /// Create a new user or get existing user by email
    func createUser(email: String, name: String?) async throws -> APIUser {
        let requestBody = CreateUserRequest(email: email, name: name)
        let body = try JSONEncoder().encode(requestBody)
        
        let response: CreateUserResponse = try await request(
            endpoint: "users",
            method: "POST",
            body: body
        )
        
        return response.user
    }
    
    /// Get user by ID
    func getUser(id: String) async throws -> APIUser {
        let response: GetUserResponse = try await request(endpoint: "users/\(id)")
        return response.user
    }
    
    // MARK: - Rides API
    
    /// Sync cycling workouts to the backend
    func syncRides(userId: String, workouts: [CyclingWorkout]) async throws -> SyncRidesResponse {
        
        // Convert CyclingWorkout to SyncRideData
        let formatter = ISO8601DateFormatter()
        
        let rideData = workouts.map { workout in
            SyncRideData(
                healthkitUuid: workout.id.uuidString,
                startDate: formatter.string(from: workout.startDate),
                endDate: formatter.string(from: workout.endDate),
                distanceKm: workout.distanceKm,
                durationMinutes: workout.durationMinutes,
                caloriesBurned: workout.caloriesBurned
            )
        }
        
        let requestBody = SyncRidesRequest(userId: userId, rides: rideData)
        let body = try JSONEncoder().encode(requestBody)
        
        return try await request(
            endpoint: "rides",
            method: "POST",
            body: body
        )
    }
    
    // MARK: - Partners API
    
    /// Get all partner cafes
    func getPartners(latitude: Double? = nil, longitude: Double? = nil) async throws -> [APIPartner] {
        var endpoint = "partners"
        
        if let lat = latitude, let lng = longitude {
            endpoint += "?lat=\(lat)&lng=\(lng)"
        }
        
        let response: GetPartnersResponse = try await request(endpoint: endpoint)
        return response.partners
    }
    
    /// Get single partner with their rewards
    func getPartner(id: String) async throws -> GetPartnerResponse {
        return try await request(endpoint: "partners/\(id)")
    }
    
    // MARK: - Rewards API
    
    /// Get all available rewards
    func getRewards(maxPoints: Int? = nil) async throws -> [APIReward] {
        var endpoint = "rewards"
        
        if let maxPoints = maxPoints {
            endpoint += "?maxPoints=\(maxPoints)"
        }
        
        let response: GetRewardsResponse = try await request(endpoint: endpoint)
        return response.rewards
    }
    
    /// Redeem a reward
    func redeemReward(userId: String, rewardId: String) async throws -> RedeemRewardResponse {
        let requestBody = RedeemRewardRequest(userId: userId, rewardId: rewardId)
        let body = try JSONEncoder().encode(requestBody)
        
        return try await request(
            endpoint: "rewards/redeem",
            method: "POST",
            body: body
        )
    }
    
    // MARK: - Health Check
    
    /// Check if the backend is reachable
    func checkConnection() async -> Bool {
        guard let url = URL(string: baseURL.replacingOccurrences(of: "/api", with: "")) else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        
        do {
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            print("❌ Connection check failed: \(error)")
            return false
        }
    }
}

//
//  APIModels.swift
//  Sykle
//
//  Data models for API requests and responses
//

import Foundation
import CoreLocation

// MARK: - User Models

struct APIUser: Codable {
    let id: String
    let email: String
    let firstName: String?
    let lastName: String?
    let fullName: String?
    let totalPoints: Int
    let totalDistanceKm: Double
    let totalCO2SavedG: Double
    let availablePoints: Int?
    
    // Computed property for display name
    var displayName: String {
        if let full = fullName, !full.isEmpty { return full }
        if let first = firstName { return first }
        return email.components(separatedBy: "@").first ?? email
    }
}

struct CreateUserRequest: Codable {
    let email: String
    let firstName: String?
    let lastName: String?
    let password: String
}

struct CreateUserResponse: Codable {
    let message: String
    let user: APIUser
}

struct GetUserResponse: Codable {
    let user: APIUser
}

// MARK: - Ride Models

struct SyncRideData: Codable {
    let healthkitUuid: String
    let startDate: String
    let endDate: String
    let distanceKm: Double
    let durationMinutes: Double
    let caloriesBurned: Double?
}

struct SyncRidesRequest: Codable {
    let userId: String
    let rides: [SyncRideData]
}

struct SyncRidesSummary: Codable {
    let ridesProcessed: Int
    let newRidesSynced: Int
    let pointsEarned: Int
    let co2SavedGrams: Int
}

struct SyncRidesUserInfo: Codable {
    let totalPoints: Int
    let totalDistanceKm: Double
    let totalCO2SavedGrams: Int
}

struct SyncRidesResponse: Codable {
    let message: String
    let summary: SyncRidesSummary
    let user: SyncRidesUserInfo
}

// MARK: - Partner Models

struct APIPartnerHours: Codable, Hashable {
    let open: String
    let close: String
}

struct APIPartnerWeeklyHours: Codable, Hashable {
    let weekday: APIPartnerHours
    let weekend: APIPartnerHours
}

struct APIPartner: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let imageName: String?
    let syklersVisited: String?
    let hours: APIPartnerWeeklyHours?
    let isOpen: Bool?
    let timeStatus: String?
    let rewardCount: Int?
    let distanceMiles: Double?
    let distanceDisplay: String?
    let description: String?
    
    
    enum CodingKeys: String, CodingKey {
        case id, name, category, address, latitude, longitude, hours
        case imageName = "image_name"
        case syklersVisited = "syklers_visited"
        case isOpen = "is_open"
        case timeStatus = "time_status"
        case rewardCount = "reward_count"
        case distanceMiles = "distance_miles"
        case distanceDisplay = "distance_display"
        case description
    }
    
    // Convert to FakePartner for UI compatibility
    func toFakePartner() -> FakePartner {
        let coord = CLLocationCoordinate2D(
            latitude: latitude ?? 51.5255,
            longitude: longitude ?? -0.0755
        )
        
        // Build weekly hours dictionary from nested hours object
        var weeklyHours: [Int: DayHours] = [:]
        if let h = hours {
            let weekday = DayHours(open: h.weekday.open, close: h.weekday.close)
            let weekend = DayHours(open: h.weekend.open, close: h.weekend.close)
            weeklyHours = [
                1: weekend,  // Sunday
                2: weekday,  // Monday
                3: weekday,  // Tuesday
                4: weekday,  // Wednesday
                5: weekday,  // Thursday
                6: weekday,  // Friday
                7: weekend   // Saturday
            ]
        }
        
        let openHoursString: String
        if let h = hours {
            openHoursString = "\(formatTime(h.weekday.open)) – \(formatTime(h.weekday.close))"
        } else {
            openHoursString = "8:00 AM – 6:00 PM"
        }
        
        return FakePartner(
            apiId: id,
            name: name,
            category: category,
            address: address ?? "",
            coordinate: coord,
            openHours: openHoursString,
            pointsCost: 100,
            reward: "Various rewards",
            distanceMiles: distanceDisplay ?? "\(distanceMiles ?? 0.5) miles away",
            syklersVisited: syklersVisited ?? "5+",
            weeklyHours: weeklyHours
        )
    }
    
    private func formatTime(_ time24: String) -> String {
        let parts = time24.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 1 else { return time24 }
        let hour = parts[0]
        let minute = parts.count > 1 ? parts[1] : 0
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        return "\(displayHour):\(String(format: "%02d", minute)) \(period)"
    }
}

struct GetPartnersResponse: Codable {
    let partners: [APIPartner]
}

struct GetPartnerResponse: Codable {
    let partner: APIPartner
    let rewards: [APIReward]
}

// MARK: - Reward Models

struct APIReward: Codable, Identifiable, Hashable {
    let id: String
    let partnerId: String?
    let name: String
    let category: String?
    let pointsCost: Int
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, category, description
        case partnerId = "partner_id"
        case pointsCost = "points_cost"
    }
    
    // Convert to FakeReward for UI compatibility
    func toFakeReward() -> FakeReward {
        return FakeReward(
            apiId: id,
            name: name,
            syklesCost: pointsCost,
            category: category ?? "Food"
        )
    }
}

struct GetRewardsResponse: Codable {
    let rewards: [APIReward]
}

// MARK: - Redemption Models

struct RedeemRewardRequest: Codable {
    let userId: String
    let rewardId: String
}

struct RedeemRewardResponse: Codable {
    let message: String
    let redemption: RedemptionInfo
    let remainingPoints: Int
}

struct Redemption: Codable, Identifiable {
    let id: String
    let visitorId: String
    let rewardId: String
    let qrCode: String
    let status: String
    let expiresAt: String
    let createdAt: String
    let reward: APIReward?
    let partner: APIPartner?
    
    enum CodingKeys: String, CodingKey {
        case id
        case visitorId = "visitor_id"
        case rewardId = "reward_id"
        case qrCode = "qr_code"
        case status
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case reward
        case partner
    }
}

struct RedemptionInfo: Codable {
    let id: String
    let qrCode: String
    let expiresAt: String
}

// MARK: - Error Response

struct APIErrorResponse: Codable {
    let error: String
}

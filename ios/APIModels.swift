//
//  APIModels.swift
//  Sykle
//
//  Data models for API requests and responses
//

import Foundation

// MARK: - User Models

struct APIUser: Codable {
    let id: String
    let email: String
    let name: String?
    let totalPoints: Int
    let totalDistanceKm: Double
    let totalCo2SavedG: Double
    
    enum CodingKeys: String, CodingKey {
        case id, email, name
        case totalPoints = "total_points"
        case totalDistanceKm = "total_distance_km"
        case totalCo2SavedG = "total_co2_saved_g"
    }
}

struct CreateUserRequest: Codable {
    let email: String
    let name: String?
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

struct APIPartner: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let imageUrl: String?
    let category: String
    let rewardCount: Int?
    let distanceKm: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, address, latitude, longitude, category
        case imageUrl = "image_url"
        case rewardCount = "reward_count"
        case distanceKm = "distance_km"
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

struct APIReward: Codable, Identifiable {
    let id: String
    let partnerId: String
    let name: String
    let description: String?
    let pointsCost: Int
    let imageUrl: String?
    let partnerName: String?
    let partnerAddress: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case partnerId = "partner_id"
        case pointsCost = "points_cost"
        case imageUrl = "image_url"
        case partnerName = "partner_name"
        case partnerAddress = "partner_address"
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

struct RedemptionInfo: Codable {
    let id: String
    let qrCode: String
    let expiresAt: String
}

struct RedeemRewardResponse: Codable {
    let message: String
    let redemption: RedemptionInfo
    let remainingPoints: Int
}

// MARK: - Error Response

struct APIErrorResponse: Codable {
    let error: String
}

//
//  PartnerStore.swift
//  Sykle
//
//  Manages partner data - fetches from API with fallback to local data
//

import Foundation
import CoreLocation

// MARK: - Partner Store

@MainActor
class PartnerStore: ObservableObject {
    static let shared = PartnerStore()
    
    @Published var partners: [FakePartner] = []
    @Published var rewardsByPartner: [String: [FakeReward]] = [:]
    @Published var isLoading = false
    @Published var hasLoaded = false
    @Published var error: String?
    
    private init() {
        // Start with local fallback data
        self.partners = fakePartners
        self.rewardsByPartner = fakeRewards
    }
    
    // MARK: - Fetch Partners from API
    
    func loadPartners() async {
        guard !hasLoaded else { return }
        
        isLoading = true
        error = nil
        
        do {
            let apiPartners = try await NetworkManager.shared.getPartners()
            
            // Convert API partners to FakePartner format
            let converted = apiPartners.map { $0.toFakePartner() }
            
            if !converted.isEmpty {
                self.partners = converted
                print("✅ Loaded \(converted.count) partners from API")
            }
            
            // Now fetch rewards for each partner
            await loadAllRewards()
            
            self.hasLoaded = true
            
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to load partners: \(error)")
            print("⚠️ Using local fallback data")
            // Keep using fakePartners
        }
        
        isLoading = false
    }
    
    // MARK: - Load All Rewards
    
    private func loadAllRewards() async {
        var newRewards: [String: [FakeReward]] = [:]
        
        for (index, partner) in partners.enumerated() {
            if let apiId = partner.apiId {
                // Stagger requests 50ms apart to avoid overwhelming Railway
                try? await Task.sleep(nanoseconds: UInt64(index) * 50_000_000)
                do {
                    let response = try await NetworkManager.shared.getPartner(id: apiId)
                    let rewards = response.rewards.map { $0.toFakeReward() }
                    newRewards[partner.name] = rewards
                } catch {
                    print("⚠️ Failed to load rewards for \(partner.name)")
                }
            }
        }
        
        if !newRewards.isEmpty {
            self.rewardsByPartner = newRewards
            print("✅ Loaded rewards for \(newRewards.count) partners")
        }
    }
    
    // MARK: - Get Rewards for Partner
    
    func getRewards(for partnerName: String) -> [FakeReward] {
        return rewardsByPartner[partnerName] ?? fakeRewards[partnerName] ?? []
    }
    
    // MARK: - Get Partner by Name
    
    func getPartner(named name: String) -> FakePartner? {
        return partners.first { $0.name == name }
    }
    
    // MARK: - Refresh
    
    func refresh() async {
        hasLoaded = false
        await loadPartners()
    }
    
    func repositionPartners(around center: CLLocationCoordinate2D) {
        // Don't reposition if already close to this location
            if let first = partners.first {
                let existing = CLLocation(latitude: first.coordinate.latitude, longitude: first.coordinate.longitude)
                let new = CLLocation(latitude: center.latitude, longitude: center.longitude)
                // Only reposition if user moved more than 100 metres
                if existing.distance(from: new) < 100 { return }
            }
        let offsets: [(Double, Double)] = [
            ( 0.0030,  0.0050),
            (-0.0045,  0.0030),
            ( 0.0020, -0.0040),
            ( 0.0060,  0.0020),
            (-0.0025,  0.0060),
            ( 0.0010,  0.0080),
            (-0.0060, -0.0030),
            ( 0.0040, -0.0060),
            ( 0.0090,  0.0040),
            (-0.0080,  0.0050),
            ( 0.0070, -0.0080),
            (-0.0050, -0.0090),
            ( 0.0120,  0.0010),
            (-0.0100,  0.0080),
            ( 0.0050,  0.0130),
            (-0.0090, -0.0120),
            ( 0.0150,  0.0060),
            (-0.0130,  0.0100),
            ( 0.0100, -0.0150),
            (-0.0160, -0.0050),
            ( 0.0180,  0.0020),
            (-0.0050,  0.0170),
        ]

        let source = fakePartners.isEmpty ? partners : fakePartners
        let userLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)

        partners = zip(source, offsets).map { partner, offset in
            let newCoord = CLLocationCoordinate2D(
                latitude: center.latitude + offset.0,
                longitude: center.longitude + offset.1
            )
            let partnerLocation = CLLocation(latitude: newCoord.latitude, longitude: newCoord.longitude)
            let distanceMeters = userLocation.distance(from: partnerLocation)
            let distanceMiles = distanceMeters / 1609.34
            let distanceString = String(format: "%.1f miles away", distanceMiles)

            return FakePartner(
                apiId: partner.apiId,
                name: partner.name,
                category: partner.category,
                address: partner.address,
                coordinate: newCoord,
                openHours: partner.openHours,
                pointsCost: partner.pointsCost,
                reward: partner.reward,
                distanceMiles: distanceString,
                syklersVisited: partner.syklersVisited,
                weeklyHours: partner.weeklyHours
            )
        }
    }
}

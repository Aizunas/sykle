//
//  BasketManager.swift
//  Sykle
//

import Foundation
import Combine

// MARK: - BasketItem

struct BasketItem: Identifiable {
    let id = UUID()
    let reward: FakeReward
    let partner: FakePartner
    var quantity: Int
}

// MARK: - BasketManager

@MainActor
class BasketManager: ObservableObject {
    static let shared = BasketManager()

    @Published var items: [BasketItem] = []

    private init() {}

    // MARK: - Computed Properties

    var totalSykles: Int {
        items.reduce(0) { $0 + ($1.reward.syklesCost * $1.quantity) }
    }

    var currentPartner: FakePartner? {
        items.first?.partner
    }
    

    // MARK: - Actions

    func add(reward: FakeReward, partner: FakePartner) {
        if let index = items.firstIndex(where: { $0.reward.id == reward.id }) {
            items[index].quantity += 1
        } else {
            items.append(BasketItem(reward: reward, partner: partner, quantity: 1))
        }
    }

    func remove(reward: FakeReward) {
        items.removeAll { $0.reward.id == reward.id }
    }

    func decrement(reward: FakeReward) {
        if let index = items.firstIndex(where: { $0.reward.id == reward.id }) {
            if items[index].quantity > 1 {
                items[index].quantity -= 1
            } else {
                items.remove(at: index)
            }
        }
    }

    func clear() {
        items = []
    }
    
    // MARK: - Partner Validation

    func isFromDifferentPartner(_ partner: FakePartner) -> Bool {
        guard let current = currentPartner else { return false }
        return current.name != partner.name
    }

    func replaceWithNew(reward: FakeReward, partner: FakePartner) {
        items = [BasketItem(reward: reward, partner: partner, quantity: 1)]
    }
}

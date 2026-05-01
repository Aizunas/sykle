//
//  VoucherStore.swift
//  Sykle
//

import Foundation

// MARK: - Voucher Item

struct VoucherItem: Codable, Hashable {
    let name: String
    let quantity: Int
    let syklesCost: Int
}

// MARK: - Voucher Partner

struct VoucherPartner: Codable, Hashable {
    let name: String
    let distanceMiles: String
    var imageName: String {
        name.lowercased().replacingOccurrences(of: " ", with: "_")
    }
}

// MARK: - Saved Voucher Model

struct SavedVoucher: Identifiable, Codable {
    let id: UUID
    let partners: [VoucherPartner]
    let items: [VoucherItem]
    let voucherCode: String
    let transactionId: String
    let totalSykles: Int
    let redeemedOn: Date
    let validUntil: Date
    var isActive: Bool

    init(partners: [VoucherPartner], totalSykles: Int, validUntil: Date? = nil, items: [VoucherItem] = []) {
        self.id = UUID()
        self.partners = partners
        self.items = items
        self.voucherCode = Self.generateCode()
        self.transactionId = Self.generateTxId()
        self.totalSykles = totalSykles
        self.redeemedOn = Date()
        self.validUntil = validUntil ?? Date().addingTimeInterval(15 * 60)
        self.isActive = true
    }

    init(partnerName: String, partnerDistanceMiles: String, totalSykles: Int) {
        self.init(
            partners: [VoucherPartner(name: partnerName, distanceMiles: partnerDistanceMiles)],
            totalSykles: totalSykles
        )
    }

    var partnerName: String { partners.first?.name ?? "" }
    var partnerDistanceMiles: String { partners.first?.distanceMiles ?? "" }
    var isExpired: Bool { Date() > validUntil }

    var validUntilString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "Today until \(formatter.string(from: validUntil))"
    }

    var redeemedOnString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy - h:mm a"
        return formatter.string(from: redeemedOn)
    }

    private static func generateCode() -> String {
        "SYKLE-CF-\(Int.random(in: 1000...9999))K\(Int.random(in: 1...9))"
    }

    private static func generateTxId() -> String {
        "#SYK-\(Int.random(in: 10000...99999))"
    }
}

// MARK: - Voucher Store

class VoucherStore: ObservableObject {
    static let shared = VoucherStore()

    @Published var vouchers: [SavedVoucher] = []

    private var key: String {
        let userId = UserDefaults.standard.string(forKey: "sykle_user_id") ?? "guest"
        return "sykle_saved_vouchers_\(userId)"
    }

    init() { load() }

    func save(voucher: SavedVoucher) {
        vouchers.insert(voucher, at: 0)
        persist()
    }

    func clear(voucher: SavedVoucher) {
        if let index = vouchers.firstIndex(where: { $0.id == voucher.id }) {
            vouchers[index].isActive = false
            persist()
        }
    }

    func loadForCurrentUser() {
        load()
    }

    var activeVouchers: [SavedVoucher] {
        vouchers.filter { $0.isActive && !$0.isExpired }
    }

    var pastVouchers: [SavedVoucher] {
        vouchers.filter { !$0.isActive || $0.isExpired }
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(vouchers) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([SavedVoucher].self, from: data) {
            vouchers = decoded
        } else {
            vouchers = []
        }
    }
}

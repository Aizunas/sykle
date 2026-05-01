//
//  BasketView.swift
//  Sykle
//

import SwiftUI

struct BasketView: View {
    @ObservedObject private var basket = BasketManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Group {
                if basket.items.isEmpty {
                    EmptyBasketView()
                } else {
                    FilledBasketView(onVoucherDismissed: { dismiss() })
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Basket")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .fixedSize()
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !basket.items.isEmpty {
                        Button(action: { basket.clear() }) {
                            Image(systemName: "trash")
                                .foregroundColor(.black)
                                .font(.system(size: 18))
                        }
                    }
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
        }
    }
}

// MARK: - Empty Basket

struct EmptyBasketView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "basket")
                .font(.system(size: 80))
                .foregroundColor(Color.gray.opacity(0.4))
                .padding(.bottom, 8)
            Text("Your basket is empty")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            Text("You haven't added any rewards yet.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Filled Basket

struct FilledBasketView: View {
    let onVoucherDismissed: () -> Void

    @ObservedObject private var basket = BasketManager.shared
    @ObservedObject private var voucherStore = VoucherStore.shared
    @State private var activeVoucher: SavedVoucher? = nil
    @StateObject private var userManager = UserManager.shared
    

    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)
    let cardBlue = Color(red: 173/255, green: 210/255, blue: 235/255)

    var currentSykles: Int {
        userManager.serverPoints
    }
    
    var hasEnoughSykles: Bool {
        currentSykles >= basket.totalSykles
    }
    
    var syklesAfterRedemption: Int {
        max(0, currentSykles - basket.totalSykles)
    }
    
    var partner: FakePartner? {
        basket.currentPartner
    }
    
    var canRedeem: Bool {
        //(partner?.isCurrentlyOpen ?? false) &&
        hasEnoughSykles
    }

    var closingTimeString: String {
        guard let closing = partner?.closingTimeToday else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: closing)
    }
    
    

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                
                // Partner header card
                if let partner = partner {
                    VStack(alignment: .leading, spacing: 10) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 120)
                            .overlay(
                                Image(partner.name
                                    .lowercased()
                                    .replacingOccurrences(of: " ", with: "_"))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipped()
                            )
                            .clipped()
                            .cornerRadius(12, corners: [.topLeft, .topRight])
                        
                        HStack {
                            Text(partner.name)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.black)
                            Spacer()
                            Text(partner.distanceMiles)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 14)
                        
                        Text(partner.timeUntilCloseString)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(partner.isOpen ? Color.sykleGreen : Color.syklePink)
                            .cornerRadius(20)
                            .padding(.horizontal, 14)
                            .padding(.bottom, 12)
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                }
                
                // Reward items
                VStack(spacing: 8) {
                    ForEach(basket.items, id: \.id) { item in
                        RewardItemRow(item: item, basket: basket, cardBlue: cardBlue)
                    }
                }
                
                Divider().padding(.vertical, 8)
                
                // Total row
                HStack {
                    Text("Total")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                    HStack(spacing: 6) {
                        Image("SykleLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("\(basket.totalSykles) sykles")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .overlay(Capsule().stroke(sykleBlue, lineWidth: 1.5))
                }
                
                // Sykles after redemption
                HStack {
                    Text("Sykles after redemption")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Spacer()
                    HStack(spacing: 6) {
                        Image("SykleLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .opacity(0.5)
                        Text("\(syklesAfterRedemption)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(20)
                }
                
                SwipeToRedeemButton(
                    isEnabled: canRedeem,
                    onComplete: {
                        if let partner = partner {
                            Task {
                                // Call backend to deduct points for each item
                                for item in basket.items {
                                    if let apiId = item.reward.apiId {
                                        if let userId = UserManager.shared.currentUser?.id {
                                            _ = try? await NetworkManager.shared.redeemReward(
                                                userId: userId,
                                                rewardId: apiId
                                            )
                                        }
                                    }
                                }
                                
                                // Create voucher locally
                                let voucherPartner = VoucherPartner(name: partner.name, distanceMiles: partner.distanceMiles)
                                let expiry = partner.closingTimeToday ?? Date().addingTimeInterval(15 * 60)
                                let voucherItems = basket.items.map {
                                    VoucherItem(name: $0.reward.name, quantity: $0.quantity, syklesCost: $0.reward.syklesCost * $0.quantity)
                                }
                                let voucher = SavedVoucher(
                                    partners: [voucherPartner],
                                    totalSykles: basket.totalSykles,
                                    validUntil: expiry,
                                    items: voucherItems
                                )
                                voucherStore.save(voucher: voucher)
                                activeVoucher = voucher
                                
                                // Refresh points
                                await UserManager.shared.refreshUser()
                                
                            }
                        }
                    }
                    
                    )
                        
                .padding(.top, 8)

                if !canRedeem {
                    if !(partner?.isCurrentlyOpen ?? false) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.badge.xmark")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                            Text("Redemption unavailable outside opening hours")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    } else if !hasEnoughSykles {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                            Text("You need \(basket.totalSykles - currentSykles) more sykles to redeem")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                } else {
                    Text("Voucher valid until \(closingTimeString)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .fullScreenCover(item: $activeVoucher) { voucher in
            let imageName = voucher.partnerName
                .lowercased()
                .replacingOccurrences(of: " ", with: "_")
            VoucherView(
                voucher: voucher,
                partnerImageName: imageName,
                onDismiss: {
                    basket.clear()
                    onVoucherDismissed()
                }
            )
        }
    }
}

// MARK: - Reward Item Row

struct RewardItemRow: View {
    let item: BasketItem
    @ObservedObject var basket: BasketManager
    let cardBlue: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row: name + quantity badge + remove
            HStack {
                HStack(spacing: 6) {
                    Text(item.reward.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                    
                    if item.quantity > 1 {
                        Text("×\(item.quantity)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.sykleMid)
                            .cornerRadius(12)
                    }
                }
                Spacer()
                Button(action: { basket.remove(reward: item.reward) }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Bottom row: price pill + stepper
            HStack {
                HStack(spacing: 6) {
                    Image("SykleLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("\(item.reward.syklesCost * item.quantity) sykles")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white)
                .cornerRadius(20)
                
                Spacer()
                
                HStack(spacing: 0) {
                    Button(action: { basket.decrement(reward: item.reward) }) {
                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.sykleMid)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Text("\(item.quantity)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 24)

                    Button(action: {
                        if item.quantity < 6 {
                            basket.add(reward: item.reward, partner: item.partner)
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(item.quantity >= 6 ? .gray.opacity(0.3) : .sykleMid)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(item.quantity >= 6)
                }
                .background(Color.white)
                .cornerRadius(20)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(cardBlue)
        .cornerRadius(12)
    }
}

// MARK: - Swipe to Redeem
    struct SwipeToRedeemButton: View {
        var isEnabled: Bool = true  // add this
        let onComplete: () -> Void

        @State private var dragOffset: CGFloat = 0
        @State private var isRedeemed = false

        let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)
        let thumbSize: CGFloat = 52
        let trackHeight: CGFloat = 56

        var body: some View {
            GeometryReader { geo in
                let maxDrag = geo.size.width - thumbSize - 8
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(isEnabled ? sykleBlue : Color.gray.opacity(0.4))  // grey when disabled
                        .frame(height: trackHeight)
                    Text(isRedeemed ? "Generating voucher..." : "swipe to generate voucher")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isEnabled ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .overlay(
                            Image(systemName: isRedeemed ? "checkmark" : "arrow.right")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(isEnabled ? sykleBlue : .gray)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .offset(x: 4 + dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    guard isEnabled, !isRedeemed else { return }  // blocked when disabled
                                    dragOffset = min(max(0, value.translation.width), maxDrag)
                                }
                                .onEnded { _ in
                                    guard isEnabled else {
                                        withAnimation(.spring()) { dragOffset = 0 }
                                        return
                                    }
                                    if dragOffset > maxDrag * 0.85 {
                                        withAnimation(.spring()) {
                                            dragOffset = maxDrag
                                            isRedeemed = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                            onComplete()
                                        }
                                    } else {
                                        withAnimation(.spring()) { dragOffset = 0 }
                                    }
                                }
                        )
                }
                .frame(height: trackHeight)
            }
            .frame(height: trackHeight)
        }
    }

#Preview {
    BasketView()
}

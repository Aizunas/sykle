//
//  PartnerDetailView.swift
//  Sykle
//

import SwiftUI

// MARK: - PartnerDetailView

struct PartnerDetailView: View {
    let partner: FakePartner

    @StateObject private var partnerStore = PartnerStore.shared
    @ObservedObject private var basket = BasketManager.shared
    @Environment(\.dismiss) var dismiss
    var cameFromFavourites: Bool = false

    @State private var selectedTab: RewardTab = .all
    @State private var showInfo = false
    @State private var showBasket = false
    @State private var addedRewardId: UUID? = nil
    @State private var showingHours = false
    @State private var showingReplaceAlert = false
    @State private var pendingReward: FakeReward? = nil

    let sykleBlue   = Color.sykleMid
    let sykleYellow = Color(hex: "FED903")
    let cardBlue    = Color.sykleLight

    var rewards: [FakeReward] {
        partnerStore.getRewards(for: partner.name)
    }

    var filteredRewards: [FakeReward] {
        switch selectedTab {
        case .all:    return rewards
        case .drinks: return rewards.filter { $0.category == "Drinks" }
        case .food:   return rewards.filter { $0.category == "Food" }
        }
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: Hero image
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 220)
                            .overlay(
                                Image(partner.name
                                    .lowercased()
                                    .replacingOccurrences(of: " ", with: "_"))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .clipped()
                            )
                            .clipped()
                    }
                    .frame(height: 220)

                    // MARK: Info section
                    VStack(alignment: .leading, spacing: 10) {

                        // Name + star + info
                        HStack(alignment: .top) {
                            Text(partner.name)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(sykleBlue)
                            Spacer()
                            FavouriteStarButton(partner: partner)
                            Button(action: { showInfo = true }) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(.black)
                            }
                        }

                        // Address
                        Text(partner.address)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)

                        // Tappable hours row
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showingHours.toggle()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Text(partner.todayHoursString)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.black)
                                Image(systemName: showingHours ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Expanded weekly hours
                        if showingHours {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach([2, 3, 4, 5, 6, 7, 1], id: \.self) { weekday in
                                    let isToday = Calendar.current.component(.weekday, from: Date()) == weekday
                                    HStack(spacing: 14) {
                                        Text(dayLetter(for: weekday))
                                            .font(.system(size: 12, weight: isToday ? .semibold : .regular))
                                            .foregroundColor(isToday ? .black : .gray)
                                            .frame(width: 14, alignment: .leading)

                                        if let hours = partner.weeklyHours[weekday] {
                                            Text("\(formatHour(hours.open)) – \(formatHour(hours.close))")
                                                .font(.system(size: 12, weight: isToday ? .semibold : .regular))
                                                .foregroundColor(isToday ? .black : .gray)
                                        } else {
                                            Text("Closed")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.top, 6)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Open/Closed + visits pills
                        HStack(spacing: 8) {
                            Text(partner.isOpen ? "Open" : "Closed")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(partner.isOpen ? Color.sykleGreen : Color.syklePink)
                                .cornerRadius(20)

                            Text("\(partner.syklersVisited)+ visits")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(sykleBlue)
                                .cornerRadius(20)
                        }
                        .padding(.top, 4)

                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16)

                    // MARK: Filter tabs
                    HStack(spacing: 10) {
                        ForEach(RewardTab.allCases, id: \.self) { tab in
                            Button(action: { selectedTab = tab }) {
                                Text(tab.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedTab == tab ? Color.white : Color.clear)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // MARK: Reward cards
                    VStack(spacing: 12) {
                        ForEach(filteredRewards) { reward in
                            RewardCard(
                                reward: reward,
                                justAdded: addedRewardId == reward.id,
                                onAdd: {
                                    // Check if basket has items from a different partner
                                    if basket.isFromDifferentPartner(partner) {
                                        pendingReward = reward
                                        showingReplaceAlert = true
                                    } else {
                                        basket.add(reward: reward, partner: partner)
                                        addedRewardId = reward.id
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                            addedRewardId = nil
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)

                }
            }
            .ignoresSafeArea(edges: .top)

            // Info overlay
            if showInfo {
                InfoOverlay(onDismiss: { showInfo = false })
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if cameFromFavourites {
                    Button(action: { dismiss() }) {
                        Image(systemName: "star")
                            .foregroundColor(.black)
                            .font(.system(size: 20))
                    }
                } else {
                    NavigationLink(destination: FavouritesView()) {
                        Image(systemName: "star")
                            .foregroundColor(.black)
                            .font(.system(size: 20))
                    }
                }
                Button(action: { showBasket = true }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "cart")
                            .foregroundColor(.black)
                            .font(.system(size: 20))
                        if !basket.items.isEmpty {
                            Circle()
                                .fill(sykleBlue)
                                .frame(width: 10, height: 10)
                                .offset(x: 4, y: -4)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showBasket) {
            BasketView()
        }
        .alert("Replace basket?", isPresented: $showingReplaceAlert) {
            Button("Cancel", role: .cancel) {
                pendingReward = nil
            }
            Button("Replace", role: .destructive) {
                if let reward = pendingReward {
                    basket.replaceWithNew(reward: reward, partner: partner)
                    addedRewardId = reward.id
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        addedRewardId = nil
                    }
                }
                pendingReward = nil
            }
        } message: {
            Text("Your basket contains items from \(basket.currentPartner?.name ?? "another partner"). Replace with this reward?")
        }
    
    }

    // MARK: - Helpers

    private func dayLetter(for weekday: Int) -> String {
        switch weekday {
        case 1: return "S"
        case 2: return "M"
        case 3: return "T"
        case 4: return "W"
        case 5: return "T"
        case 6: return "F"
        case 7: return "S"
        default: return ""
        }
    }

    private func formatHour(_ time24: String) -> String {
        let inFmt = DateFormatter(); inFmt.dateFormat = "HH:mm"
        guard let date = inFmt.date(from: time24) else { return time24 }
        let outFmt = DateFormatter(); outFmt.dateFormat = "h:mm a"
        return outFmt.string(from: date)
    }
}

// MARK: - Reward Tab

enum RewardTab: String, CaseIterable {
    case all    = "All"
    case drinks = "Drinks"
    case food   = "Food"
}

// MARK: - Reward Card

struct RewardCard: View {
    let reward: FakeReward
    let justAdded: Bool
    let onAdd: () -> Void

    let cardBlue = Color.sykleLight
    let sykleBlue = Color.sykleMid

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(reward.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)

                HStack(spacing: 6) {
                    Image("SykleLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text("\(reward.syklesCost) sykles")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white)
                .cornerRadius(20)
            }

            Spacer()

            Button(action: onAdd) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(justAdded ? Color.green : sykleBlue)
                        .frame(width: 40, height: 40)
                    Image(systemName: justAdded ? "checkmark" : "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(cardBlue)
        .cornerRadius(14)
    }
}

// MARK: - Info Overlay

struct InfoOverlay: View {
    let onDismiss: () -> Void
    let sykleBlue = Color.sykleMid

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    Image("SykleLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                    Text("How to use your collected sykles?")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)

                VStack(spacing: 10) {
                    InfoStep(number: 1, text: "Add rewards to your basket")
                    InfoStep(number: 2, text: "Swipe to use your sykles and generate a voucher")
                    InfoStep(number: 3, text: "Show the QR code to staff — voucher is valid until the partner closes today")
                }

                Button(action: onDismiss) {
                    Text("Let's go")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(sykleBlue)
                        .cornerRadius(30)
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, 24)
        }
    }
}

struct InfoStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number).")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 20, alignment: .leading)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationView {
        PartnerDetailView(partner: fakePartners[0])
    }
}

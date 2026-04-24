//
//  HomeView.swift
//  Sykle
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @StateObject private var userManager = UserManager.shared
    @ObservedObject private var partnerStore = PartnerStore.shared
    @State private var showingLoginSheet = false
    @State private var showingBasket = false
    @ObservedObject private var basket = BasketManager.shared
    @ObservedObject private var locationManager = LocationManager.shared

    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)

    // MARK: - Curated partner lists per row
    // Each row picks specific partners by name, with occasional repeats across rows

    var coffeePartners: [FakePartner] {
        let names = ["OA Coffee", "Lannan", "Cremerie", "Dayz", "Sede", "Honu", "Latte Club", "OA Coffee", "Cado Cado"]
        return names.compactMap { name in partnerStore.partners.first { $0.name == name } }
    }

    var newestPartners: [FakePartner] {
        let names = ["Browneria", "Aleph", "Petibon", "Fufu", "Varmuteo", "Tio", "Makeroom", "Browneria", "Neulo"]
        return names.compactMap { name in partnerStore.partners.first { $0.name == name } }
    }

    var popularPartners: [FakePartner] {
        let names = ["Been Bakery", "La Joconde", "Rosemund Bakery", "Signorelli Pasticceria", "Honu", "Latte Club", "Been Bakery", "Browneria"]
        return names.compactMap { name in partnerStore.partners.first { $0.name == name } }
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    WalletCard(
                        points: userManager.isLoggedIn
                            ? userManager.serverPoints
                            : healthKitManager.totalPoints
                    )

                    FeaturedRewardSection(partnerStore: partnerStore)

                    HomePartnerRow(
                        title: "Coffee shops nearby",
                        partners: coffeePartners,
                        filterTitle: "Coffee shops nearby"
                    )
                    HomePartnerRow(
                        title: "Newest partners",
                        partners: newestPartners,
                        filterTitle: "Newest partners"
                    )
                    HomePartnerRow(
                        title: "Most popular partners",
                        partners: popularPartners,
                        filterTitle: "Most popular partners"
                    )

                    Spacer(minLength: 20)
                }
                .padding(.top, 8)
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("sykle.")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(sykleBlue)
                        .fixedSize()
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: FavouritesView()) {
                        Image(systemName: "star.fill")
                            .foregroundColor(Color(red: 254/255, green: 217/255, blue: 3/255))
                            .font(.system(size: 20))
                    }
                    Button(action: { showingBasket = true }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "cart")
                                .foregroundColor(.black)
                                .font(.system(size: 20))
                            if !basket.items.isEmpty {
                                Circle()
                                    .fill(Color(red: 88/255, green: 134/255, blue: 185/255))
                                    .frame(width: 10, height: 10)
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingLoginSheet) {
                LoginSheet()
            }
            .sheet(isPresented: $showingBasket) {
                BasketView()
            }
            .task {
                if !partnerStore.hasLoaded {
                    await partnerStore.loadPartners()
                }
                // Reposition after loading
                if let location = locationManager.userLocation {
                    partnerStore.repositionPartners(around: location)
                }
            }
            .onAppear {
                if let location = locationManager.userLocation {
                    partnerStore.repositionPartners(around: location)
                }
            }
            .onChange(of: locationManager.userLocation?.latitude) { _ in
                guard let location = locationManager.userLocation else { return }
                // Only reposition if partners are already loaded
                guard partnerStore.hasLoaded else { return }
                partnerStore.repositionPartners(around: location)
            }
        }
    }
}

// MARK: - Wallet Card

struct WalletCard: View {
    let points: Int
    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wallet")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 16)

            NavigationLink(destination: WalletView()) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(sykleBlue)

                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .frame(width: 190, height: 80)
                            .overlay(
                                HStack(spacing: 12) {
                                    Image("SykleLogo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 48, height: 48)
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text("\(points)")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.black)
                                        Text("sykles")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.gray)
                                    }
                                }
                            )
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
                .frame(height: 120)
                .padding(.horizontal, 16)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(height: 120)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Featured Reward Section

struct FeaturedRewardSection: View {
    @ObservedObject var partnerStore: PartnerStore
    let sykleYellow = Color(red: 254/255, green: 217/255, blue: 3/255)

    // Pick a featured partner+reward combo that changes daily
    var featured: (partner: FakePartner, reward: FakeReward)? {
        // Only consider free item rewards under 6000 sykles
        let eligible = partnerStore.partners.compactMap { partner -> (FakePartner, FakeReward)? in
            let rewards = PartnerStore.shared.getRewards(for: partner.name)
            let goodReward = rewards.first {
                $0.name.lowercased().contains("free") && $0.syklesCost <= 6000
            }
            guard let reward = goodReward else { return nil }
            return (partner, reward)
        }

        guard !eligible.isEmpty else { return nil }

        // Use day of year as seed so it changes daily but stays consistent within a day
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = dayOfYear % eligible.count
        return eligible[index]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundColor(sykleYellow)
                    .font(.system(size: 18))
                Text("Featured reward")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 16)

            if let featured = featured {
                let imageName = featured.partner.name
                    .lowercased()
                    .replacingOccurrences(of: " ", with: "_")
                    .replacingOccurrences(of: "'", with: "")

                NavigationLink(destination: PartnerDetailView(partner: featured.partner)) {
                    HStack(spacing: 0) {
                        ZStack {
                            Rectangle().fill(Color.gray.opacity(0.2))
                            Image(imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                        .frame(width: 120, height: 100)
                        .clipped()
                        .cornerRadius(12, corners: [.topLeft, .bottomLeft])

                        VStack(alignment: .leading, spacing: 8) {
                            Text(featured.partner.name.uppercased())
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.black)
                                .lineLimit(1)
                            Text(featured.reward.name.uppercased())
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.black)
                            HStack(spacing: 6) {
                                Image("SykleLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                Text("\(featured.reward.syklesCost) sykles")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .overlay(Capsule().stroke(Color.gray.opacity(0.4), lineWidth: 1))
                        }
                        .padding(.horizontal, 16)
                        Spacer()
                    }
                    .frame(height: 100)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
// MARK: - Horizontal Partner Row (Looping)

struct HomePartnerRow: View {
    let title: String
    let partners: [FakePartner]
    let filterTitle: String

    // Multiply partners to create infinite loop illusion
    private var loopedPartners: [LoopedPartner] {
        guard !partners.isEmpty else { return [] }
        // Repeat 3 times so user can scroll in either direction
        return (0..<3).flatMap { cycle in
            partners.map { LoopedPartner(id: "\(cycle)-\($0.id)", partner: $0) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                NavigationLink(destination: FilteredPartnersView(title: title, partners: partners)) {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.black)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .padding(.horizontal, 16)

            LoopingCarousel(items: loopedPartners, startIndex: partners.count)
        }
    }
}

// MARK: - Looped Partner wrapper (unique ID per loop cycle)

struct LoopedPartner: Identifiable {
    let id: String
    let partner: FakePartner
}

// MARK: - Looping Carousel

struct LoopingCarousel: View {
    let items: [LoopedPartner]
    let startIndex: Int

    @State private var scrollOffset: CGFloat = 0
    private let cardWidth: CGFloat = 160
    private let cardSpacing: CGFloat = 12

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: cardSpacing) {
                    ForEach(items) { item in
                        NavigationLink(destination: PartnerDetailView(partner: item.partner)) {
                            HomePartnerCard(partner: item.partner)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .id(item.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            }
            .onAppear {
                // Start in the middle copy so user can scroll both ways
                if startIndex < items.count {
                    proxy.scrollTo(items[startIndex].id, anchor: .leading)
                }
            }
        }
    }
}

// MARK: - Home Partner Card

struct HomePartnerCard: View {
    let partner: FakePartner

    private var imageName: String {
        partner.name.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "'", with: "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Rectangle().fill(Color.gray.opacity(0.15))
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .frame(width: 160, height: 130)
            .clipped()
            .cornerRadius(12)

            Text(partner.name.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.black)
                .lineLimit(1)
                .frame(width: 160, alignment: .leading)

            Text(partner.distanceMiles)
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .frame(width: 160, alignment: .leading)

            HStack(spacing: 6) {
                Text("\(partner.syklersVisited) syklers visited")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 7).padding(.vertical, 4)
                    .background(Color.sykleLight)
                    .cornerRadius(20)

                Text(partner.isOpen ? "Open" : "Closed")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 7).padding(.vertical, 4)
                    .background(partner.isOpen ? Color.sykleGreen : Color.syklePink)
                    .cornerRadius(20)
            }
            .frame(width: 160, alignment: .leading)
        }
    }
}

// MARK: - Corner Radius Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    HomeView()
        .environmentObject(HealthKitManager())
}

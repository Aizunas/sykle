//
//  FavouritesView.swift
//  Sykle
//

import SwiftUI

// MARK: - Favourites Manager
@MainActor
class FavouritesManager: ObservableObject {
    static let shared = FavouritesManager()

    @Published var favourites: [FakePartner] = []

    private let key = "sykle_favourites"

    init() {
        load()
    }

    func toggle(_ partner: FakePartner) {
        if isFavourite(partner) {
            favourites.removeAll { $0.name == partner.name }
        } else {
            favourites.append(partner)
        }
        persist()
    }

    func isFavourite(_ partner: FakePartner) -> Bool {
        favourites.contains { $0.name == partner.name }
    }

    private func persist() {
        // Save partner names — we reload full data from PartnerStore
        let names = favourites.map { $0.name }
        UserDefaults.standard.set(names, forKey: key)
    }

    func load() {
        guard let names = UserDefaults.standard.stringArray(forKey: key) else { return }
        // Reconstruct FakePartner objects from PartnerStore or fallback to fakePartners
        let store = PartnerStore.shared
        favourites = names.compactMap { name in
            store.partners.first { $0.name == name } ?? fakePartners.first { $0.name == name }
        }
    }
    
    // Call this after PartnerStore loads to refresh with API data
    func refreshFromStore() {
        let names = favourites.map { $0.name }
        let store = PartnerStore.shared
        favourites = names.compactMap { name in
            store.partners.first { $0.name == name }
        }
    }
}

// MARK: - FavouritesView

struct FavouritesView: View {
    @ObservedObject private var favourites = FavouritesManager.shared
    @ObservedObject private var partnerStore = PartnerStore.shared
    @State private var showingBasket = false

    let sykleYellow = Color(hex: "FED903")

    var body: some View {
        Group {
            if favourites.favourites.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "star")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.4))
                    Text("No favourites yet")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    Text("Tap the star on any partner to save it here.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(favourites.favourites) { partner in
                            NavigationLink(destination: PartnerDetailView(partner: partner, cameFromFavourites: true)) {
                                FavouriteCard(partner: partner)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text("Favourites")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .fixedSize()
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Image(systemName: "star.fill")
                    .foregroundColor(sykleYellow)
                    .font(.system(size: 20))
                Button(action: { showingBasket = true }) {
                    Image(systemName: "cart")
                        .foregroundColor(.black)
                        .font(.system(size: 20))
                }
            }
        }
        .sheet(isPresented: $showingBasket) {
            BasketView()
        }
        .task {
            if !partnerStore.hasLoaded {
                await partnerStore.loadPartners()
            }
        }
    }
}

// MARK: - Favourite Card

struct FavouriteCard: View {
    let partner: FakePartner
    @ObservedObject private var favourites = FavouritesManager.shared

    let sykleYellow = Color(hex: "FED903")

    private var imageName: String {
        partner.name.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "'", with: "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Hero image with star overlay
            ZStack(alignment: .bottomTrailing) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 160)
                    .overlay(
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                    )
                    .clipped()
                    .cornerRadius(12, corners: [.topLeft, .topRight])

                Button(action: { favourites.toggle(partner) }) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 22))
                        .foregroundColor(sykleYellow)
                        .padding(12)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(partner.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                Text(partner.distanceMiles)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)

                HStack(spacing: 8) {
                    Text("\(partner.syklersVisited) syklers visited")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.sykleLight)
                        .cornerRadius(20)

                    Text(partner.isOpen ? "Open" : "Closed")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(partner.isOpen ? Color.sykleGreen : Color.syklePink)
                        .cornerRadius(20)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.white)
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Reusable Star Button

struct FavouriteStarButton: View {
    let partner: FakePartner
    @ObservedObject private var favourites = FavouritesManager.shared

    let sykleYellow = Color(hex: "FED903")

    var body: some View {
        Button(action: { favourites.toggle(partner) }) {
            Image(systemName: favourites.isFavourite(partner) ? "star.fill" : "star")
                .foregroundColor(favourites.isFavourite(partner) ? sykleYellow : .black)
                .font(.system(size: 20))
        }
    }
}

#Preview {
    NavigationView {
        FavouritesView()
    }
}

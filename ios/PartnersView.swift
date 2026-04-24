//
//  PartnersView.swift
//  Sykle
//
//  Displays partner cafes fetched from the backend API
//

import SwiftUI

struct PartnersView: View {
    @StateObject private var viewModel = PartnersViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    // Loading state
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading partners...")
                            .foregroundColor(.gray)
                    }
                } else if let error = viewModel.errorMessage {
                    // Error state
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("Couldn't load partners")
                            .font(.system(size: 18, weight: .medium))
                        
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button("Try Again") {
                            viewModel.loadPartners()
                        }
                        .foregroundColor(Color("SykleBlue"))
                        .padding(.top, 8)
                    }
                } else if viewModel.partners.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "cup.and.saucer")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No partners yet")
                            .font(.system(size: 18, weight: .medium))
                        
                        Text("Partner cafes will appear here")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                } else {
                    // Partners list
                    ScrollView {
                        VStack(spacing: 16) {
                            // Header
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Redeem your sykles")
                                        .font(.system(size: 24, weight: .bold))
                                    Text("\(viewModel.partners.count) partner locations")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            
                            // Partner cards
                            ForEach(viewModel.partners) { partner in
                                NavigationLink(value: partner) {
                                    PartnerCard(partner: partner)
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Partners")
            .navigationDestination(for: APIPartner.self) { apiPartner in
                // Map APIPartner to FakePartner so it works with the new PartnerDetailView
                let fake = fakePartners.first { $0.name == apiPartner.name }
                    ?? FakePartner(
                        name: apiPartner.name,
                        category: apiPartner.category ?? "Coffee",
                        address: apiPartner.address ?? "",
                        coordinate: .init(latitude: apiPartner.latitude ?? 51.5228,
                                          longitude: apiPartner.longitude ?? -0.0755),
                        openHours: "9:00 AM – 6:00 PM",
                        pointsCost: 100,
                        reward: "Reward",
                        distanceMiles: "Nearby",
                        syklersVisited: "5+",
                        weeklyHours: [
                            1: DayHours(open: "09:00", close: "18:00"),
                            2: DayHours(open: "09:00", close: "18:00"),
                            3: DayHours(open: "09:00", close: "18:00"),
                            4: DayHours(open: "09:00", close: "18:00"),
                            5: DayHours(open: "09:00", close: "18:00"),
                            6: DayHours(open: "09:00", close: "18:00"),
                            7: DayHours(open: "09:00", close: "18:00")
                        ]
                    )
                PartnerDetailView(partner: fake)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.loadPartners()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                if viewModel.partners.isEmpty {
                    viewModel.loadPartners()
                }
            }
        }
    }
}

// MARK: - Partners ViewModel

class PartnersViewModel: ObservableObject {
    @Published var partners: [APIPartner] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager.shared
    
    func loadPartners() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedPartners = try await networkManager.getPartners()
                
                await MainActor.run {
                    self.partners = fetchedPartners
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Partner Card

struct PartnerCard: View {
    let partner: APIPartner
    
    var body: some View {
        HStack(spacing: 16) {
            // Placeholder image
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("SykleBlue").opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 30))
                    .foregroundColor(Color("SykleBlue"))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(partner.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                if let description = partner.description {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                HStack(spacing: 12) {
                    // Rewards count
                    if let count = partner.rewardCount {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text("\(count) rewards")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Distance (if available)
                    if let distance = partner.distanceDisplay {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color("SykleBlue"))
                            Text(distance)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Preview

struct PartnersView_Previews: PreviewProvider {
    static var previews: some View {
        PartnersView()
    }
}

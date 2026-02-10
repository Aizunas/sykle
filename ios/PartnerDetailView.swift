//
//  PartnerDetailView.swift
//  Sykle
//
//  Shows partner details and their available rewards
//

import SwiftUI

struct PartnerDetailView: View {
    let partnerId: String
    
    @StateObject private var viewModel = PartnerDetailViewModel()
    @StateObject private var userManager = UserManager.shared
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    ProgressView()
                    Text("Loading...")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
            } else if let partner = viewModel.partner {
                ScrollView {
                    VStack(spacing: 24) {
                        // Partner Header
                        PartnerHeader(partner: partner)
                        
                        // Points Balance
                        PointsBalanceMini(points: userManager.serverPoints)
                        
                        // Rewards Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Available Rewards")
                                .font(.system(size: 20, weight: .bold))
                                .padding(.horizontal)
                            
                            if viewModel.rewards.isEmpty {
                                Text("No rewards available at this location")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                            } else {
                                ForEach(viewModel.rewards) { reward in
                                    RewardCard(
                                        reward: reward,
                                        userPoints: userManager.serverPoints,
                                        onRedeem: {
                                            viewModel.redeemReward(reward: reward, userId: userManager.currentUser?.id)
                                        }
                                    )
                                }
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text(error)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Try Again") {
                        viewModel.loadPartner(id: partnerId)
                    }
                }
            }
        }
        .navigationTitle(viewModel.partner?.name ?? "Partner")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground))
        .alert("Reward Redeemed!", isPresented: $viewModel.showRedemptionSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            if let qrCode = viewModel.redemptionQRCode {
                Text("Your code: \(qrCode)\n\nShow this to the staff within 15 minutes.")
            }
        }
        .alert("Error", isPresented: $viewModel.showRedemptionError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.redemptionErrorMessage ?? "Something went wrong")
        }
        .onAppear {
            viewModel.loadPartner(id: partnerId)
        }
    }
}

// MARK: - Partner Detail ViewModel

class PartnerDetailViewModel: ObservableObject {
    @Published var partner: APIPartner?
    @Published var rewards: [APIReward] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Redemption state
    @Published var showRedemptionSuccess = false
    @Published var showRedemptionError = false
    @Published var redemptionQRCode: String?
    @Published var redemptionErrorMessage: String?
    
    private let networkManager = NetworkManager.shared
    
    func loadPartner(id: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await networkManager.getPartner(id: id)
                
                await MainActor.run {
                    self.partner = response.partner
                    self.rewards = response.rewards
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
    
    func redeemReward(reward: APIReward, userId: String?) {
        guard let userId = userId else {
            redemptionErrorMessage = "Please sign in first"
            showRedemptionError = true
            return
        }
        
        Task {
            do {
                let response = try await networkManager.redeemReward(
                    userId: userId,
                    rewardId: reward.id
                )
                
                await MainActor.run {
                    self.redemptionQRCode = response.redemption.qrCode
                    self.showRedemptionSuccess = true
                    
                    // Refresh user data to update points
                    Task {
                        await UserManager.shared.refreshUser()
                    }
                }
            } catch {
                await MainActor.run {
                    self.redemptionErrorMessage = error.localizedDescription
                    self.showRedemptionError = true
                }
            }
        }
    }
}

// MARK: - Partner Header

struct PartnerHeader: View {
    let partner: APIPartner
    
    var body: some View {
        VStack(spacing: 16) {
            // Image placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("SykleBlue").opacity(0.1))
                    .frame(height: 150)
                
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color("SykleBlue"))
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                Text(partner.name)
                    .font(.system(size: 24, weight: .bold))
                
                if let description = partner.description {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                if let address = partner.address {
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color("SykleBlue"))
                        Text(address)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Points Balance Mini

struct PointsBalanceMini: View {
    let points: Int
    
    var body: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
            
            Text("You have")
                .foregroundColor(.white.opacity(0.8))
            
            Text("\(points) sykles")
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("to spend")
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color("SykleBlue"))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Reward Card

struct RewardCard: View {
    let reward: APIReward
    let userPoints: Int
    let onRedeem: () -> Void
    
    var canAfford: Bool {
        userPoints >= reward.pointsCost
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(canAfford ? Color("SykleBlue").opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "gift.fill")
                    .font(.system(size: 20))
                    .foregroundColor(canAfford ? Color("SykleBlue") : .gray)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(canAfford ? .primary : .gray)
                
                if let description = reward.description {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    Text("\(reward.pointsCost) sykles")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(canAfford ? Color("SykleBlue") : .gray)
                }
            }
            
            Spacer()
            
            // Redeem button
            Button(action: onRedeem) {
                Text(canAfford ? "Redeem" : "Need \(reward.pointsCost - userPoints) more")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(canAfford ? .white : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(canAfford ? Color("SykleBlue") : Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            .disabled(!canAfford)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .opacity(canAfford ? 1.0 : 0.7)
        .padding(.horizontal)
    }
}

// MARK: - Preview

struct PartnerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PartnerDetailView(partnerId: "partner-1")
        }
    }
}

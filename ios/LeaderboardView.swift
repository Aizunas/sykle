//
//  LeaderboardView.swift
//  Sykle
//

import SwiftUI

struct LeaderboardView: View {
    @StateObject private var userManager = UserManager.shared
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)
    let cardBlue = Color(red: 173/255, green: 210/255, blue: 235/255)

    var currentUserEntry: LeaderboardEntry? {
        entries.first { $0.id == userManager.currentUser?.id }
    }

    var top3: [LeaderboardEntry] { Array(entries.prefix(3)) }
    var rest: [LeaderboardEntry] { Array(entries.dropFirst(3)) }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    Text("Leaderboard")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(cardBlue)
                        .cornerRadius(14)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 24)

                    if isLoading {
                        ProgressView()
                            .padding(.top, 60)
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.gray)
                            .padding(.top, 60)
                    } else {
                        // Top 3 podium
                        if top3.count >= 1 {
                            PodiumView(entries: top3, cardBlue: cardBlue, sykleBlue: sykleBlue)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)
                        }

                        // Current user card
                        if let me = currentUserEntry {
                            CurrentUserCard(entry: me, sykleBlue: sykleBlue)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                        }

                        // Rest of leaderboard
                        VStack(spacing: 0) {
                            ForEach(rest) { entry in
                                LeaderboardRow(entry: entry, sykleBlue: sykleBlue, isCurrentUser: entry.id == userManager.currentUser?.id)
                                if entry.rank != entries.last?.rank {
                                    Divider().padding(.leading, 72)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("sykle.")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(sykleBlue)
                        .fixedSize()
                }
            }
            .task {
                await loadLeaderboard()
            }
            .refreshable {
                await loadLeaderboard()
            }
        }
    }

    private func loadLeaderboard() async {
        isLoading = true
        do {
            entries = try await NetworkManager.shared.getLeaderboard()
        } catch {
            print("❌ Leaderboard error: \(error)")
            errorMessage = "Couldn't load leaderboard"
        }
        isLoading = false
    }
}

// MARK: - Podium

struct PodiumView: View {
    let entries: [LeaderboardEntry]
    let cardBlue: Color
    let sykleBlue: Color

    var first: LeaderboardEntry? { entries.first { $0.rank == 1 } }
    var second: LeaderboardEntry? { entries.first { $0.rank == 2 } }
    var third: LeaderboardEntry? { entries.first { $0.rank == 3 } }

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // 2nd place
            if let second = second {
                PodiumColumn(entry: second, height: 120, cardBlue: cardBlue)
            }
            // 1st place
            if let first = first {
                PodiumColumn(entry: first, height: 160, cardBlue: cardBlue)
            }
            // 3rd place
            if let third = third {
                PodiumColumn(entry: third, height: 90, cardBlue: cardBlue)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct PodiumColumn: View {
    let entry: LeaderboardEntry
    let height: CGFloat
    let cardBlue: Color

    var body: some View {
        VStack(spacing: 6) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(cardBlue.opacity(0.5))
                    .frame(width: 60, height: 60)
                Text(entry.initials)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(entry.shortName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black)

            HStack(spacing: 4) {
                Image("SykleLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                Text(entry.co2Display)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }

            // Podium block
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(cardBlue)
                    .frame(height: height)
                Text("\(entry.rank)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Current User Card

struct CurrentUserCard: View {
    let entry: LeaderboardEntry
    let sykleBlue: Color

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 56, height: 56)
                    Text(entry.initials)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                Text(entry.shortName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Position")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                Text("\(entry.rank)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("CO₂ saved")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                Text(entry.co2Display)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(20)
        .background(sykleBlue)
        .cornerRadius(16)
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let sykleBlue: Color
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 16) {
            Text(String(format: "%02d", entry.rank))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(sykleBlue)
                .frame(width: 36)

            ZStack {
                Circle()
                    .fill(Color(red: 173/255, green: 210/255, blue: 235/255).opacity(0.4))
                    .frame(width: 40, height: 40)
                Text(entry.initials)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(sykleBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.shortName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)
                HStack(spacing: 4) {
                    Image("SykleLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                    Text(entry.co2Display)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            if isCurrentUser {
                Image(systemName: "star.fill")
                    .foregroundColor(Color(red: 254/255, green: 217/255, blue: 3/255))
                    .font(.system(size: 18))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isCurrentUser ? Color(red: 173/255, green: 210/255, blue: 235/255).opacity(0.15) : Color.white)
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(HealthKitManager())
}

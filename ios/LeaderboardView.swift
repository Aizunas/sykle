//
//  LeaderboardView.swift
//  Sykle
//
//  Placeholder — leaderboard feature coming soon
//

import SwiftUI

struct LeaderboardView: View {
    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)
    let sykleYellow = Color(red: 254/255, green: 217/255, blue: 3/255)

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(sykleYellow)

                Text("Leaderboard")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)

                Text("See how you rank against other syklers in your area. Coming soon.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("sykle.")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(sykleBlue)
                        .fixedSize()
                }
            }
        }
    }
}

#Preview {
    LeaderboardView()
}

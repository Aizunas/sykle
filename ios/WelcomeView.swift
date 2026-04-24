//
//  WelcomeView.swift
//  Sykle
//
//  Welcome screen with rotating partner logos
//

import SwiftUI

struct WelcomeView: View {
    let onComplete: () -> Void

    @State private var rotation: Double = 0
    @State private var showSyncHealth = false

    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    let partnerLogos = [
        "partner_nona",
        "partner_fifthsip",
        "partner_sando",
        "partner_bb",
        "partner_bloom",
        "partner_croissant",
        "partner_knotts",
        "partner_yummy"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Welcome to sykle.
            VStack(alignment: .leading, spacing: 0) {
                Text("Welcome to")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.black)
                Text("sykle.")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(sykleBlue)
            }
            .padding(.top, 24)

            // Description
            Text("Start earning points with every ride and use them to save at hundreds of partners across your area!")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.black)
                .padding(.top, 16)

            Spacer()

            // Rotating partner logos
            ZStack {
                ForEach(0..<partnerLogos.count, id: \.self) { index in
                    let angle = (Double(index) / Double(partnerLogos.count)) * 360 + rotation
                    let radius: CGFloat = 120

                    Image(partnerLogos[index])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: logoSize(for: index), height: logoSize(for: index))
                        .clipShape(Circle())
                        .offset(
                            x: CGFloat(cos(angle * .pi / 180)) * radius,
                            y: CGFloat(sin(angle * .pi / 180)) * radius
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .onReceive(timer) { _ in
                rotation += 0.3
            }

            Spacer()

            // Continue button
            Button(action: {
                showSyncHealth = true
            }) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(sykleBlue)
                    .cornerRadius(30)
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
        .background(Color.white)
        .fullScreenCover(isPresented: $showSyncHealth) {
            SyncHealthView(onComplete: onComplete)
        }
    }

    private func logoSize(for index: Int) -> CGFloat {
        let sizes: [CGFloat] = [70, 65, 70, 60, 75, 55, 70, 60]
        return sizes[index % sizes.count]
    }
}

#Preview {
    WelcomeView(onComplete: {})
}

//
//  PastOrdersView.swift
//  Sykle
//

import SwiftUI

struct PastOrdersView: View {
    @ObservedObject private var voucherStore = VoucherStore.shared
    @State private var selectedVoucher: SavedVoucher? = nil

    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)

    var expiredVouchers: [SavedVoucher] {
        voucherStore.pastVouchers
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                if expiredVouchers.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.4))
                        Text("No past orders")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                        Text("Your redeemed vouchers will appear here.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    ForEach(expiredVouchers) { voucher in
                        PastOrderCard(voucher: voucher)
                            .onTapGesture { selectedVoucher = voucher }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Past orders")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedVoucher) { voucher in
            let imageName = voucher.partnerName
                .lowercased()
                .replacingOccurrences(of: " ", with: "_")
            VoucherView(voucher: voucher, partnerImageName: imageName)
        }
    }
}

// MARK: - Past Order Card

struct PastOrderCard: View {
    let voucher: SavedVoucher
    let cardBlue = Color(red: 173/255, green: 210/255, blue: 235/255)

    private var imageName: String {
        voucher.partnerName.lowercased().replacingOccurrences(of: " ", with: "_")
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Rectangle().fill(Color.gray.opacity(0.15))
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .frame(width: 64, height: 64)
            .clipped()
            .cornerRadius(10)
            .opacity(0.5)

            VStack(alignment: .leading, spacing: 4) {
                Text(voucher.partnerName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.gray)
                Text(voucher.voucherCode)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
                HStack(spacing: 6) {
                    Text("Expired")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(20)
                    Text("\(voucher.totalSykles) sykles")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                Text(voucher.redeemedOnString)
                    .font(.system(size: 11))
                    .foregroundColor(.gray.opacity(0.7))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

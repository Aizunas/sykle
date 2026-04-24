//
//  WalletView.swift
//  Sykle
//
//  Apple Wallet-style view showing all vouchers
//

import SwiftUI

struct WalletView: View {
    @ObservedObject private var voucherStore = VoucherStore.shared
    @State private var selectedVoucher: SavedVoucher? = nil

    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: Active vouchers
                    if !voucherStore.activeVouchers.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Active")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)

                            ForEach(voucherStore.activeVouchers) { voucher in
                                WalletVoucherCard(voucher: voucher, isActive: true)
                                    .onTapGesture { selectedVoucher = voucher }
                            }
                        }
                    }

                    // MARK: Past vouchers
                    if !voucherStore.pastVouchers.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Past vouchers")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)

                            ForEach(voucherStore.pastVouchers) { voucher in
                                WalletVoucherCard(voucher: voucher, isActive: false)
                                    .onTapGesture { selectedVoucher = voucher }
                            }
                        }
                    }

                    // MARK: Empty state
                    if voucherStore.vouchers.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "wallet.pass")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.4))
                            Text("No vouchers yet")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                            Text("Redeem your sykles at a partner to generate a voucher.")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    }

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Wallet")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .fixedSize()
                }
            }
            .sheet(item: $selectedVoucher) { voucher in
                let imageName = voucher.partnerName
                    .lowercased()
                    .replacingOccurrences(of: " ", with: "_")
                VoucherView(voucher: voucher, partnerImageName: imageName)
            }
        }
    }
}

// MARK: - Wallet Voucher Card

struct WalletVoucherCard: View {
    let voucher: SavedVoucher
    let isActive: Bool

    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)
    let cardBlue  = Color(red: 173/255, green: 210/255, blue: 235/255)

    private var imageName: String {
        voucher.partnerName
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
    }

    var body: some View {
        HStack(spacing: 14) {
            // Partner image
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .frame(width: 64, height: 64)
            .clipped()
            .cornerRadius(10)
            .opacity(isActive ? 1 : 0.5)

            VStack(alignment: .leading, spacing: 4) {
                Text(voucher.partnerName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isActive ? .black : .gray)

                Text(voucher.voucherCode)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)

                HStack(spacing: 6) {
                    Text(isActive ? "Active" : "Used")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(isActive ? cardBlue : Color.gray.opacity(0.2))
                        .cornerRadius(20)

                    Text("\(voucher.totalSykles) sykles")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
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

#Preview {
    WalletView()
}

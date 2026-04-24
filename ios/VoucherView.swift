//
//  VoucherView.swift
//  Sykle
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct VoucherView: View {
    let voucher: SavedVoucher
    let partnerImageName: String
    var onDismiss: (() -> Void)? = nil

    @Environment(\.dismiss) var dismiss
    @ObservedObject private var basket = BasketManager.shared
    @State private var logoRotation = 0.0

    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)
    let bgGray    = Color(red: 242/255, green: 240/255, blue: 237/255)

    var qrImage: UIImage {
        generateQRCode(from: voucher.voucherCode)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // Active voucher badge
                    HStack(spacing: 12) {
                        Image("SykleLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .rotationEffect(.degrees(logoRotation))
                            .onAppear {
                                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                                    logoRotation = 360
                                }
                            }

                        Text(voucher.isExpired ? "✕  Expired voucher" : "✓  Active voucher")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(voucher.isExpired
                                ? Color.gray.opacity(0.2)
                                : Color(red: 173/255, green: 210/255, blue: 235/255))
                            .cornerRadius(20)
                    }
                    .padding(.top, 8)

                    // Partner card
                    VStack(spacing: 12) {
                        ForEach(voucher.partners, id: \.self) { partner in
                            VStack(alignment: .leading, spacing: 0) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 140)
                                    .overlay(
                                        Image(partner.imageName)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .clipped()
                                    )
                                    .clipped()
                                    .cornerRadius(12, corners: [.topLeft, .topRight])

                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(partner.name)
                                                .font(.system(size: 18, weight: .bold))
                                            Spacer()
                                            Text(partner.distanceMiles)
                                                .font(.system(size: 13))
                                                .foregroundColor(.gray)
                                        }
                                        // You can't compute timeUntilClose from just the name/distance here
                                        // since VoucherPartner doesn't store hours — show a generic badge
                                        Text("Active")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 12).padding(.vertical, 5)
                                            .background(Color.syklePink)
                                            .cornerRadius(20)
                                    }
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
                            }
                            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                        }
                    }
                    // QR code card
                    VStack(spacing: 16) {
                        Text("Show this QR code")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)

                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .padding(16)
                            .background(Color(red: 173/255, green: 210/255, blue: 235/255).opacity(0.4))
                            .cornerRadius(12)

                        Text(voucher.voucherCode)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)

                        VStack(spacing: 0) {
                            VoucherDetailRow(
                                label: "Points redeemed",
                                value: "\(voucher.totalSykles) sykles",
                                showLogo: true
                            )
                            Divider().padding(.horizontal, 16)
                            VoucherDetailRow(label: "Valid until",    value: voucher.validUntilString)
                            Divider().padding(.horizontal, 16)
                            VoucherDetailRow(label: "Redeemed on",   value: voucher.redeemedOnString)
                            Divider().padding(.horizontal, 16)
                            VoucherDetailRow(label: "Transaction ID", value: voucher.transactionId)
                        }
                        .background(bgGray)
                        .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)

                    // Expiry warning
                    if !voucher.isExpired {
                        HStack(spacing: 14) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Expires in 15 minutes")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.black)
                                Text("Make sure to redeem before \(voucher.validUntilString)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.gray.opacity(0.12))
                        .cornerRadius(16)
                    }

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
            }
            .background(bgGray.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Voucher")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .fixedSize()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Clear basket when closing — voucher already saved in VoucherStore
                        basket.clear()
                        dismiss()
                        onDismiss?()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                    }
                }
            }
        }
    }

    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        if let outputImage = filter.outputImage {
            let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
            if let cgImage = context.createCGImage(scaled, from: scaled.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return UIImage(systemName: "qrcode") ?? UIImage()
    }
}

// MARK: - Voucher Detail Row

struct VoucherDetailRow: View {
    let label: String
    let value: String
    var showLogo: Bool = false
    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.gray)
            Spacer()
            if showLogo {
                HStack(spacing: 6) {
                    Image("SykleLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text(value)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .overlay(Capsule().stroke(sykleBlue, lineWidth: 1))
            } else {
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

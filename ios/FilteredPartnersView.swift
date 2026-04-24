//
//  FilteredPartnersView.swift
//  Sykle
//

import SwiftUI

struct FilteredPartnersView: View {
    let title: String
    let partners: [FakePartner]  // receives the exact same list from the carousel

    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)

    // Deduplicate by name so repeated partners show only once in the list
    var uniquePartners: [FakePartner] {
        var seen = Set<String>()
        return partners.filter { seen.insert($0.name).inserted }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack {
                    Text("\(uniquePartners.count) locations")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                ForEach(uniquePartners) { partner in
                    NavigationLink(destination: PartnerDetailView(partner: partner)) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 64, height: 64)
                                Image(partner.name.lowercased()
                                    .replacingOccurrences(of: " ", with: "_")
                                    .replacingOccurrences(of: "'", with: ""))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(partner.name)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.black)
                                Text(partner.address)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)

                                HStack(spacing: 6) {
                                    Text("\(partner.syklersVisited) syklers visited")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(Color(red: 210/255, green: 225/255, blue: 245/255))
                                        .cornerRadius(20)

                                    Text(partner.isOpen ? "Open" : "Closed")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(partner.isOpen
                                            ? Color(red: 180/255, green: 230/255, blue: 180/255)
                                            : Color(red: 255/255, green: 180/255, blue: 180/255))
                                        .cornerRadius(20)
                                }

                                Text(partner.distanceMiles)
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
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
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FilteredPartnersView(title: "Coffee shops nearby", partners: fakePartners)
    }
}

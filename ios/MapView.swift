//
//  MapView.swift
//  Sykle
//

import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject private var partnerStore = PartnerStore.shared
    @StateObject private var locationManager = LocationManager.shared

    @State private var region = MKCoordinateRegion(
        center: LocationManager.shared.userLocation ?? CLLocationCoordinate2D(latitude: 51.5255, longitude: -0.0755),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @State private var selectedPartner: FakePartner? = nil
    @State private var navigateToPartner: FakePartner? = nil
    @State private var showList = false
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var filters = FilterOptions.load()

    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)

    var filteredPartners: [FakePartner] {
        var result = partnerStore.partners
        if !filters.showClosed {
            result = result.filter { $0.isOpen }
        }
        result = result.filter { $0.distanceMilesValue <= filters.maxDistanceMiles }
        if filters.showDrinks || filters.showFood {
            result = result.filter {
                (filters.showDrinks && $0.category == "Coffee") ||
                (filters.showFood   && $0.category == "Bakery")
            }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.reward.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        switch filters.sortBy {
        case .distance: result = result.sorted { $0.distanceMiles < $1.distanceMiles }
        case .newest:   result = result.reversed()
        case .featured: break
        }
        return result
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    if showSearch {
                        HStack {
                            HStack {
                                TextField("Search partners or rewards...", text: $searchText)
                                    .font(.system(size: 15))
                                    .autocorrectionDisabled()
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                } else {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.systemGroupedBackground))
                    }

                    // ← Key change: use MapContainerView instead of inline Map
                    MapContainerView(
                        filteredPartners: filteredPartners,
                        region: $region,
                        selectedPartner: $selectedPartner,
                        navigateToPartner: $navigateToPartner,
                        showList: showList
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("sykle.")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(sykleBlue)
                        .fixedSize()
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showFilters = true }) {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                    }
                    HStack(spacing: 0) {
                        Button(action: {
                            withAnimation { showList = false; showSearch = false; searchText = "" }
                        }) {
                            Text("Map")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(!showList ? .white : .black)
                                .padding(.horizontal, 14).padding(.vertical, 7)
                                .background(!showList ? sykleBlue : Color.clear)
                                .cornerRadius(20)
                        }
                        Button(action: { withAnimation { showList = true } }) {
                            Text("List")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(showList ? .white : .black)
                                .padding(.horizontal, 14).padding(.vertical, 7)
                                .background(showList ? sykleBlue : Color.clear)
                                .cornerRadius(20)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSearch.toggle()
                            if !showSearch { searchText = "" }
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                            .padding(8)
                            .background(showSearch ? sykleBlue.opacity(0.1) : Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet(filters: $filters, isPresented: $showFilters)
            }
            .task {
                if !partnerStore.hasLoaded {
                    await partnerStore.loadPartners()
                }
            }
            .onAppear {
                guard let location = locationManager.userLocation else { return }
                region = MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
                partnerStore.repositionPartners(around: location)
            }
            .onChange(of: locationManager.userLocation?.latitude) { _, _ in
                guard let location = locationManager.userLocation else { return }
                region = MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
                partnerStore.repositionPartners(around: location)
            }
        }
    }
}

// MARK: - Map Container

struct MapContainerView: View {
    let filteredPartners: [FakePartner]
    @Binding var region: MKCoordinateRegion
    @Binding var selectedPartner: FakePartner?
    @Binding var navigateToPartner: FakePartner?
    let showList: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            if showList {
                PartnerListView(partners: filteredPartners)
            } else {
                PartnerMapView(
                    region: $region,
                    partners: filteredPartners,
                    selectedPartner: $selectedPartner
                )

                if let partner = selectedPartner {
                    NavigationLink(
                        destination: PartnerDetailView(partner: partner),
                        isActive: Binding(
                            get: { navigateToPartner?.id == partner.id },
                            set: { if !$0 { navigateToPartner = nil } }
                        )
                    ) { EmptyView() }

                    PartnerMapCard(partner: partner, onDismiss: {
                        withAnimation { selectedPartner = nil }
                    }, onTap: {
                        navigateToPartner = partner
                    })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
}

// MARK: - Partner Map View

struct PartnerMapView: View {
    @Binding var region: MKCoordinateRegion
    let partners: [FakePartner]
    @Binding var selectedPartner: FakePartner?

    var body: some View {
        Map(coordinateRegion: $region,
            showsUserLocation: true,
            annotationItems: partners) { partner in
            MapAnnotation(coordinate: partner.coordinate) {
                PartnerMapPin(
                    partner: partner,
                    isSelected: selectedPartner?.id == partner.id
                )
                .onTapGesture {
                    withAnimation(.spring()) {
                        selectedPartner = partner
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Partner List View

struct PartnerListView: View {
    let partners: [FakePartner]
    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(partners) { partner in
                    NavigationLink(destination: PartnerDetailView(partner: partner)) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 64, height: 64)
                                Image(partner.name.lowercased().replacingOccurrences(of: " ", with: "_"))
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
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Map Pin

struct PartnerMapPin: View {
    let partner: FakePartner
    let isSelected: Bool
    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isSelected ? sykleBlue : Color.white)
                    .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                Image(systemName: partner.category == "Bakery"
                      ? "birthday.cake.fill" : "cup.and.saucer.fill")
                    .font(.system(size: isSelected ? 18 : 14))
                    .foregroundColor(isSelected ? .white : sykleBlue)
            }
            Triangle()
                .fill(isSelected ? sykleBlue : Color.white)
                .frame(width: 10, height: 6)
        }
        .animation(.spring(), value: isSelected)
    }
}

// MARK: - Triangle

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Partner Map Card

struct PartnerMapCard: View {
    let partner: FakePartner
    let onDismiss: () -> Void
    let onTap: () -> Void
    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(partner.name)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                        Text(partner.address)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(7)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                HStack(spacing: 8) {
                    Text("\(partner.syklersVisited) syklers visited")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color(red: 210/255, green: 225/255, blue: 245/255))
                        .cornerRadius(20)
                    Text(partner.isOpen ? "Open" : "Closed")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(partner.isOpen
                            ? Color(red: 180/255, green: 230/255, blue: 180/255)
                            : Color(red: 255/255, green: 180/255, blue: 180/255))
                        .cornerRadius(20)
                    Spacer()
                    Text(partner.distanceMiles)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}

// MARK: - Filter Options Persistence

extension FilterOptions {
    private static let key = "sykle_filter_options"

    static func load() -> FilterOptions {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(FilterOptions.self, from: data)
        else { return FilterOptions() }
        return decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }
}

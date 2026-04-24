//
//  FilterSheet.swift
//  Sykle
//

import SwiftUI

// MARK: - Filter State

struct FilterOptions: Codable {
    var showClosed: Bool = false
    var sortBy: SortOption = .featured
    var maxDistanceMiles: Double = 2.0
    var showDrinks: Bool = false
    var showFood: Bool = false
}

enum SortOption: String, CaseIterable, Codable {
    case featured = "Featured"
    case distance = "Distance"
    case newest   = "Newest"
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Binding var filters: FilterOptions
    @Binding var isPresented: Bool

    @State private var local: FilterOptions

    let sykleBlue   = Color.sykleMid
    let sykleYellow = Color(hex: "FED903")
    let bgGray      = Color.sykleCream

    init(filters: Binding<FilterOptions>, isPresented: Binding<Bool>) {
        self._filters     = filters
        self._isPresented = isPresented
        self._local       = State(initialValue: filters.wrappedValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack {
                Text("Filters")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 28)

            // Show closed toggle
            HStack {
                Text("Show closed")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                Spacer()
                Toggle("", isOn: $local.showClosed)
                    .labelsHidden()
                    .tint(sykleBlue)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)

            // Sort by
            VStack(alignment: .leading, spacing: 14) {
                Text("Sort by")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)

                HStack(spacing: 0) {
                    ForEach(Array(SortOption.allCases.enumerated()), id: \.element) { index, option in
                        let isSelected = local.sortBy == option
                        let isLast = index == SortOption.allCases.count - 1

                        Button(action: { local.sortBy = option }) {
                            Text(option.rawValue)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(isSelected ? .white : .black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(isSelected ? sykleBlue : Color.white)
                        }

                        if !isLast {
                            Rectangle()
                                .fill(Color.gray.opacity(0.25))
                                .frame(width: 1, height: 36)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(sykleBlue.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)

            // Distance slider
            VStack(alignment: .leading, spacing: 14) {
                Text("Distance (mi)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)

                // Star-thumb slider using UIKit under the hood
                StarSlider(value: $local.maxDistanceMiles, range: 0...2)
                    .frame(height: 40)

                Text(String(format: "%.1f mi", local.maxDistanceMiles))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)

            // Show results for
            VStack(alignment: .leading, spacing: 12) {
                Text("Show results for")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)

                FilterCheckRow(label: "Drinks", bgColor: bgGray, isChecked: $local.showDrinks)
                FilterCheckRow(label: "Food",   bgColor: bgGray, isChecked: $local.showFood)
            }
            .padding(.horizontal, 24)

            Spacer()

            // See results button
            Button(action: {
                filters = local
                filters.save()   // persist immediately on apply
                isPresented = false
            }) {
                Text("See results")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(sykleBlue)
                    .cornerRadius(30)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
        .background(Color.white)
    }
}

// MARK: - Star Slider
// Uses UISlider so the thumb gesture works reliably.
// The star image is set as the thumb image via UIKit.

struct StarSlider: UIViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value)
    }

    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider()
        slider.minimumValue = Float(range.lowerBound)
        slider.maximumValue = Float(range.upperBound)
        slider.value = Float(value)

        // Track colours
        slider.minimumTrackTintColor = UIColor(Color.sykleMid)
        slider.maximumTrackTintColor = UIColor(Color.sykleMid.opacity(0.2))

        // Star thumb image
        let starImage = makeStarImage()
        slider.setThumbImage(starImage, for: .normal)
        slider.setThumbImage(starImage, for: .highlighted)

        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.valueChanged(_:)),
            for: .valueChanged
        )

        return slider
    }

    func updateUIView(_ uiView: UISlider, context: Context) {
        uiView.value = Float(value)
    }

    // Renders a yellow star as a UIImage for the thumb
    private func makeStarImage() -> UIImage {
        let size = CGSize(width: 32, height: 32)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let yellow = UIColor(red: 254/255, green: 217/255, blue: 3/255, alpha: 1)
            yellow.setFill()

            // Draw a 5-point star
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outerRadius: CGFloat = 14
            let innerRadius: CGFloat = 6
            let path = UIBezierPath()

            for i in 0..<10 {
                let angle = CGFloat(i) * .pi / 5 - .pi / 2
                let radius = i % 2 == 0 ? outerRadius : innerRadius
                let point = CGPoint(
                    x: center.x + radius * cos(angle),
                    y: center.y + radius * sin(angle)
                )
                if i == 0 { path.move(to: point) }
                else { path.addLine(to: point) }
            }
            path.close()
            path.fill()
        }
    }

    class Coordinator: NSObject {
        @Binding var value: Double

        init(value: Binding<Double>) {
            self._value = value
        }

        @objc func valueChanged(_ sender: UISlider) {
            // Round to 1 decimal place
            value = Double(round(sender.value * 10) / 10)
        }
    }
}

// MARK: - Checkbox Row

struct FilterCheckRow: View {
    let label: String
    let bgColor: Color
    @Binding var isChecked: Bool

    let sykleBlue = Color.sykleMid

    var body: some View {
        Button(action: { isChecked.toggle() }) {
            HStack {
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isChecked ? sykleBlue : Color.clear)
                        .frame(width: 22, height: 22)
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        .frame(width: 22, height: 22)
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(bgColor)
            .cornerRadius(12)
        }
    }
}

#Preview {
    FilterSheet(
        filters: .constant(FilterOptions()),
        isPresented: .constant(true)
    )
}

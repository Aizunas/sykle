//
//  SykleColors.swift
//  Sykle
//
//  Brand colour palette — use these everywhere instead of inline RGB values
//

import SwiftUI

extension Color {
    // Light blue — backgrounds, card tints, pills
    static let sykleLight   = Color(hex: "9FC9DF")

    // Medium blue — primary brand, buttons, nav bar tint
    static let sykleMid     = Color(hex: "5886B9")

    // Dark navy blue — CTA buttons, next reward card, highlights
    static let sykleNavy    = Color(hex: "2348A3")

    // Off white / cream — page backgrounds, section backgrounds
    static let sykleCream   = Color(hex: "F0EBE5")

    // Mid grey — secondary text, icons
    static let sykleGray    = Color(hex: "595959")

    // Dark grey / near black — primary text
    static let sykleDark    = Color(hex: "333333")

    // Olive green — open pill, CO₂ accents
    static let sykleGreen   = Color(hex: "ACBD6F")

    // Salmon / pink — closed pill, error states
    static let syklePink    = Color(hex: "FEA1A1")

    // Convenience init from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

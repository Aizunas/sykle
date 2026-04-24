//
//  Models.swift
//  Sykle
//
//  Core data models for partners and rewards
//

import Foundation
import CoreLocation

// MARK: - Day Hours

struct DayHours: Hashable {
    let open: String   // "09:00"
    let close: String  // "17:00"
}

// MARK: - FakePartner

struct FakePartner: Identifiable, Hashable {
    let id = UUID()
    let apiId: String?
    let name: String
    let category: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let openHours: String
    let pointsCost: Int
    let reward: String
    let distanceMiles: String
    let syklersVisited: String
    let weeklyHours: [Int: DayHours]

    // Full init (from API)
    init(apiId: String? = nil, name: String, category: String, address: String,
         coordinate: CLLocationCoordinate2D, openHours: String, pointsCost: Int,
         reward: String, distanceMiles: String, syklersVisited: String,
         weeklyHours: [Int: DayHours] = [:]) {
        self.apiId = apiId
        self.name = name
        self.category = category
        self.address = address
        self.coordinate = coordinate
        self.openHours = openHours
        self.pointsCost = pointsCost
        self.reward = reward
        self.distanceMiles = distanceMiles
        self.syklersVisited = syklersVisited
        self.weeklyHours = weeklyHours
    }

    // MARK: - Computed Properties

    var isOpen: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date()) // 1=Sun, 7=Sat
        guard let hours = weeklyHours[weekday] else { return false }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let openTime = formatter.date(from: hours.open),
              let closeTime = formatter.date(from: hours.close) else { return false }

        let now = Date()
        let todayOpen = calendar.date(bySettingHour: calendar.component(.hour, from: openTime),
                                      minute: calendar.component(.minute, from: openTime),
                                      second: 0, of: now)!
        let todayClose = calendar.date(bySettingHour: calendar.component(.hour, from: closeTime),
                                       minute: calendar.component(.minute, from: closeTime),
                                       second: 0, of: now)!
        return now >= todayOpen && now <= todayClose
    }

    var distanceMilesValue: Double {
        let digits = distanceMiles.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()
        return Double(digits) ?? 999
    }
    
    var timeUntilCloseString: String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        guard let hours = weeklyHours[weekday] else { return "Closed today" }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let closeTime = formatter.date(from: hours.close) else { return "Closes later" }

        let now = Date()
        let todayClose = calendar.date(
            bySettingHour: calendar.component(.hour, from: closeTime),
            minute: calendar.component(.minute, from: closeTime),
            second: 0, of: now)!

        guard isOpen else { return "Currently closed" }

        let diff = calendar.dateComponents([.hour, .minute], from: now, to: todayClose)
        let hours2 = diff.hour ?? 0
        let mins = diff.minute ?? 0

        if hours2 > 0 {
            return "Closes in \(hours2)h \(mins)m"
        } else {
            return "Closes in \(mins)m"
        }
    }
    
    var todayHoursString: String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        guard let hours = weeklyHours[weekday] else { return "Closed today" }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let display = DateFormatter()
        display.dateFormat = "h:mm a"

        guard let openTime = formatter.date(from: hours.open),
              let closeTime = formatter.date(from: hours.close) else {
            return "\(hours.open) – \(hours.close)"
        }

        return "\(display.string(from: openTime)) – \(display.string(from: closeTime))"
    }
    
    var closingTimeToday: Date? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        guard let hours = weeklyHours[weekday] else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let closeTime = formatter.date(from: hours.close) else { return nil }
        return calendar.date(
            bySettingHour: calendar.component(.hour, from: closeTime),
            minute: calendar.component(.minute, from: closeTime),
            second: 0, of: Date()
        )
    }

    var isCurrentlyOpen: Bool {
        guard let closing = closingTimeToday else { return false }
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        guard let hours = weeklyHours[weekday] else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let openTime = formatter.date(from: hours.open) else { return false }
        let todayOpen = calendar.date(
            bySettingHour: calendar.component(.hour, from: openTime),
            minute: calendar.component(.minute, from: openTime),
            second: 0, of: Date()
        )!
        return Date() >= todayOpen && Date() <= closing
    }
    
    
    


    // MARK: - Hashable (CLLocationCoordinate2D isn't Hashable by default)

    static func == (lhs: FakePartner, rhs: FakePartner) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


// MARK: - FakeReward

struct FakeReward: Identifiable, Hashable {
    let id = UUID()
    let apiId: String?  // ID from backend API
    let name: String
    let syklesCost: Int
    let category: String
    
    // Init with apiId (from API)
    init(apiId: String?, name: String, syklesCost: Int, category: String) {
        self.apiId = apiId
        self.name = name
        self.syklesCost = syklesCost
        self.category = category
    }
    
    // Legacy init without apiId
    init(name: String, syklesCost: Int, category: String) {
        self.apiId = nil
        self.name = name
        self.syklesCost = syklesCost
        self.category = category
    }
}

// MARK: - Fallback Sample Data

// Helper: builds a full week from weekday + weekend hours
private func weeklySchedule(
    open: String, close: String,
    weekendOpen: String? = nil, weekendClose: String? = nil
) -> [Int: DayHours] {
    let weekday = DayHours(open: open, close: close)
    let weekend = DayHours(open: weekendOpen ?? open, close: weekendClose ?? close)
    return [
        1: weekend,  // Sun
        2: weekday,  // Mon
        3: weekday,  // Tue
        4: weekday,  // Wed
        5: weekday,  // Thu
        6: weekday,  // Fri
        7: weekend   // Sat
    ]
}

let fakePartners: [FakePartner] = [
    FakePartner(name: "Been Bakery", category: "Bakery",
                address: "14 Redchurch St, Shoreditch, E2 7DJ",
                coordinate: CLLocationCoordinate2D(latitude: 51.5237, longitude: -0.0733),
                openHours: "7:00 AM – 6:00 PM",
                pointsCost: 80, reward: "Free pastry",
                distanceMiles: "0.3 miles away", syklersVisited: "5+",
                weeklyHours: weeklySchedule(open: "07:00", close: "18:00",
                                            weekendOpen: "08:00", weekendClose: "17:00")),

    FakePartner(name: "OA Coffee", category: "Coffee",
                address: "27 Calvert Ave, Shoreditch, E2 7JP",
                coordinate: CLLocationCoordinate2D(latitude: 51.5255, longitude: -0.0791),
                openHours: "8:00 AM – 5:00 PM",
                pointsCost: 120, reward: "Free coffee",
                distanceMiles: "0.5 miles away", syklersVisited: "5+",
                weeklyHours: weeklySchedule(open: "08:00", close: "17:00",
                                            weekendOpen: "09:00", weekendClose: "17:00")),

    FakePartner(name: "Lannan", category: "Coffee",
                address: "3 Boundary St, Shoreditch, E2 7JE",
                coordinate: CLLocationCoordinate2D(latitude: 51.5248, longitude: -0.0768),
                openHours: "9:00 AM – 4:00 PM",
                pointsCost: 100, reward: "Free flat white",
                distanceMiles: "0.4 miles away", syklersVisited: "5+",
                weeklyHours: weeklySchedule(open: "09:00", close: "16:00",
                                            weekendOpen: "10:00", weekendClose: "15:00")),

    FakePartner(name: "La Joconde", category: "Bakery",
                address: "52 Columbia Rd, Bethnal Green, E2 7RG",
                coordinate: CLLocationCoordinate2D(latitude: 51.5285, longitude: -0.0724),
                openHours: "8:00 AM – 7:00 PM",
                pointsCost: 150, reward: "Free croissant",
                distanceMiles: "0.7 miles away", syklersVisited: "10+",
                weeklyHours: weeklySchedule(open: "08:00", close: "19:00",
                                            weekendOpen: "09:00", weekendClose: "18:00")),

    FakePartner(name: "Rosemund Bakery", category: "Bakery",
                address: "8 Ezra St, Bethnal Green, E2 7RH",
                coordinate: CLLocationCoordinate2D(latitude: 51.5291, longitude: -0.0741),
                openHours: "7:30 AM – 5:30 PM",
                pointsCost: 90, reward: "Free slice of cake",
                distanceMiles: "0.8 miles away", syklersVisited: "20+",
                weeklyHours: weeklySchedule(open: "07:30", close: "17:30",
                                            weekendOpen: "08:30", weekendClose: "16:30")),

    FakePartner(name: "Cremerie", category: "Coffee",
                address: "19 Arnold Circus, Shoreditch, E2 7JP",
                coordinate: CLLocationCoordinate2D(latitude: 51.5261, longitude: -0.0779),
                openHours: "9:00 AM – 3:00 PM",
                pointsCost: 110, reward: "Free latte",
                distanceMiles: "0.5 miles away", syklersVisited: "5+",
                weeklyHours: weeklySchedule(open: "09:00", close: "15:00",
                                            weekendOpen: "10:00", weekendClose: "14:00")),

    FakePartner(name: "Fifth Sip", category: "Coffee",
                address: "41 Bethnal Green Rd, E1 6LA",
                coordinate: CLLocationCoordinate2D(latitude: 51.5224, longitude: -0.0756),
                openHours: "7:00 AM – 6:00 PM",
                pointsCost: 95, reward: "Free cold brew",
                distanceMiles: "0.2 miles away", syklersVisited: "5+",
                weeklyHours: weeklySchedule(open: "07:00", close: "18:00",
                                            weekendOpen: "08:00", weekendClose: "17:00")),

    FakePartner(name: "Signorelli Pasticceria", category: "Bakery",
                address: "7 Victory Parade, London, E20 1AW",
                coordinate: CLLocationCoordinate2D(latitude: 51.5242, longitude: -0.0762),
                openHours: "8:00 AM – 6:00 PM",
                pointsCost: 120, reward: "Free coffee",
                distanceMiles: "0.3 miles away", syklersVisited: "20+",
                weeklyHours: weeklySchedule(open: "08:00", close: "18:00",
                                            weekendOpen: "09:00", weekendClose: "17:00")),
    FakePartner(name: "Sede", category: "Coffee",
                address: "12 Exmouth Market, Clerkenwell, EC1R 4QE",
                coordinate: CLLocationCoordinate2D(latitude: 51.5267, longitude: -0.1091),
                openHours: "8:00 AM – 5:00 PM", pointsCost: 100, reward: "Free espresso",
                distanceMiles: "0.4 miles away", syklersVisited: "10+",
                weeklyHours: weeklySchedule(open: "08:00", close: "17:00", weekendOpen: "09:00", weekendClose: "16:00")),

    FakePartner(name: "Aleph", category: "Bakery",
                address: "34 Stoke Newington Church St, N16 0LU",
                coordinate: CLLocationCoordinate2D(latitude: 51.5635, longitude: -0.0749),
                openHours: "7:30 AM – 5:30 PM", pointsCost: 100, reward: "Free sourdough slice",
                distanceMiles: "0.6 miles away", syklersVisited: "15+",
                weeklyHours: weeklySchedule(open: "07:30", close: "17:30", weekendOpen: "08:00", weekendClose: "17:00")),

    FakePartner(name: "Browneria", category: "Bakery",
                address: "5 Broadway Market, Hackney, E8 4PH",
                coordinate: CLLocationCoordinate2D(latitude: 51.5358, longitude: -0.0576),
                openHours: "9:00 AM – 6:00 PM", pointsCost: 100, reward: "Free brownie",
                distanceMiles: "0.5 miles away", syklersVisited: "25+",
                weeklyHours: weeklySchedule(open: "09:00", close: "18:00", weekendOpen: "09:00", weekendClose: "19:00")),

    FakePartner(name: "Cado Cado", category: "Coffee",
                address: "88 Lower Clapton Rd, Hackney, E5 0QR",
                coordinate: CLLocationCoordinate2D(latitude: 51.5498, longitude: -0.0571),
                openHours: "8:00 AM – 4:00 PM", pointsCost: 100, reward: "Free filter coffee",
                distanceMiles: "0.7 miles away", syklersVisited: "8+",
                weeklyHours: weeklySchedule(open: "08:00", close: "16:00", weekendOpen: "09:00", weekendClose: "16:00")),

    FakePartner(name: "Dayz", category: "Coffee",
                address: "21 Kingsland Road, Hoxton, E2 8AA",
                coordinate: CLLocationCoordinate2D(latitude: 51.5312, longitude: -0.0784),
                openHours: "7:30 AM – 5:00 PM", pointsCost: 100, reward: "Free oat latte",
                distanceMiles: "0.3 miles away", syklersVisited: "12+",
                weeklyHours: weeklySchedule(open: "07:30", close: "17:00", weekendOpen: "09:00", weekendClose: "17:00")),

    FakePartner(name: "Fufu", category: "Bakery",
                address: "43 Maltby St, Bermondsey, SE1 3PA",
                coordinate: CLLocationCoordinate2D(latitude: 51.4997, longitude: -0.0793),
                openHours: "8:00 AM – 3:00 PM", pointsCost: 100, reward: "Free cinnamon roll",
                distanceMiles: "0.8 miles away", syklersVisited: "6+",
                weeklyHours: weeklySchedule(open: "08:00", close: "15:00", weekendOpen: "10:00", weekendClose: "15:00")),

    FakePartner(name: "Honu", category: "Coffee",
                address: "9 Gabriel's Wharf, South Bank, SE1 9PP",
                coordinate: CLLocationCoordinate2D(latitude: 51.5073, longitude: -0.1098),
                openHours: "8:00 AM – 6:00 PM", pointsCost: 100, reward: "Free cold brew",
                distanceMiles: "0.9 miles away", syklersVisited: "30+",
                weeklyHours: weeklySchedule(open: "08:00", close: "18:00", weekendOpen: "09:00", weekendClose: "19:00")),

    FakePartner(name: "Latte Club", category: "Coffee",
                address: "67 Brewer St, Soho, W1F 9US",
                coordinate: CLLocationCoordinate2D(latitude: 51.5117, longitude: -0.1358),
                openHours: "7:00 AM – 7:00 PM", pointsCost: 100, reward: "Free latte",
                distanceMiles: "1.1 miles away", syklersVisited: "40+",
                weeklyHours: weeklySchedule(open: "07:00", close: "19:00", weekendOpen: "08:00", weekendClose: "18:00")),

    FakePartner(name: "Makeroom", category: "Coffee",
                address: "15 Brixton Village, Coldharbour Ln, SW9 8PR",
                coordinate: CLLocationCoordinate2D(latitude: 51.4618, longitude: -0.1140),
                openHours: "9:00 AM – 5:00 PM", pointsCost: 100, reward: "Free filter coffee",
                distanceMiles: "1.3 miles away", syklersVisited: "18+",
                weeklyHours: weeklySchedule(open: "09:00", close: "17:00", weekendOpen: "10:00", weekendClose: "18:00")),

    FakePartner(name: "Neulo", category: "Bakery",
                address: "6 Turnham Green Terrace, Chiswick, W4 1QP",
                coordinate: CLLocationCoordinate2D(latitude: 51.4944, longitude: -0.2546),
                openHours: "7:30 AM – 5:30 PM", pointsCost: 100, reward: "Free croissant",
                distanceMiles: "1.4 miles away", syklersVisited: "10+",
                weeklyHours: weeklySchedule(open: "07:30", close: "17:30", weekendOpen: "08:00", weekendClose: "17:00")),

    FakePartner(name: "Petibon", category: "Bakery",
                address: "22 Islington Green, Islington, N1 8DU",
                coordinate: CLLocationCoordinate2D(latitude: 51.5364, longitude: -0.1034),
                openHours: "8:00 AM – 6:00 PM", pointsCost: 100, reward: "Free baguette",
                distanceMiles: "0.6 miles away", syklersVisited: "14+",
                weeklyHours: weeklySchedule(open: "08:00", close: "18:00", weekendOpen: "09:00", weekendClose: "17:00")),
    
    FakePartner(name: "Tamed Fox", category: "Coffee",
                address: "56 Peckham Rye, Peckham, SE15 4JR",
                coordinate: CLLocationCoordinate2D(latitude: 51.4702, longitude: -0.0662),
                openHours: "8:00 AM – 5:00 PM", pointsCost: 100, reward: "Free flat white",
                distanceMiles: "1.2 miles away", syklersVisited: "22+",
                weeklyHours: weeklySchedule(open: "08:00", close: "17:00", weekendOpen: "09:00", weekendClose: "17:00")),

    FakePartner(name: "Tio", category: "Coffee",
                address: "11 Portobello Rd, Notting Hill, W11 2DA",
                coordinate: CLLocationCoordinate2D(latitude: 51.5155, longitude: -0.2042),
                openHours: "8:00 AM – 6:00 PM", pointsCost: 100, reward: "Free espresso",
                distanceMiles: "1.0 miles away", syklersVisited: "35+",
                weeklyHours: weeklySchedule(open: "08:00", close: "18:00", weekendOpen: "08:00", weekendClose: "19:00")),

    FakePartner(name: "Varmuteo", category: "Coffee",
                address: "3 Bermondsey Square, SE1 3UN",
                coordinate: CLLocationCoordinate2D(latitude: 51.4985, longitude: -0.0802),
                openHours: "9:00 AM – 4:00 PM", pointsCost: 100, reward: "Free cortado",
                distanceMiles: "0.8 miles away", syklersVisited: "9+",
                weeklyHours: weeklySchedule(open: "09:00", close: "16:00", weekendOpen: "10:00", weekendClose: "17:00")),
]

let fakeRewards: [String: [FakeReward]] = [
    "Signorelli Pasticceria": [
        FakeReward(name: "£1 off any pastry", syklesCost: 5000, category: "Food"),
        FakeReward(name: "£1 off any drink", syklesCost: 5000, category: "Drinks"),
        FakeReward(name: "Free coffee", syklesCost: 70000, category: "Drinks"),
    ],
    "Been Bakery": [
        FakeReward(name: "Free pastry", syklesCost: 4000, category: "Food"),
        FakeReward(name: "£1 off any drink", syklesCost: 3000, category: "Drinks"),
    ],
    "OA Coffee": [
        FakeReward(name: "Free coffee", syklesCost: 6000, category: "Drinks"),
        FakeReward(name: "Free cold brew", syklesCost: 5000, category: "Drinks"),
    ],
    "Lannan": [
        FakeReward(name: "Free flat white", syklesCost: 5000, category: "Drinks"),
    ],
    "La Joconde": [
        FakeReward(name: "Free croissant", syklesCost: 4500, category: "Food"),
        FakeReward(name: "Free coffee", syklesCost: 6000, category: "Drinks"),
    ],
    "Rosemund Bakery": [
        FakeReward(name: "Free slice of cake", syklesCost: 5000, category: "Food"),
        FakeReward(name: "£1 off any drink", syklesCost: 3000, category: "Drinks"),
    ],
    "Cremerie": [
        FakeReward(name: "Free latte", syklesCost: 6500, category: "Drinks"),
    ],
    "Fifth Sip": [
        FakeReward(name: "Free cold brew", syklesCost: 5000, category: "Drinks"),
        FakeReward(name: "Free pastry", syklesCost: 4000, category: "Food"),
    ],
    
    "Sede": [
        FakeReward(name: "Free espresso", syklesCost: 4000, category: "Drinks"),
        FakeReward(name: "£1 off any drink", syklesCost: 3000, category: "Drinks"),
    ],
    "Aleph": [
        FakeReward(name: "Free sourdough slice", syklesCost: 4500, category: "Food"),
        FakeReward(name: "Free coffee", syklesCost: 6000, category: "Drinks"),
    ],
    "Browneria": [
        FakeReward(name: "Free brownie", syklesCost: 3500, category: "Food"),
        FakeReward(name: "£2 off any box", syklesCost: 5000, category: "Food"),
    ],
    "Cado Cado": [
        FakeReward(name: "Free filter coffee", syklesCost: 4000, category: "Drinks"),
        FakeReward(name: "Free pastry", syklesCost: 4500, category: "Food"),
    ],
    "Dayz": [
        FakeReward(name: "Free oat latte", syklesCost: 6000, category: "Drinks"),
    ],
    "Fufu": [
        FakeReward(name: "Free cinnamon roll", syklesCost: 4000, category: "Food"),
        FakeReward(name: "£1 off any bake", syklesCost: 3000, category: "Food"),
    ],
    "Honu": [
        FakeReward(name: "Free cold brew", syklesCost: 5500, category: "Drinks"),
        FakeReward(name: "Free matcha", syklesCost: 6000, category: "Drinks"),
    ],
    "Latte Club": [
        FakeReward(name: "Free latte", syklesCost: 6000, category: "Drinks"),
        FakeReward(name: "£1 off any drink", syklesCost: 3000, category: "Drinks"),
    ],
    "Makeroom": [
        FakeReward(name: "Free filter coffee", syklesCost: 4000, category: "Drinks"),
        FakeReward(name: "Free slice of cake", syklesCost: 5000, category: "Food"),
    ],
    "Neulo": [
        FakeReward(name: "Free croissant", syklesCost: 4500, category: "Food"),
        FakeReward(name: "Free pain au chocolat", syklesCost: 4500, category: "Food"),
    ],
    "Petibon": [
        FakeReward(name: "Free baguette", syklesCost: 5000, category: "Food"),
        FakeReward(name: "£1 off any pastry", syklesCost: 3000, category: "Food"),
    ],
    
    "Tamed Fox": [
        FakeReward(name: "Free flat white", syklesCost: 5500, category: "Drinks"),
        FakeReward(name: "Free cookie", syklesCost: 3000, category: "Food"),
    ],
  
    "Tio": [
        FakeReward(name: "Free espresso", syklesCost: 4000, category: "Drinks"),
        FakeReward(name: "£2 off any drink", syklesCost: 5000, category: "Drinks"),
    ],
    "Varmuteo": [
        FakeReward(name: "Free cortado", syklesCost: 4500, category: "Drinks"),
        FakeReward(name: "Free pastry", syklesCost: 4000, category: "Food"),
    ],
    
    
]

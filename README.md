# Sykle 🚴
### Rewarding Every Ride

Sykle is a native iOS cycling rewards platform built for London. Earn sykles for every verified cycling workout and redeem them at independent local cafés and bakeries.

Built as a Final Year Project.

---

## What is Sykle?

London has 1.33 million daily cycling journeys but cycling accounts for only 3% of all trips. Sykle addresses this by turning verified cycling activity into redeemable rewards at independent high-street businesses — encouraging more frequent cycling while supporting local retailers.

---

## Features

- 🗺️ **Map & Discovery** — Find nearby partner cafés and bakeries on an interactive map that centres on your location
- 🏃 **HealthKit Integration** — Automatically syncs verified cycling workouts from Apple Health
- 💰 **Points System** — Earns sykles based on distance and duration: `(km × 100) + (minutes × 10)`
- 🎁 **Reward Redemption** — Add rewards to a basket and swipe to generate a QR voucher
- ⭐ **Favourites** — Save your favourite partner locations
- 👤 **User Profiles** — Full account management with stats, CO₂ saved, and ride history
- 🔐 **Authentication** — Email + password with validation and two-step login flow

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| iOS App | Swift, SwiftUI |
| Data | HealthKit, CoreLocation, MapKit |
| Backend | Node.js, Express |
| Database | SQLite (sqlite3) |
| Auth | bcrypt password hashing |
| Architecture | 3-tier (iOS → REST API → SQLite) |

---

## Project Structure

```
sykle/
├── ios/                          # Swift/SwiftUI iOS application
│   ├── Sykle/                    # App entry point and assets
│   ├── HomeView.swift            # Home screen with partner carousels
│   ├── MapView.swift             # Interactive partner map
│   ├── PartnerDetailView.swift   # Partner detail and reward selection
│   ├── BasketView.swift          # Reward basket and voucher generation
│   ├── ProfileView.swift         # User profile and stats
│   ├── HealthKitManager.swift    # HealthKit integration
│   ├── UserManager.swift         # Auth and user state
│   ├── NetworkManager.swift      # API networking layer
│   └── Models.swift              # Core data models
│
└── backend/                      # Node.js REST API
    ├── src/
    │   ├── server.js             # Express server
    │   ├── controllers/          # Business logic
    │   ├── routes/               # API routes
    │   └── database/             # SQLite setup and seed data
    └── data/                     # SQLite database file
```

---

## Running Locally

### Backend

```bash
cd backend
npm install
npm start
```

Server runs on `http://localhost:3000`

### iOS

1. Open `ios/Sykle.xcodeproj` in Xcode
2. Create `ios/Secrets.swift` with your local IP:

```swift
struct Secrets {
    static let localIP = "YOUR_LOCAL_IP"
}
```

3. Run on a real iPhone (HealthKit requires a physical device)

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/users` | Create or login user |
| POST | `/api/users/check` | Check if email exists |
| GET | `/api/users/:id` | Get user by ID |
| PUT | `/api/users/:id` | Update user details |
| DELETE | `/api/users/:id` | Delete account |
| POST | `/api/rides` | Sync HealthKit rides |
| GET | `/api/partners` | List all partners |
| GET | `/api/partners/:id` | Get partner with rewards |
| GET | `/api/rewards` | List all rewards |
| POST | `/api/rewards/redeem` | Redeem a reward |

---

## Points Formula

```
sykles = (distance_km × 100) + (duration_minutes × 10)
```

CO₂ saved is calculated at 150g per km compared to driving.

---

## Testing the App

### Test Account

| Field | Value |
|-------|-------|
| Email | sykletester@gmail.com |
| Password | Sykle2026 |

first name - Test 

last name - User 

This account is pre-loaded with **50,000 sykles** so you can test the full redemption flow immediately.

### What to test

1. Sign in with the test credentials above
2. Browse the **Home** screen — featured reward and partner carousels
3. Open the **Map** — tap partner pins to see details
4. Go into any partner and add a reward to your **basket**
5. Swipe to generate a **voucher**
6. Check the **Wallet** tab for your voucher history
7. View your **Profile** — stats, settings, past orders

### Notes

- Requires iPhone running iOS 16 or later
- Location permission needed for the map
- Health data won't sync on the test account (no real cycling workouts) — create your own account and add cycling workouts via the Health app to test syncing
- Backend must be running — contact if you see connection errors

---

## Methodology

Built using a hybrid **Agile + Design Thinking** approach with weekly vertical slices — each iteration delivering a demonstrable, end-to-end feature from UI through to database.

Design-first workflow: high-fidelity Figma prototypes were created before implementation, with user feedback informing each iteration.


---

## Developer

**Sanuzia Jorge**  

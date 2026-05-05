# Sykle 🚴
### Rewarding Every Ride

Sykle is a native iOS cycling rewards platform built for London. Earn sykles for every verified cycling workout and redeem them at independent local cafés and bakeries.

Built as a Final Year Project.

---

## What is Sykle?

London has 1.33 million daily cycling journeys but cycling accounts for only 3% of all trips. Sykle addresses this by turning verified cycling activity into redeemable rewards at independent high-street businesses — encouraging more frequent cycling while supporting local retailers.

---

## Features

- 🗺️ **Map & Discovery** — Interactive map centred on your location showing nearby partner cafés and bakeries
- 🏃 **HealthKit Integration** — Automatically syncs verified cycling workouts from Apple Health
- 💰 **Points System** — Earns sykles based on distance and duration: `(km × 100) + (minutes × 10)`
- 🎁 **Reward Redemption** — Add rewards to a basket and swipe to generate a QR voucher valid until closing time
- ⭐ **Favourites** — Save your favourite partner locations
- 👤 **User Profiles** — Full account management with lifetime stats, CO₂ saved, and ride history
- 🔐 **Authentication** — Two-step email + password login with full validation
- 🏆 **Leaderboard** — Weekly CO₂ savings rankings with podium display
- 🤖 **AI Customer Support** — In-app chat assistant powered by Llama via Groq

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| iOS App | Swift, SwiftUI |
| Data | HealthKit, CoreLocation, MapKit |
| Backend | Node.js, Express |
| Database | PostgreSQL |
| Auth | bcrypt password hashing |
| AI Support | Groq API (Llama 3.1) |
| Deployment | Railway |
| Architecture | 3-tier (iOS → REST API → PostgreSQL) |

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
│   ├── VoucherView.swift         # QR code voucher display
│   ├── LeaderboardView.swift     # Weekly CO₂ leaderboard
│   ├── ProfileView.swift         # User profile and stats
│   ├── SupportChatView.swift     # AI customer support chat
│   ├── HealthKitManager.swift    # HealthKit integration
│   ├── UserManager.swift         # Auth and user state
│   ├── NetworkManager.swift      # API networking layer
│   ├── PartnerStore.swift        # Partner and reward data management
│   └── Models.swift              # Core data models
│
└── backend/                      # Node.js REST API
    ├── src/
    │   ├── server.js             # Express server
    │   ├── controllers/          # Business logic
    │   ├── routes/               # API routes
    │   └── database/             # PostgreSQL connection (pg.js)
    └── package.json
```

---

## Live Backend

The backend is deployed on Railway with PostgreSQL:

**Base URL:** `https://sykle-production.up.railway.app/api`

No local setup required — the iOS app connects to this URL out of the box.

---

## Running Locally

### Backend

```bash
cd backend
npm install
npm start
```

Requires a `.env` file or environment variables:
- `DATABASE_URL` — PostgreSQL connection string
- `GROQ_API_KEY` — Groq API key for AI support chat

Server runs on `http://localhost:3000`

### iOS

1. Open `ios/Sykle.xcodeproj` in Xcode
2. Run on a real iPhone (HealthKit requires a physical device)
3. Or run on simulator for UI testing (HealthKit and GPS won't work)

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
| GET | `/api/leaderboard` | Get weekly CO₂ leaderboard |
| POST | `/api/support/chat` | AI customer support chat |

---

## Points Formula

```
sykles = (distance_km × 100) + (duration_minutes × 10)
CO₂ saved = distance_km × 150g (vs driving)
```

Sykles never expire. Vouchers are valid until the partner closes on the day of redemption.

---

## Partner Network

22 independent partner businesses across London including:

**Coffee** — OA Coffee, Lannan, Cremerie, Dayz, Sede, Honu, Latte Club, Cado Cado, Varmuteo, Tio, Makeroom, Tamed Fox, Fifth Sip

**Bakeries** — Browneria, Aleph, Petibon, Fufu, Neulo, La Joconde, Been Bakery, Rosemund Bakery, Signorelli Pasticceria

---

## Testing the App

### Test Account

| Field | Value |
|-------|-------|
| Email | sykletester@gmail.com |
| Password | Sykle2026 |
| First name | Test |
| Last name | User |

### Try in browser (no iPhone needed)

https://appetize.io/app/b_hc6tmd4ummyu6knldtez2x4m3i

### What to test

1. Sign in with the test credentials above
2. Browse the **Home** screen — featured reward and partner carousels
3. Open the **Map** — tap partner pins to see details
4. Go into any partner and add a reward to your **basket**
5. Swipe to generate a **voucher**
6. Check the **Wallet** tab for your voucher history
7. View your **Profile** — stats, CO₂ saved, past orders
8. Check the **Leaderboard** — weekly CO₂ rankings
9. Tap **Customer support** to chat with the AI assistant

### Notes

- Requires iPhone running iOS 16 or later
- Location permission needed for the map
- Health data won't sync on the test account — create your own account and add cycling workouts via the Health app to test syncing

---

## Known Limitations

- HealthKit and GPS do not work in simulator or browser — requires real iPhone
- Merchant dashboard for QR code verification is not implemented (explicitly out of scope)
- Profile pictures are stored locally on device only and do not appear on the leaderboard
- Apple Developer account (£79/year) required for TestFlight distribution

---

## Methodology

Built using a hybrid **Agile + Design Thinking** approach with weekly vertical slices — each iteration delivering a demonstrable, end-to-end feature from UI through to database.

Design-first workflow: high-fidelity Figma prototypes were created before implementation, with user feedback informing each iteration.

The project pivoted from third-party bike-sharing APIs (Lime, GBFS) to HealthKit as the verified data source — maintaining the core principle of verified, non-self-reported cycling data while improving data quality and reliability.


---

## Developer

**Sanuzia Jorge**
2026

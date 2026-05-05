# Sykle — User Guide

## What it does
Sykle is a native iOS cycling rewards platform that converts verified cycling workouts from Apple Health into redeemable points (called sykles) at independent local cafés and bakeries across London.

## Core features implemented
- Email and password authentication with two-step login flow and full validation
- HealthKit integration — syncs real cycling workouts automatically
- Points calculation: (km × 100) + (minutes × 10)
- Interactive map centred on user location with 22 partner businesses
- Partner discovery with real opening hours and live open/closed status
- Reward basket and swipe-to-redeem voucher generation
- Voucher expiry set to partner closing time on the day of redemption
- User profile with lifetime CO₂ saved, distance, and points stats
- Weekly CO₂ leaderboard with podium display
- AI customer support chat powered by Groq (Llama 3.1)
- Favourites, wallet, and past orders
- Account management including edit details and delete account

## Live backend
The backend is deployed on Railway — no local setup required.

**Base URL:** `https://sykle-production.up.railway.app/api`

## How to run

### Backend (local)
```bash
cd backend
npm install
npm start
```

Requires environment variables:
- `DATABASE_URL` — PostgreSQL connection string
- `GROQ_API_KEY` — Groq API key for AI support chat

Server runs on `http://localhost:3000`

### iOS app
1. Open `ios/Sykle.xcodeproj` in Xcode
2. Run on a real iPhone (HealthKit requires a physical device)
3. Or run on simulator for UI testing (HealthKit and GPS won't sync)

The app connects to the live Railway backend by default — no local configuration needed.

### Dependencies
- Node.js v20+
- npm packages: bcrypt, express, pg, uuid, node-fetch, nodemon
- Xcode 15+
- iOS 16+

## Test credentials
| Field | Value |
|-------|-------|
| Email | sykletester@gmail.com |
| Password | Sykle2026 |
| First name | Test |
| Last name | User |

Pre-loaded with sykles so you can test the full redemption flow immediately.

## Try in browser (no iPhone needed)
https://appetize.io/app/b_hc6tmd4ummyu6knldtez2x4m3i

The browser version connects to the live Railway backend — no additional setup needed.

## What to test
1. Sign in with the test credentials above
2. Browse the **Home** screen — featured reward and partner carousels
3. Open the **Map** — tap partner pins to see details and rewards
4. Go into any partner and add a reward to your **basket**
5. Swipe to generate a **voucher** — shows order items and QR code
6. Check the **Wallet** tab for voucher history
7. View your **Profile** — stats, CO₂ saved, past orders
8. Check the **Leaderboard** — weekly CO₂ rankings
9. Tap **Customer support** in Profile to chat with the AI assistant

## Known limitations
- HealthKit and GPS do not work in simulator or browser — requires real iPhone
- Merchant dashboard for QR code verification is not implemented (explicitly out of scope)
- Profile pictures are stored locally on device only and do not sync across devices or appear on the leaderboard
- Apple Developer account required for TestFlight distribution — currently tested in-person on device

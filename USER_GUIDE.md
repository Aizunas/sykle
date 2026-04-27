# Sykle — User Guide

## What it does
Sykle is a native iOS cycling rewards platform that converts verified cycling workouts from Apple Health into redeemable points at independent local cafés and bakeries.

## Core features implemented
- Email and password authentication with two-step login flow
- HealthKit integration — syncs real cycling workouts automatically
- Points calculation: (km × 100) + (minutes × 10)
- Interactive map centred on user location with 22 partner businesses
- Partner discovery with real opening hours and live open/closed status
- Reward basket and swipe-to-redeem voucher generation
- Voucher expiry set to partner closing time
- User profile with CO₂ saved, distance, and points stats
- Favourites, wallet, and past orders
- Account management including edit details and delete account

## How to run

### Backend
```bash
cd backend
npm install
npm start
```
Server runs on http://localhost:3000

### iOS app
1. Open ios/Sykle.xcodeproj in Xcode
2. Create ios/Secrets.swift:
```swift
struct Secrets {
    static let localIP = "YOUR_MAC_IP_ADDRESS"
}
```
3. Run on a real iPhone (HealthKit requires physical device)
4. Or run on simulator for UI testing (HealthKit won't sync)

### Dependencies
- Node.js v20+
- npm install (bcrypt, express, sqlite3, uuid, nodemon)
- Xcode 15+
- iOS 16+

## Test credentials
- Email: sykletester@gmail.com
- Password: Sykle2026
- Pre-loaded with 50,000 sykles

## Try in browser (no iPhone needed)
https://appetize.io/app/b_hc6tmd4ummyu6knldtez2x4m3i

Note: backend must be running with ngrok for the browser version to connect.

## Known limitations
- SQLite cannot be deployed to cloud platforms with ephemeral filesystems (e.g. Railway) — production would use PostgreSQL
- HealthKit and GPS do not work in simulator or browser — requires real iPhone
- Merchant dashboard for QR code verification is not implemented (explicitly out of scope)
- Leaderboard UI is built but not backed by real comparative data
- Apple Developer account (£79/year) required for TestFlight distribution — currently tested in-person
- ngrok URL changes on restart — testers need current URL from developer

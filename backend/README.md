# Sykle Backend API

Backend server for the Sykle cycling rewards platform.

## Tech Stack

- **Node.js** - Runtime
- **Express** - Web framework
- **SQLite** (sqlite3) - Database
- **UUID** - Unique ID generation

## Setup Instructions (IntelliJ)

### Step 1: Open Project

1. Open IntelliJ IDEA
2. File → Open → Select the `sykle-backend` folder
3. Trust the project when prompted

### Step 2: Install Dependencies

Open Terminal in IntelliJ (View → Tool Windows → Terminal):

```bash
npm install
```

### Step 3: Run the Server

```bash
npm run dev
```

You should see:
```
========================================
🚴 Sykle API Server running on port 3000
📍 http://localhost:3000
========================================
```

### Step 4: Test It

Open browser: **http://localhost:3000**

Or in terminal:
```bash
curl http://localhost:3000
curl http://localhost:3000/api/partners
curl http://localhost:3000/api/rewards
```

## API Endpoints

### Users
- `POST /api/users` - Create user
- `GET /api/users/:id` - Get user
- `GET /api/users/:id/stats` - Get stats

### Rides  
- `POST /api/rides` - Sync rides from iOS
- `GET /api/rides/user/:userId` - Get user's rides

### Partners
- `GET /api/partners` - List all partners
- `GET /api/partners/:id` - Get partner + rewards

### Rewards
- `GET /api/rewards` - List all rewards
- `POST /api/rewards/redeem` - Redeem a reward
- `POST /api/rewards/verify` - Verify QR code

## Testing the API

**Create a user:**
```bash
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "name": "Test User"}'
```

**Sync a ride:**
```bash
curl -X POST http://localhost:3000/api/rides \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "YOUR_USER_ID",
    "rides": [{
      "healthkitUuid": "test-001",
      "startDate": "2025-01-30T10:00:00Z",
      "endDate": "2025-01-30T10:30:00Z",
      "distanceKm": 5.5,
      "durationMinutes": 30
    }]
  }'
```

## Points Formula

```
Points = (km × 100) + (minutes × 10)

Example: 5km, 30 minutes = 500 + 300 = 800 sykles
```

## Connecting iOS App

1. Find your Mac's IP: System Settings → Network → WiFi → Details
2. Use `http://YOUR_IP:3000` as API base URL in iOS app
3. Example: `http://192.168.1.100:3000/api`

## Sample Data

Pre-loaded with 4 cafes and 8 rewards. View them:
```bash
curl http://localhost:3000/api/partners
curl http://localhost:3000/api/rewards
```

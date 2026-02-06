/**
 * Ride Controller
 * 
 * Handles ride syncing and points calculation
 * 
 * Points Formula: (km × 100) + (minutes × 10)
 * CO2 Saved: 150g per km (vs car)
 */

const { dbRun, dbGet, dbAll } = require('../database/init');
const { v4: uuidv4 } = require('uuid');

// Calculate points from a ride
function calculatePoints(distanceKm, durationMinutes) {
    const distancePoints = Math.floor(distanceKm * 100);
    const durationPoints = Math.floor(durationMinutes * 10);
    return distancePoints + durationPoints;
}

// Calculate CO2 saved (150g per km vs car)
function calculateCO2Saved(distanceKm) {
    return distanceKm * 150;
}

// Sync rides from iOS app
exports.syncRides = async (req, res) => {
    try {
        const { userId, rides } = req.body;

        if (!userId) {
            return res.status(400).json({ error: 'userId is required' });
        }

        if (!rides || !Array.isArray(rides)) {
            return res.status(400).json({ error: 'rides array is required' });
        }

        // Check user exists
        const user = await dbGet('SELECT * FROM users WHERE id = ?', [userId]);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        let newRidesCount = 0;
        let totalNewPoints = 0;
        let totalNewDistance = 0;
        let totalNewCO2 = 0;

        const syncResults = [];

        // Process each ride
        for (const ride of rides) {
            const {
                healthkitUuid,
                startDate,
                endDate,
                distanceKm,
                durationMinutes,
                caloriesBurned
            } = ride;

            // Check if ride already synced
            const existingRide = await dbGet(
                'SELECT id FROM rides WHERE healthkit_uuid = ?',
                [healthkitUuid]
            );

            if (existingRide) {
                syncResults.push({ healthkitUuid, status: 'already_synced' });
                continue;
            }

            // Calculate points and CO2
            const pointsEarned = calculatePoints(distanceKm, durationMinutes);
            const co2Saved = calculateCO2Saved(distanceKm);

            // Insert new ride
            const rideId = uuidv4();
            await dbRun(
                `INSERT INTO rides 
                (id, user_id, healthkit_uuid, start_date, end_date, distance_km, duration_minutes, calories_burned, points_earned, co2_saved_g)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                [rideId, userId, healthkitUuid, startDate, endDate, distanceKm, durationMinutes, caloriesBurned || null, pointsEarned, co2Saved]
            );

            newRidesCount++;
            totalNewPoints += pointsEarned;
            totalNewDistance += distanceKm;
            totalNewCO2 += co2Saved;

            syncResults.push({
                healthkitUuid,
                status: 'synced',
                pointsEarned,
                co2Saved
            });
        }

        // Update user totals
        if (newRidesCount > 0) {
            await dbRun(
                `UPDATE users 
                SET 
                    total_points = total_points + ?,
                    total_distance_km = total_distance_km + ?,
                    total_co2_saved_g = total_co2_saved_g + ?,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = ?`,
                [totalNewPoints, totalNewDistance, totalNewCO2, userId]
            );
        }

        // Get updated user
        const updatedUser = await dbGet('SELECT * FROM users WHERE id = ?', [userId]);

        res.json({
            message: `Synced ${newRidesCount} new rides`,
            summary: {
                ridesProcessed: rides.length,
                newRidesSynced: newRidesCount,
                pointsEarned: totalNewPoints,
                co2SavedGrams: Math.round(totalNewCO2)
            },
            user: {
                totalPoints: updatedUser.total_points,
                totalDistanceKm: Math.round(updatedUser.total_distance_km * 10) / 10,
                totalCO2SavedGrams: Math.round(updatedUser.total_co2_saved_g)
            },
            rides: syncResults
        });

    } catch (error) {
        console.error('Error syncing rides:', error);
        res.status(500).json({ error: 'Failed to sync rides' });
    }
};

// Get all rides for a user
exports.getUserRides = async (req, res) => {
    try {
        const { userId } = req.params;
        const { limit = 50, offset = 0 } = req.query;
        
        // Check user exists
        const user = await dbGet('SELECT * FROM users WHERE id = ?', [userId]);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Get rides
        const rides = await dbAll(
            `SELECT * FROM rides 
            WHERE user_id = ? 
            ORDER BY start_date DESC 
            LIMIT ? OFFSET ?`,
            [userId, parseInt(limit), parseInt(offset)]
        );

        // Get total count
        const countResult = await dbGet(
            'SELECT COUNT(*) as total FROM rides WHERE user_id = ?',
            [userId]
        );

        res.json({
            rides,
            pagination: {
                total: countResult.total,
                limit: parseInt(limit),
                offset: parseInt(offset)
            }
        });

    } catch (error) {
        console.error('Error getting user rides:', error);
        res.status(500).json({ error: 'Failed to get rides' });
    }
};

// Get a specific ride
exports.getRide = async (req, res) => {
    try {
        const { id } = req.params;

        const ride = await dbGet('SELECT * FROM rides WHERE id = ?', [id]);

        if (!ride) {
            return res.status(404).json({ error: 'Ride not found' });
        }

        res.json({ ride });

    } catch (error) {
        console.error('Error getting ride:', error);
        res.status(500).json({ error: 'Failed to get ride' });
    }
};

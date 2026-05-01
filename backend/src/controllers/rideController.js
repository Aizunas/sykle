/**
 * Ride Controller
 */

const { dbRun, dbGet, dbAll } = require('../database/init');
const { v4: uuidv4 } = require('uuid');

function calculatePoints(distanceKm, durationMinutes) {
    const distancePoints = Math.floor(distanceKm * 100);
    const durationPoints = Math.floor(durationMinutes * 10);
    return distancePoints + durationPoints;
}

function calculateCO2Saved(distanceKm) {
    return distanceKm * 150;
}

exports.syncRides = async (req, res) => {
    try {
        const { userId, rides } = req.body;

        if (!userId) return res.status(400).json({ error: 'userId is required' });
        if (!rides || !Array.isArray(rides)) return res.status(400).json({ error: 'rides array is required' });

        const user = await dbGet('SELECT * FROM users WHERE id = ?', [userId]);
        if (!user) return res.status(404).json({ error: 'User not found' });

        let newRidesCount = 0;
        let totalNewPoints = 0;
        let totalNewDistance = 0;
        let totalNewCO2 = 0;
        let totalNewMinutes = 0;

        const syncResults = [];

        for (const ride of rides) {
            const { healthkitUuid, startDate, endDate, distanceKm, durationMinutes, caloriesBurned } = ride;

            const existingRide = await dbGet('SELECT id FROM rides WHERE healthkit_uuid = ?', [healthkitUuid]);

            if (existingRide) {
                syncResults.push({ healthkitUuid, status: 'already_synced' });
                continue;
            }

            const pointsEarned = calculatePoints(distanceKm, durationMinutes);
            const co2Saved = calculateCO2Saved(distanceKm);

            const rideId = uuidv4();
            await dbRun(
                'INSERT INTO rides (id, user_id, healthkit_uuid, start_date, end_date, distance_km, duration_minutes, calories_burned, points_earned, co2_saved_g) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                [rideId, userId, healthkitUuid, startDate, endDate, distanceKm, durationMinutes, caloriesBurned || null, pointsEarned, co2Saved]
            );

            newRidesCount++;
            totalNewPoints += pointsEarned;
            totalNewDistance += distanceKm;
            totalNewCO2 += co2Saved;
            totalNewMinutes += durationMinutes;

            syncResults.push({ healthkitUuid, status: 'synced', pointsEarned, co2Saved });
        }

        if (newRidesCount > 0) {
            await dbRun(
                'UPDATE users SET total_points = total_points + ?, total_distance_km = total_distance_km + ?, total_co2_saved_g = total_co2_saved_g + ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
                [totalNewPoints, totalNewDistance, totalNewCO2, userId]
            );
        }

        const updatedUser = await dbGet('SELECT * FROM users WHERE id = ?', [userId]);

        res.json({
            message: 'Synced ' + newRidesCount + ' new rides',
            summary: {
                ridesProcessed: rides.length,
                newRidesSynced: newRidesCount,
                pointsEarned: totalNewPoints,
                co2SavedGrams: Math.round(totalNewCO2),
                distanceSynced: Math.round(totalNewDistance * 10) / 10,
                minutesSynced: Math.round(totalNewMinutes)
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

exports.getUserRides = async (req, res) => {
    try {
        const { userId } = req.params;
        const { limit = 50, offset = 0 } = req.query;

        const user = await dbGet('SELECT * FROM users WHERE id = ?', [userId]);
        if (!user) return res.status(404).json({ error: 'User not found' });

        const rides = await dbAll(
            'SELECT * FROM rides WHERE user_id = ? ORDER BY start_date DESC LIMIT ? OFFSET ?',
            [userId, parseInt(limit), parseInt(offset)]
        );

        const countResult = await dbGet('SELECT COUNT(*) as total FROM rides WHERE user_id = ?', [userId]);

        res.json({
            rides,
            pagination: { total: countResult.total, limit: parseInt(limit), offset: parseInt(offset) }
        });

    } catch (error) {
        console.error('Error getting user rides:', error);
        res.status(500).json({ error: 'Failed to get rides' });
    }
};

exports.getRide = async (req, res) => {
    try {
        const ride = await dbGet('SELECT * FROM rides WHERE id = ?', [req.params.id]);
        if (!ride) return res.status(404).json({ error: 'Ride not found' });
        res.json({ ride });
    } catch (error) {
        console.error('Error getting ride:', error);
        res.status(500).json({ error: 'Failed to get ride' });
    }
};

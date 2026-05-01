const { dbRun, dbGet, dbAll } = require('../database/pg');

function calculatePoints(distanceKm, durationMinutes) {
    return Math.floor(distanceKm * 100) + Math.floor(durationMinutes * 10);
}

function calculateCO2Saved(distanceKm) {
    return distanceKm * 150;
}

exports.syncRides = async (req, res) => {
    try {
        const { userId, rides } = req.body;
        if (!userId) return res.status(400).json({ error: 'userId is required' });
        if (!rides || !Array.isArray(rides)) return res.status(400).json({ error: 'rides array is required' });

        const user = await dbGet('SELECT * FROM users WHERE id = $1', [userId]);
        if (!user) return res.status(404).json({ error: 'User not found' });

        let newRidesCount = 0, totalNewPoints = 0, totalNewDistance = 0, totalNewCO2 = 0, totalNewMinutes = 0;
        const syncResults = [];

        for (const ride of rides) {
            const { healthkitUuid, startDate, endDate, distanceKm, durationMinutes, caloriesBurned } = ride;
            const existingRide = await dbGet('SELECT id FROM rides WHERE healthkit_uuid = $1', [healthkitUuid]);
            if (existingRide) {
                syncResults.push({ healthkitUuid, status: 'already_synced' });
                continue;
            }
            const pointsEarned = calculatePoints(distanceKm, durationMinutes);
            const co2Saved = calculateCO2Saved(distanceKm);
            await dbRun(
                'INSERT INTO rides (user_id, healthkit_uuid, start_date, end_date, distance_km, duration_minutes, calories_burned, points_earned, co2_saved_g) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)',
                [userId, healthkitUuid, startDate, endDate, distanceKm, durationMinutes, caloriesBurned || null, pointsEarned, co2Saved]
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
                'UPDATE users SET total_points = total_points + $1, total_distance_km = total_distance_km + $2, total_co2_saved_g = total_co2_saved_g + $3, updated_at = NOW() WHERE id = $4',
                [totalNewPoints, totalNewDistance, totalNewCO2, userId]
            );
        }

        const updatedUser = await dbGet('SELECT * FROM users WHERE id = $1', [userId]);
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
                totalDistanceKm: Math.round(parseFloat(updatedUser.total_distance_km) * 10) / 10,
                totalCO2SavedGrams: Math.round(parseFloat(updatedUser.total_co2_saved_g))
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
        const user = await dbGet('SELECT * FROM users WHERE id = $1', [userId]);
        if (!user) return res.status(404).json({ error: 'User not found' });
        const rides = await dbAll(
            'SELECT * FROM rides WHERE user_id = $1 ORDER BY start_date DESC LIMIT $2 OFFSET $3',
            [userId, parseInt(limit), parseInt(offset)]
        );
        const countResult = await dbGet('SELECT COUNT(*) as total FROM rides WHERE user_id = $1', [userId]);
        res.json({ rides, pagination: { total: parseInt(countResult.total), limit: parseInt(limit), offset: parseInt(offset) } });
    } catch (error) {
        res.status(500).json({ error: 'Failed to get rides' });
    }
};

exports.getRide = async (req, res) => {
    try {
        const ride = await dbGet('SELECT * FROM rides WHERE id = $1', [req.params.id]);
        if (!ride) return res.status(404).json({ error: 'Ride not found' });
        res.json({ ride });
    } catch (error) {
        res.status(500).json({ error: 'Failed to get ride' });
    }
};

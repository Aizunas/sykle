const { dbAll } = require('../database/pg');

exports.getLeaderboard = async (req, res) => {
    try {
        const { limit = 10 } = req.query;

        const users = await dbAll(
            `SELECT 
                u.id,
                u.first_name,
                u.last_name,
                u.total_points,
                u.total_distance_km,
                u.total_co2_saved_g,
                COALESCE(SUM(r.co2_saved_g), 0) as weekly_co2,
                COALESCE(SUM(r.distance_km), 0) as weekly_distance,
                COUNT(r.id) as weekly_rides
            FROM users u
            LEFT JOIN rides r ON r.user_id = u.id 
                AND r.start_date >= NOW() - INTERVAL '7 days'
            GROUP BY u.id, u.first_name, u.last_name, u.total_points, u.total_distance_km, u.total_co2_saved_g
            ORDER BY weekly_co2 DESC
            LIMIT $1`,
            [parseInt(limit)]
        );

        const leaderboard = users.map((user, index) => ({
            rank: index + 1,
            id: user.id,
            displayName: [user.first_name, user.last_name].filter(Boolean).join(' ') || 'Cyclist',
            weeklyCO2G: Math.round(parseFloat(user.weekly_co2)),
            weeklyDistanceKm: Math.round(parseFloat(user.weekly_distance) * 10) / 10,
            weeklyRides: parseInt(user.weekly_rides),
            totalPoints: user.total_points
        }));

        res.json({ leaderboard });
    } catch (error) {
        console.error('Error getting leaderboard:', error);
        res.status(500).json({ error: 'Failed to get leaderboard' });
    }
};

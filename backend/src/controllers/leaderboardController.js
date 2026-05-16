const { dbAll, dbGet } = require('../database/pg');

exports.getLeaderboard = async (req, res) => {
    try {
        const { limit = 10, userId } = req.query;

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
            ORDER BY weekly_co2 DESC`,
            []
        );

        // Assign ranks to all users
        const allRanked = users.map((user, index) => ({
            rank: index + 1,
            id: user.id,
            displayName: [user.first_name, user.last_name].filter(Boolean).join(' ') || 'Cyclist',
            weeklyCO2G: Math.round(parseFloat(user.weekly_co2)),
            weeklyDistanceKm: Math.round(parseFloat(user.weekly_distance) * 10) / 10,
            weeklyRides: parseInt(user.weekly_rides),
            totalPoints: user.total_points
        }));

        // Top 10
        const leaderboard = allRanked.slice(0, parseInt(limit));

        // If userId provided and not in top 10, find their rank
        let currentUser = null;
        if (userId) {
            const inTop10 = leaderboard.find(u => u.id === userId);
            if (!inTop10) {
                currentUser = allRanked.find(u => u.id === userId) || null;
            }
        }

        res.json({ leaderboard, currentUser });

    } catch (error) {
        console.error('Error getting leaderboard:', error);
        res.status(500).json({ error: 'Failed to get leaderboard' });
    }
};

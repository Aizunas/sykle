const { dbRun, dbGet, dbAll } = require('../database/pg');
const bcrypt = require('bcrypt');

exports.createUser = async (req, res) => {
    try {
        const { email, firstName, lastName, password } = req.body;
        if (!email) return res.status(400).json({ error: 'Email is required' });
        if (!password) return res.status(400).json({ error: 'Password is required' });

        const existingUser = await dbGet('SELECT * FROM users WHERE email = $1', [email.toLowerCase()]);
        if (existingUser) {
            const match = await bcrypt.compare(password, existingUser.password_hash || '');
            if (!match) return res.status(401).json({ error: 'Incorrect password' });
            return res.json({ message: 'User logged in', user: formatUser(existingUser) });
        }

        const passwordHash = await bcrypt.hash(password, 10);
        const result = await dbRun(
            'INSERT INTO users (email, first_name, last_name, password_hash) VALUES ($1, $2, $3, $4) RETURNING *',
            [email.toLowerCase(), firstName || null, lastName || null, passwordHash]
        );
        const newUser = result.rows[0];
        res.status(201).json({ message: 'User created successfully', user: formatUser(newUser) });
    } catch (error) {
        console.error('Error creating user:', error);
        res.status(500).json({ error: 'Failed to create user' });
    }
};

exports.getUser = async (req, res) => {
    try {
        const { id } = req.params;
        const user = await dbGet('SELECT * FROM users WHERE id = $1', [id]);
        if (!user) return res.status(404).json({ error: 'User not found' });

        const spentPoints = await dbGet(
            "SELECT COALESCE(SUM(points_spent), 0) as total FROM redemptions WHERE user_id = $1 AND status IN ('pending', 'completed')",
            [id]
        );
        const rideStats = await dbGet(
            'SELECT COALESCE(SUM(duration_minutes), 0) as total_minutes FROM rides WHERE user_id = $1',
            [id]
        );
        const availablePoints = user.total_points - parseInt(spentPoints.total);

        res.json({
            user: {
                ...formatUser(user),
                available_points: availablePoints,
                total_minutes: Math.round(parseFloat(rideStats.total_minutes))
            }
        });
    } catch (error) {
        console.error('Error getting user:', error);
        res.status(500).json({ error: 'Failed to get user' });
    }
};

exports.getUserByEmail = async (req, res) => {
    try {
        const { email } = req.params;
        const user = await dbGet('SELECT * FROM users WHERE email = $1', [email.toLowerCase()]);
        if (!user) return res.status(404).json({ error: 'User not found' });
        const spentPoints = await dbGet(
            "SELECT COALESCE(SUM(points_spent), 0) as total FROM redemptions WHERE user_id = $1 AND status IN ('pending', 'completed')",
            [user.id]
        );
        res.json({ user: { ...formatUser(user), available_points: user.total_points - parseInt(spentPoints.total) } });
    } catch (error) {
        res.status(500).json({ error: 'Failed to get user' });
    }
};

exports.getUserStats = async (req, res) => {
    try {
        const { id } = req.params;
        const user = await dbGet('SELECT * FROM users WHERE id = $1', [id]);
        if (!user) return res.status(404).json({ error: 'User not found' });

        const rideStats = await dbGet(
            'SELECT COUNT(*) as total_rides, COALESCE(SUM(distance_km),0) as total_distance, COALESCE(SUM(duration_minutes),0) as total_duration, COALESCE(SUM(points_earned),0) as total_points, COALESCE(SUM(co2_saved_g),0) as total_co2_saved FROM rides WHERE user_id = $1',
            [id]
        );
        const weeklyStats = await dbGet(
            "SELECT COUNT(*) as weekly_rides, COALESCE(SUM(distance_km),0) as weekly_distance, COALESCE(SUM(duration_minutes),0) as weekly_duration, COALESCE(SUM(points_earned),0) as weekly_points FROM rides WHERE user_id = $1 AND start_date >= NOW() - INTERVAL '7 days'",
            [id]
        );
        const redemptionStats = await dbGet(
            "SELECT COUNT(*) as total_redemptions, COALESCE(SUM(points_spent),0) as total_points_spent FROM redemptions WHERE user_id = $1 AND status IN ('pending', 'completed')",
            [id]
        );

        res.json({
            user: formatUser(user),
            stats: {
                total_points: user.total_points,
                available_points: user.total_points - parseInt(redemptionStats.total_points_spent),
                total_rides: parseInt(rideStats.total_rides),
                total_distance_km: Math.round(parseFloat(rideStats.total_distance) * 10) / 10,
                total_duration_minutes: Math.round(parseFloat(rideStats.total_duration)),
                total_co2_saved_g: Math.round(parseFloat(rideStats.total_co2_saved)),
                total_redemptions: parseInt(redemptionStats.total_redemptions),
                weekly_rides: parseInt(weeklyStats.weekly_rides),
                weekly_distance_km: Math.round(parseFloat(weeklyStats.weekly_distance) * 10) / 10,
                weekly_duration_minutes: Math.round(parseFloat(weeklyStats.weekly_duration)),
                weekly_points: parseInt(weeklyStats.weekly_points)
            }
        });
    } catch (error) {
        console.error('Error getting user stats:', error);
        res.status(500).json({ error: 'Failed to get user stats' });
    }
};

exports.updateUser = async (req, res) => {
    try {
        const { id } = req.params;
        const { firstName, lastName } = req.body;
        const user = await dbGet('SELECT * FROM users WHERE id = $1', [id]);
        if (!user) return res.status(404).json({ error: 'User not found' });
        const result = await dbRun(
            'UPDATE users SET first_name = $1, last_name = $2, updated_at = NOW() WHERE id = $3 RETURNING *',
            [firstName || user.first_name, lastName || user.last_name, id]
        );
        res.json({ message: 'User updated successfully', user: formatUser(result.rows[0]) });
    } catch (error) {
        res.status(500).json({ error: 'Failed to update user' });
    }
};

exports.checkEmail = async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) return res.status(400).json({ error: 'Email required' });
        const user = await dbGet('SELECT id, first_name FROM users WHERE email = $1', [email.toLowerCase()]);
        res.json({ exists: !!user, name: user?.first_name ?? null });
    } catch (error) {
        res.status(500).json({ error: 'Database error' });
    }
};

exports.deleteUser = async (req, res) => {
    try {
        const { id } = req.params;
        const user = await dbGet('SELECT * FROM users WHERE id = $1', [id]);
        if (!user) return res.status(404).json({ error: 'User not found' });
        await dbRun('DELETE FROM redemptions WHERE user_id = $1', [id]);
        await dbRun('DELETE FROM rides WHERE user_id = $1', [id]);
        await dbRun('DELETE FROM favourites WHERE user_id = $1', [id]);
        await dbRun('DELETE FROM users WHERE id = $1', [id]);
        res.json({ message: 'Account deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to delete account' });
    }
};

function formatUser(user) {
    return {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        fullName: [user.first_name, user.last_name].filter(Boolean).join(' ') || null,
        totalPoints: user.total_points,
        totalDistanceKm: parseFloat(user.total_distance_km) || 0,
        totalCO2SavedG: parseFloat(user.total_co2_saved_g) || 0,
        createdAt: user.created_at,
        updatedAt: user.updated_at
    };
}

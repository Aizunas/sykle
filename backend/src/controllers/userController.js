/**
 * User Controller
 */

const { dbRun, dbGet, dbAll } = require('../database/init');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcrypt');

// Create a new user (or login existing)
exports.createUser = async (req, res) => {
    try {
        const { email, firstName, lastName, password } = req.body;

        if (!email) return res.status(400).json({ error: 'Email is required' });
        if (!password) return res.status(400).json({ error: 'Password is required' });

        const existingUser = await dbGet('SELECT * FROM users WHERE email = ?', [email.toLowerCase()]);

        if (existingUser) {
            const match = await bcrypt.compare(password, existingUser.password_hash || '');
            if (!match) return res.status(401).json({ error: 'Incorrect password' });
            return res.json({ message: 'User logged in', user: formatUser(existingUser) });
        }

        const passwordHash = await bcrypt.hash(password, 10);
        const id = uuidv4();
        await dbRun(
            'INSERT INTO users (id, email, first_name, last_name, password_hash) VALUES (?, ?, ?, ?, ?)',
            [id, email.toLowerCase(), firstName || null, lastName || null, passwordHash]
        );

        const newUser = await dbGet('SELECT * FROM users WHERE id = ?', [id]);
        res.status(201).json({ message: 'User created successfully', user: formatUser(newUser) });

    } catch (error) {
        console.error('Error creating user:', error);
        res.status(500).json({ error: 'Failed to create user' });
    }
};

// Get user by ID
exports.getUser = async (req, res) => {
    try {
        const { id } = req.params;
        const user = await dbGet('SELECT * FROM users WHERE id = ?', [id]);
        if (!user) return res.status(404).json({ error: 'User not found' });

        const spentPoints = await dbGet(`
            SELECT COALESCE(SUM(points_spent), 0) as total
            FROM redemptions WHERE user_id = ? AND status IN ('pending', 'completed')
        `, [id]);

        res.json({ user: { ...formatUser(user), available_points: user.total_points - spentPoints.total } });
    } catch (error) {
        console.error('Error getting user:', error);
        res.status(500).json({ error: 'Failed to get user' });
    }
};

// Get user by email
exports.getUserByEmail = async (req, res) => {
    try {
        const { email } = req.params;
        const user = await dbGet('SELECT * FROM users WHERE email = ?', [email.toLowerCase()]);
        if (!user) return res.status(404).json({ error: 'User not found' });

        const spentPoints = await dbGet(`
            SELECT COALESCE(SUM(points_spent), 0) as total
            FROM redemptions WHERE user_id = ? AND status IN ('pending', 'completed')
        `, [user.id]);

        res.json({ user: { ...formatUser(user), available_points: user.total_points - spentPoints.total } });
    } catch (error) {
        console.error('Error getting user by email:', error);
        res.status(500).json({ error: 'Failed to get user' });
    }
};

// Get user statistics
exports.getUserStats = async (req, res) => {
    try {
        const { id } = req.params;
        const user = await dbGet('SELECT * FROM users WHERE id = ?', [id]);
        if (!user) return res.status(404).json({ error: 'User not found' });

        const rideStats = await dbGet(`
            SELECT COUNT(*) as total_rides,
                COALESCE(SUM(distance_km), 0) as total_distance,
                COALESCE(SUM(duration_minutes), 0) as total_duration,
                COALESCE(SUM(points_earned), 0) as total_points,
                COALESCE(SUM(co2_saved_g), 0) as total_co2_saved
            FROM rides WHERE user_id = ?
        `, [id]);

        const weeklyStats = await dbGet(`
            SELECT COUNT(*) as weekly_rides,
                COALESCE(SUM(distance_km), 0) as weekly_distance,
                COALESCE(SUM(duration_minutes), 0) as weekly_duration,
                COALESCE(SUM(points_earned), 0) as weekly_points
            FROM rides WHERE user_id = ? AND start_date >= datetime('now', '-7 days')
        `, [id]);

        const redemptionStats = await dbGet(`
            SELECT COUNT(*) as total_redemptions,
                COALESCE(SUM(points_spent), 0) as total_points_spent
            FROM redemptions WHERE user_id = ? AND status IN ('pending', 'completed')
        `, [id]);

        res.json({
            user: formatUser(user),
            stats: {
                total_points: user.total_points,
                available_points: user.total_points - (redemptionStats.total_points_spent || 0),
                total_rides: rideStats.total_rides,
                total_distance_km: Math.round(rideStats.total_distance * 10) / 10,
                total_duration_minutes: Math.round(rideStats.total_duration),
                total_co2_saved_g: Math.round(rideStats.total_co2_saved),
                total_redemptions: redemptionStats.total_redemptions,
                weekly_rides: weeklyStats.weekly_rides,
                weekly_distance_km: Math.round(weeklyStats.weekly_distance * 10) / 10,
                weekly_duration_minutes: Math.round(weeklyStats.weekly_duration),
                weekly_points: weeklyStats.weekly_points
            }
        });
    } catch (error) {
        console.error('Error getting user stats:', error);
        res.status(500).json({ error: 'Failed to get user stats' });
    }
};

// Update user
exports.updateUser = async (req, res) => {
    try {
        const { id } = req.params;
        const { firstName, lastName } = req.body;
        const user = await dbGet('SELECT * FROM users WHERE id = ?', [id]);
        if (!user) return res.status(404).json({ error: 'User not found' });

        await dbRun(
            'UPDATE users SET first_name = ?, last_name = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            [firstName || user.first_name, lastName || user.last_name, id]
        );

        const updatedUser = await dbGet('SELECT * FROM users WHERE id = ?', [id]);
        res.json({ message: 'User updated successfully', user: formatUser(updatedUser) });
    } catch (error) {
        console.error('Error updating user:', error);
        res.status(500).json({ error: 'Failed to update user' });
    }
};

// Check if email exists
exports.checkEmail = async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) return res.status(400).json({ error: 'Email required' });
        const user = await dbGet('SELECT id, first_name FROM users WHERE email = ?', [email.toLowerCase()]);
        res.json({ exists: !!user, name: user?.first_name ?? null });
    } catch (error) {
        console.error('Error checking email:', error);
        res.status(500).json({ error: 'Database error' });
    }
};

// Delete user
exports.deleteUser = async (req, res) => {
    try {
        const { id } = req.params;
        const user = await dbGet('SELECT * FROM users WHERE id = ?', [id]);
        if (!user) return res.status(404).json({ error: 'User not found' });

        await dbRun('DELETE FROM redemptions WHERE user_id = ?', [id]);
        await dbRun('DELETE FROM rides WHERE user_id = ?', [id]);
        await dbRun('DELETE FROM favourites WHERE user_id = ?', [id]);
        await dbRun('DELETE FROM users WHERE id = ?', [id]);

        res.json({ message: 'Account deleted successfully' });
    } catch (error) {
        console.error('Error deleting user:', error);
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
        totalDistanceKm: user.total_distance_km,
        totalCO2SavedG: user.total_co2_saved_g,
        createdAt: user.created_at,
        updatedAt: user.updated_at
    };
}
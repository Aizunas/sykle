/**
 * User Controller
 * 
 * Handles user-related business logic
 */

const { dbRun, dbGet, dbAll } = require('../database/init');
const { v4: uuidv4 } = require('uuid');

// Create a new user
exports.createUser = async (req, res) => {
    try {
        const { email, name } = req.body;

        if (!email) {
            return res.status(400).json({ error: 'Email is required' });
        }

        // Check if user already exists
        const existingUser = await dbGet('SELECT * FROM users WHERE email = ?', [email]);
        
        if (existingUser) {
            return res.json({
                message: 'User already exists',
                user: existingUser
            });
        }

        // Create new user
        const id = uuidv4();
        await dbRun(
            'INSERT INTO users (id, email, name) VALUES (?, ?, ?)',
            [id, email, name || null]
        );

        const newUser = await dbGet('SELECT * FROM users WHERE id = ?', [id]);

        res.status(201).json({
            message: 'User created successfully',
            user: newUser
        });

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

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json({ user });

    } catch (error) {
        console.error('Error getting user:', error);
        res.status(500).json({ error: 'Failed to get user' });
    }
};

// Get user statistics
exports.getUserStats = async (req, res) => {
    try {
        const { id } = req.params;

        const user = await dbGet('SELECT * FROM users WHERE id = ?', [id]);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Get ride stats
        const rideStats = await dbGet(`
            SELECT 
                COUNT(*) as total_rides,
                COALESCE(SUM(distance_km), 0) as total_distance,
                COALESCE(SUM(duration_minutes), 0) as total_duration,
                COALESCE(SUM(points_earned), 0) as total_points,
                COALESCE(SUM(co2_saved_g), 0) as total_co2_saved
            FROM rides 
            WHERE user_id = ?
        `, [id]);

        // Get redemption stats
        const redemptionStats = await dbGet(`
            SELECT 
                COUNT(*) as total_redemptions,
                COALESCE(SUM(points_spent), 0) as total_points_spent
            FROM redemptions 
            WHERE user_id = ? AND status IN ('pending', 'completed')
        `, [id]);

        res.json({
            user: {
                id: user.id,
                email: user.email,
                name: user.name
            },
            stats: {
                total_points: user.total_points,
                available_points: user.total_points - (redemptionStats.total_points_spent || 0),
                total_rides: rideStats.total_rides,
                total_distance_km: Math.round(rideStats.total_distance * 10) / 10,
                total_duration_minutes: Math.round(rideStats.total_duration),
                total_co2_saved_g: Math.round(rideStats.total_co2_saved),
                total_redemptions: redemptionStats.total_redemptions
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
        const { name } = req.body;

        const user = await dbGet('SELECT * FROM users WHERE id = ?', [id]);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        await dbRun(
            'UPDATE users SET name = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            [name || user.name, id]
        );

        const updatedUser = await dbGet('SELECT * FROM users WHERE id = ?', [id]);

        res.json({
            message: 'User updated successfully',
            user: updatedUser
        });

    } catch (error) {
        console.error('Error updating user:', error);
        res.status(500).json({ error: 'Failed to update user' });
    }
};

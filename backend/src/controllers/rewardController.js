/**
 * Reward Controller
 * 
 * Handles reward listings, redemption, and QR code verification
 */

const { dbRun, dbGet, dbAll } = require('../database/init');
const { v4: uuidv4 } = require('uuid');

// Get all rewards
exports.getAllRewards = async (req, res) => {
    try {
        const { maxPoints, category } = req.query;

        let query = `
            SELECT r.*, p.name as partner_name, p.address as partner_address
            FROM rewards r
            JOIN partners p ON r.partner_id = p.id
            WHERE r.is_active = 1 AND p.is_active = 1
        `;
        const params = [];

        if (maxPoints) {
            query += ' AND r.points_cost <= ?';
            params.push(parseInt(maxPoints));
        }

        if (category) {
            query += ' AND p.category = ?';
            params.push(category);
        }

        query += ' ORDER BY r.points_cost ASC';

        const rewards = await dbAll(query, params);

        res.json({ rewards });

    } catch (error) {
        console.error('Error getting rewards:', error);
        res.status(500).json({ error: 'Failed to get rewards' });
    }
};

// Get single reward
exports.getReward = async (req, res) => {
    try {
        const { id } = req.params;

        const reward = await dbGet(`
            SELECT r.*, p.name as partner_name, p.address as partner_address, 
                   p.latitude as partner_lat, p.longitude as partner_lng
            FROM rewards r
            JOIN partners p ON r.partner_id = p.id
            WHERE r.id = ? AND r.is_active = 1
        `, [id]);

        if (!reward) {
            return res.status(404).json({ error: 'Reward not found' });
        }

        res.json({ reward });

    } catch (error) {
        console.error('Error getting reward:', error);
        res.status(500).json({ error: 'Failed to get reward' });
    }
};

// Redeem a reward - creates QR code voucher
exports.redeemReward = async (req, res) => {
    try {
        const { userId, rewardId } = req.body;

        if (!userId || !rewardId) {
            return res.status(400).json({ error: 'userId and rewardId are required' });
        }

        // Get user
        const user = await dbGet('SELECT * FROM users WHERE id = ?', [userId]);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Get reward with partner info
        const reward = await dbGet(`
            SELECT r.*, p.name as partner_name
            FROM rewards r
            JOIN partners p ON r.partner_id = p.id
            WHERE r.id = ? AND r.is_active = 1
        `, [rewardId]);

        if (!reward) {
            return res.status(404).json({ error: 'Reward not found' });
        }

        // Calculate available points
        const spentPoints = await dbGet(`
            SELECT COALESCE(SUM(points_spent), 0) as total
            FROM redemptions
            WHERE user_id = ? AND status IN ('pending', 'completed')
        `, [userId]);

        const availablePoints = user.total_points - spentPoints.total;

        // Check user has enough points
        if (availablePoints < reward.points_cost) {
            return res.status(400).json({
                error: 'Insufficient points',
                required: reward.points_cost,
                available: availablePoints
            });
        }

        // Generate QR code
        const qrCode = `SYKLE-${uuidv4().substring(0, 8).toUpperCase()}`;
        
        // Set expiration (15 minutes)
        const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();

        // Create redemption record
        const redemptionId = uuidv4();
        await dbRun(`
            INSERT INTO redemptions 
            (id, user_id, reward_id, partner_id, points_spent, qr_code, status, expires_at)
            VALUES (?, ?, ?, ?, ?, ?, 'pending', ?)
        `, [redemptionId, userId, rewardId, reward.partner_id, reward.points_cost, qrCode, expiresAt]);

        res.status(201).json({
            message: 'Reward redeemed successfully',
            redemption: {
                id: redemptionId,
                qrCode,
                expiresAt,
                reward: {
                    name: reward.name,
                    description: reward.description,
                    pointsCost: reward.points_cost
                },
                partner: {
                    id: reward.partner_id,
                    name: reward.partner_name
                }
            },
            remainingPoints: availablePoints - reward.points_cost
        });

    } catch (error) {
        console.error('Error redeeming reward:', error);
        res.status(500).json({ error: 'Failed to redeem reward' });
    }
};

// Get user's redemption history
exports.getUserRedemptions = async (req, res) => {
    try {
        const { userId } = req.params;
        const { status } = req.query;

        const user = await dbGet('SELECT * FROM users WHERE id = ?', [userId]);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        let query = `
            SELECT red.*, 
                   rew.name as reward_name, 
                   rew.description as reward_description,
                   p.name as partner_name
            FROM redemptions red
            JOIN rewards rew ON red.reward_id = rew.id
            JOIN partners p ON red.partner_id = p.id
            WHERE red.user_id = ?
        `;
        const params = [userId];

        if (status) {
            query += ' AND red.status = ?';
            params.push(status);
        }

        query += ' ORDER BY red.created_at DESC';

        const redemptions = await dbAll(query, params);

        // Update expired pending redemptions
        const now = new Date().toISOString();
        await dbRun(`
            UPDATE redemptions 
            SET status = 'expired' 
            WHERE user_id = ? AND status = 'pending' AND expires_at < ?
        `, [userId, now]);

        res.json({ redemptions });

    } catch (error) {
        console.error('Error getting redemptions:', error);
        res.status(500).json({ error: 'Failed to get redemptions' });
    }
};

// Verify QR code
exports.verifyRedemption = async (req, res) => {
    try {
        const { qrCode, partnerId } = req.body;

        if (!qrCode || !partnerId) {
            return res.status(400).json({ error: 'qrCode and partnerId are required' });
        }

        // Find redemption
        const redemption = await dbGet(`
            SELECT red.*, 
                   rew.name as reward_name,
                   u.name as user_name, u.email as user_email
            FROM redemptions red
            JOIN rewards rew ON red.reward_id = rew.id
            JOIN users u ON red.user_id = u.id
            WHERE red.qr_code = ?
        `, [qrCode]);

        if (!redemption) {
            return res.status(404).json({ error: 'Invalid QR code', valid: false });
        }

        if (redemption.partner_id !== partnerId) {
            return res.status(403).json({ 
                error: 'QR code not valid at this location', 
                valid: false 
            });
        }

        if (redemption.status === 'completed') {
            return res.status(400).json({ 
                error: 'QR code already used', 
                valid: false,
                usedAt: redemption.redeemed_at
            });
        }

        if (redemption.status === 'expired' || new Date(redemption.expires_at) < new Date()) {
            await dbRun(
                "UPDATE redemptions SET status = 'expired' WHERE id = ?",
                [redemption.id]
            );
            return res.status(400).json({ 
                error: 'QR code has expired', 
                valid: false 
            });
        }

        // Mark as completed
        await dbRun(`
            UPDATE redemptions 
            SET status = 'completed', redeemed_at = CURRENT_TIMESTAMP 
            WHERE id = ?
        `, [redemption.id]);

        res.json({
            valid: true,
            message: 'Redemption successful',
            redemption: {
                rewardName: redemption.reward_name,
                pointsSpent: redemption.points_spent,
                userName: redemption.user_name || redemption.user_email
            }
        });

    } catch (error) {
        console.error('Error verifying redemption:', error);
        res.status(500).json({ error: 'Failed to verify redemption' });
    }
};

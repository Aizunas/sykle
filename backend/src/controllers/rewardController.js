const { dbRun, dbGet, dbAll } = require('../database/init');
const { v4: uuidv4 } = require('uuid');

exports.getAllRewards = async (req, res) => {
    try {
        const rewards = await dbAll('SELECT r.*, p.name as partner_name FROM rewards r JOIN partners p ON r.partner_id = p.id WHERE r.is_active = 1 AND p.is_active = 1 ORDER BY r.points_cost ASC', []);
        res.json({ rewards });
    } catch (error) {
        res.status(500).json({ error: 'Failed to get rewards' });
    }
};

exports.getReward = async (req, res) => {
    try {
        const reward = await dbGet('SELECT r.*, p.name as partner_name FROM rewards r JOIN partners p ON r.partner_id = p.id WHERE r.id = ? AND r.is_active = 1', [req.params.id]);
        if (!reward) return res.status(404).json({ error: 'Reward not found' });
        res.json({ reward });
    } catch (error) {
        res.status(500).json({ error: 'Failed to get reward' });
    }
};

exports.redeemReward = async (req, res) => {
    try {
        const { userId, rewardId } = req.body;
        if (!userId || !rewardId) return res.status(400).json({ error: 'userId and rewardId are required' });

        const user = await dbGet('SELECT * FROM users WHERE id = ?', [userId]);
        if (!user) return res.status(404).json({ error: 'User not found' });

        const reward = await dbGet('SELECT r.*, p.name as partner_name FROM rewards r JOIN partners p ON r.partner_id = p.id WHERE r.id = ? AND r.is_active = 1', [rewardId]);
        if (!reward) return res.status(404).json({ error: 'Reward not found' });

        const spentPoints = await dbGet('SELECT COALESCE(SUM(points_spent), 0) as total FROM redemptions WHERE user_id = ? AND status IN (?, ?)', [userId, 'pending', 'completed']);
        const availablePoints = user.total_points - spentPoints.total;

        if (availablePoints < reward.points_cost) return res.status(400).json({ error: 'Insufficient points', required: reward.points_cost, available: availablePoints });

        const qrCode = 'SYKLE-' + uuidv4().substring(0, 8).toUpperCase();
        const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();
        const redemptionId = uuidv4();

        await dbRun('INSERT INTO redemptions (id, user_id, reward_id, partner_id, points_spent, qr_code, status, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', [redemptionId, userId, rewardId, reward.partner_id, reward.points_cost, qrCode, 'pending', expiresAt]);
        await dbRun('UPDATE users SET total_points = total_points - ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?', [reward.points_cost, userId]);

        res.status(201).json({ message: 'Reward redeemed successfully', redemption: { id: redemptionId, qrCode, expiresAt }, remainingPoints: availablePoints - reward.points_cost });
    } catch (error) {
        console.error('Error redeeming reward:', error);
        res.status(500).json({ error: 'Failed to redeem reward' });
    }
};

exports.getUserRedemptions = async (req, res) => {
    try {
        const redemptions = await dbAll('SELECT red.*, rew.name as reward_name, p.name as partner_name FROM redemptions red JOIN rewards rew ON red.reward_id = rew.id JOIN partners p ON red.partner_id = p.id WHERE red.user_id = ? ORDER BY red.created_at DESC', [req.params.userId]);
        res.json({ redemptions });
    } catch (error) {
        res.status(500).json({ error: 'Failed to get redemptions' });
    }
};

exports.verifyRedemption = async (req, res) => {
    try {
        const { qrCode } = req.body;
        const redemption = await dbGet('SELECT * FROM redemptions WHERE qr_code = ?', [qrCode]);
        if (!redemption) return res.status(404).json({ error: 'Invalid QR code', valid: false });
        if (redemption.status === 'completed') return res.status(400).json({ error: 'Already used', valid: false });
        await dbRun('UPDATE redemptions SET status = ?, redeemed_at = CURRENT_TIMESTAMP WHERE id = ?', ['completed', redemption.id]);
        res.json({ valid: true, message: 'Redemption successful' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to verify redemption' });
    }
};

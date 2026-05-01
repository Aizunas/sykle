const { dbRun, dbGet, dbAll } = require('../database/pg');

exports.getAllRewards = async (req, res) => {
    try {
        const { maxPoints, category } = req.query;
        let query = 'SELECT r.*, p.name as partner_name FROM rewards r JOIN partners p ON r.partner_id = p.id WHERE r.is_active = true AND p.is_active = true';
        const params = [];
        if (maxPoints) { params.push(parseInt(maxPoints)); query += ' AND r.points_cost <= $' + params.length; }
        if (category) { params.push(category); query += ' AND p.category = $' + params.length; }
        query += ' ORDER BY r.points_cost ASC';
        const rewards = await dbAll(query, params);
        res.json({ rewards });
    } catch (error) {
        res.status(500).json({ error: 'Failed to get rewards' });
    }
};

exports.getReward = async (req, res) => {
    try {
        const reward = await dbGet('SELECT r.*, p.name as partner_name FROM rewards r JOIN partners p ON r.partner_id = p.id WHERE r.id = $1 AND r.is_active = true', [req.params.id]);
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

        const user = await dbGet('SELECT * FROM users WHERE id = $1', [userId]);
        if (!user) return res.status(404).json({ error: 'User not found' });

        const reward = await dbGet('SELECT r.*, p.name as partner_name FROM rewards r JOIN partners p ON r.partner_id = p.id WHERE r.id = $1 AND r.is_active = true', [rewardId]);
        if (!reward) return res.status(404).json({ error: 'Reward not found' });

        const spentPoints = await dbGet("SELECT COALESCE(SUM(points_spent),0) as total FROM redemptions WHERE user_id = $1 AND status IN ('pending','completed')", [userId]);
        const availablePoints = user.total_points - parseInt(spentPoints.total);
        if (availablePoints < reward.points_cost) return res.status(400).json({ error: 'Insufficient points', required: reward.points_cost, available: availablePoints });

        const qrCode = 'SYKLE-' + require('crypto').randomBytes(4).toString('hex').toUpperCase();
        const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

        await dbRun(
            "INSERT INTO redemptions (user_id, reward_id, partner_id, points_spent, qr_code, status, expires_at) VALUES ($1,$2,$3,$4,$5,'pending',$6)",
            [userId, rewardId, reward.partner_id, reward.points_cost, qrCode, expiresAt]
        );
        await dbRun('UPDATE users SET total_points = total_points - $1, updated_at = NOW() WHERE id = $2', [reward.points_cost, userId]);

        res.status(201).json({
            message: 'Reward redeemed successfully',
            redemption: { qrCode, expiresAt },
            remainingPoints: availablePoints - reward.points_cost
        });
    } catch (error) {
        console.error('Error redeeming reward:', error);
        res.status(500).json({ error: 'Failed to redeem reward' });
    }
};

exports.getUserRedemptions = async (req, res) => {
    try {
        const redemptions = await dbAll(
            'SELECT red.*, rew.name as reward_name, p.name as partner_name FROM redemptions red JOIN rewards rew ON red.reward_id = rew.id JOIN partners p ON red.partner_id = p.id WHERE red.user_id = $1 ORDER BY red.created_at DESC',
            [req.params.userId]
        );
        res.json({ redemptions });
    } catch (error) {
        res.status(500).json({ error: 'Failed to get redemptions' });
    }
};

exports.verifyRedemption = async (req, res) => {
    try {
        const { qrCode } = req.body;
        const redemption = await dbGet('SELECT * FROM redemptions WHERE qr_code = $1', [qrCode]);
        if (!redemption) return res.status(404).json({ error: 'Invalid QR code', valid: false });
        if (redemption.status === 'completed') return res.status(400).json({ error: 'Already used', valid: false });
        await dbRun("UPDATE redemptions SET status = 'completed', redeemed_at = NOW() WHERE id = $1", [redemption.id]);
        res.json({ valid: true, message: 'Redemption successful' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to verify redemption' });
    }
};

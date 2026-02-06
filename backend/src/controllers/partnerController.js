/**
 * Partner Controller
 * 
 * Handles partner (cafe/business) listings
 */

const { dbGet, dbAll } = require('../database/init');

// Helper: Calculate distance between two coordinates (Haversine formula)
function calculateDistance(lat1, lng1, lat2, lng2) {
    const R = 6371; // Earth's radius in km
    const dLat = toRad(lat2 - lat1);
    const dLng = toRad(lng2 - lng1);
    const a = 
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
        Math.sin(dLng / 2) * Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

function toRad(deg) {
    return deg * (Math.PI / 180);
}

// Get all partners
exports.getAllPartners = async (req, res) => {
    try {
        const { category, lat, lng, radius } = req.query;

        let query = 'SELECT * FROM partners WHERE is_active = 1';
        const params = [];

        // Filter by category if provided
        if (category) {
            query += ' AND category = ?';
            params.push(category);
        }

        query += ' ORDER BY name ASC';

        let partners = await dbAll(query, params);

        // If location provided, calculate distances and sort
        if (lat && lng) {
            const userLat = parseFloat(lat);
            const userLng = parseFloat(lng);
            const maxRadius = radius ? parseFloat(radius) : 10; // Default 10km

            partners = partners.map(partner => {
                if (partner.latitude && partner.longitude) {
                    const distance = calculateDistance(
                        userLat, userLng,
                        partner.latitude, partner.longitude
                    );
                    return { ...partner, distance_km: Math.round(distance * 10) / 10 };
                }
                return { ...partner, distance_km: null };
            })
            .filter(p => p.distance_km === null || p.distance_km <= maxRadius)
            .sort((a, b) => (a.distance_km || 999) - (b.distance_km || 999));
        }

        // Get reward counts for each partner
        for (let i = 0; i < partners.length; i++) {
            const rewardCount = await dbGet(
                'SELECT COUNT(*) as count FROM rewards WHERE partner_id = ? AND is_active = 1',
                [partners[i].id]
            );
            partners[i].reward_count = rewardCount.count;
        }

        res.json({ partners });

    } catch (error) {
        console.error('Error getting partners:', error);
        res.status(500).json({ error: 'Failed to get partners' });
    }
};

// Get single partner
exports.getPartner = async (req, res) => {
    try {
        const { id } = req.params;

        const partner = await dbGet(
            'SELECT * FROM partners WHERE id = ? AND is_active = 1',
            [id]
        );

        if (!partner) {
            return res.status(404).json({ error: 'Partner not found' });
        }

        // Get rewards for this partner
        const rewards = await dbAll(
            'SELECT * FROM rewards WHERE partner_id = ? AND is_active = 1 ORDER BY points_cost ASC',
            [id]
        );

        res.json({
            partner,
            rewards
        });

    } catch (error) {
        console.error('Error getting partner:', error);
        res.status(500).json({ error: 'Failed to get partner' });
    }
};

// Get rewards for a partner
exports.getPartnerRewards = async (req, res) => {
    try {
        const { id } = req.params;

        // Check partner exists
        const partner = await dbGet('SELECT * FROM partners WHERE id = ?', [id]);
        if (!partner) {
            return res.status(404).json({ error: 'Partner not found' });
        }

        const rewards = await dbAll(
            'SELECT * FROM rewards WHERE partner_id = ? AND is_active = 1 ORDER BY points_cost ASC',
            [id]
        );

        res.json({
            partner: {
                id: partner.id,
                name: partner.name
            },
            rewards
        });

    } catch (error) {
        console.error('Error getting partner rewards:', error);
        res.status(500).json({ error: 'Failed to get rewards' });
    }
};

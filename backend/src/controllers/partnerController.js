/**
 * Partner Controller
 * 
 * Handles partner (cafe/business) listings
 */

const { dbGet, dbAll } = require('../database/init');

// Helper: Calculate distance between two coordinates (Haversine formula)
function calculateDistance(lat1, lng1, lat2, lng2) {
    const R = 3959; // Earth's radius in miles
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

// Helper: Check if partner is currently open
function isPartnerOpen(partner) {
    const now = new Date();
    const day = now.getDay(); // 0 = Sunday, 6 = Saturday
    const isWeekend = day === 0 || day === 6;
    
    const openTime = isWeekend ? partner.weekend_open : partner.weekday_open;
    const closeTime = isWeekend ? partner.weekend_close : partner.weekday_close;
    
    if (!openTime || !closeTime) return false;
    
    const currentMinutes = now.getHours() * 60 + now.getMinutes();
    const [openHour, openMin] = openTime.split(':').map(Number);
    const [closeHour, closeMin] = closeTime.split(':').map(Number);
    
    const openMinutes = openHour * 60 + openMin;
    const closeMinutes = closeHour * 60 + closeMin;
    
    return currentMinutes >= openMinutes && currentMinutes < closeMinutes;
}

// Helper: Format partner response
function formatPartner(partner, userLat = null, userLng = null) {
    const formatted = {
        id: partner.id,
        name: partner.name,
        category: partner.category,
        address: partner.address,
        latitude: partner.latitude,
        longitude: partner.longitude,
        image_name: partner.image_name,
        syklers_visited: partner.syklers_visited,
        is_open: isPartnerOpen(partner),
        hours: {
            weekday: {
                open: partner.weekday_open,
                close: partner.weekday_close
            },
            weekend: {
                open: partner.weekend_open,
                close: partner.weekend_close
            }
        }
    };
    
    // Calculate distance if user location provided
    if (userLat && userLng && partner.latitude && partner.longitude) {
        const distance = calculateDistance(
            userLat, userLng,
            partner.latitude, partner.longitude
        );
        formatted.distance_miles = Math.round(distance * 10) / 10;
        formatted.distance_text = `${formatted.distance_miles} miles away`;
    }
    
    return formatted;
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
        
        const userLat = lat ? parseFloat(lat) : null;
        const userLng = lng ? parseFloat(lng) : null;
        const maxRadius = radius ? parseFloat(radius) : 10; // Default 10 miles

        // Format all partners
        let formattedPartners = partners.map(p => formatPartner(p, userLat, userLng));
        
        // Filter by radius if location provided
        if (userLat && userLng) {
            formattedPartners = formattedPartners
                .filter(p => p.distance_miles === undefined || p.distance_miles <= maxRadius)
                .sort((a, b) => (a.distance_miles || 999) - (b.distance_miles || 999));
        }

        // Get reward counts for each partner
        for (let i = 0; i < formattedPartners.length; i++) {
            const rewardCount = await dbGet(
                'SELECT COUNT(*) as count FROM rewards WHERE partner_id = ? AND is_active = 1',
                [formattedPartners[i].id]
            );
            formattedPartners[i].reward_count = rewardCount.count;
        }

        res.json({ partners: formattedPartners });

    } catch (error) {
        console.error('Error getting partners:', error);
        res.status(500).json({ error: 'Failed to get partners' });
    }
};

// Get single partner with rewards
exports.getPartner = async (req, res) => {
    try {
        const { id } = req.params;
        const { lat, lng } = req.query;

        const partner = await dbGet(
            'SELECT * FROM partners WHERE id = ? AND is_active = 1',
            [id]
        );

        if (!partner) {
            return res.status(404).json({ error: 'Partner not found' });
        }

        const userLat = lat ? parseFloat(lat) : null;
        const userLng = lng ? parseFloat(lng) : null;
        const formattedPartner = formatPartner(partner, userLat, userLng);

        // Get rewards for this partner
        const rewards = await dbAll(
            'SELECT id, name, description, points_cost, category FROM rewards WHERE partner_id = ? AND is_active = 1 ORDER BY points_cost ASC',
            [id]
        );

        res.json({
            partner: formattedPartner,
            rewards: rewards
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
        const partner = await dbGet('SELECT id, name FROM partners WHERE id = ? AND is_active = 1', [id]);
        if (!partner) {
            return res.status(404).json({ error: 'Partner not found' });
        }

        const rewards = await dbAll(
            'SELECT id, name, description, points_cost, category FROM rewards WHERE partner_id = ? AND is_active = 1 ORDER BY points_cost ASC',
            [id]
        );

        res.json({
            partner: {
                id: partner.id,
                name: partner.name
            },
            rewards: rewards
        });

    } catch (error) {
        console.error('Error getting partner rewards:', error);
        res.status(500).json({ error: 'Failed to get rewards' });
    }
};

const { dbGet, dbAll } = require('../database/pg');

function calculateDistance(lat1, lng1, lat2, lng2) {
    const R = 3959;
    const dLat = toRad(lat2 - lat1);
    const dLng = toRad(lng2 - lng1);
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
        Math.sin(dLng/2) * Math.sin(dLng/2);
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
}

function toRad(deg) { return deg * (Math.PI / 180); }

function isPartnerOpen(partner) {
    const now = new Date();
    const isWeekend = now.getDay() === 0 || now.getDay() === 6;
    const openTime = isWeekend ? partner.open_weekend : partner.open_weekday;
    const closeTime = isWeekend ? partner.close_weekend : partner.close_weekday;
    if (!openTime || !closeTime) return false;
    const current = now.getHours() * 60 + now.getMinutes();
    const [oh, om] = openTime.split(':').map(Number);
    const [ch, cm] = closeTime.split(':').map(Number);
    return current >= oh * 60 + om && current < ch * 60 + cm;
}

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
            weekday: { open: partner.open_weekday, close: partner.close_weekday },
            weekend: { open: partner.open_weekend, close: partner.close_weekend }
        }
    };
    if (userLat && userLng && partner.latitude && partner.longitude) {
        const distance = calculateDistance(userLat, userLng, partner.latitude, partner.longitude);
        formatted.distance_miles = Math.round(distance * 10) / 10;
        formatted.distance_display = distance < 0.1 ? 'less than 0.1 miles away' : distance.toFixed(1) + ' miles away';
    }
    return formatted;
}

exports.getAllPartners = async (req, res) => {
    try {
        const { category, lat, lng, radius } = req.query;
        let query = 'SELECT * FROM partners WHERE is_active = true';
        const params = [];
        if (category) {
            params.push(category);
            query += ' AND category = $' + params.length;
        }
        query += ' ORDER BY name ASC';
        let partners = await dbAll(query, params);
        const userLat = lat ? parseFloat(lat) : null;
        const userLng = lng ? parseFloat(lng) : null;
        const maxRadius = radius ? parseFloat(radius) : 10;
        let formatted = partners.map(p => formatPartner(p, userLat, userLng));
        if (userLat && userLng) {
            formatted = formatted
                .filter(p => p.distance_miles === undefined || p.distance_miles <= maxRadius)
                .sort((a, b) => (a.distance_miles || 999) - (b.distance_miles || 999));
        }
        for (let i = 0; i < formatted.length; i++) {
            const rc = await dbGet(
                'SELECT COUNT(*) as count FROM rewards WHERE partner_id = $1 AND is_active = true',
                [formatted[i].id]
            );
            formatted[i].reward_count = parseInt(rc.count);
        }
        res.json({ partners: formatted });
    } catch (error) {
        console.error('Error getting partners:', error);
        res.status(500).json({ error: 'Failed to get partners' });
    }
};

exports.getPartner = async (req, res) => {
    try {
        const { id } = req.params;
        const { lat, lng } = req.query;
        const partner = await dbGet('SELECT * FROM partners WHERE id = $1 AND is_active = true', [id]);
        if (!partner) return res.status(404).json({ error: 'Partner not found' });
        const userLat = lat ? parseFloat(lat) : null;
        const userLng = lng ? parseFloat(lng) : null;
        const formattedPartner = formatPartner(partner, userLat, userLng);
        const rewards = await dbAll(
            'SELECT id, name, description, points_cost, category FROM rewards WHERE partner_id = $1 AND is_active = true ORDER BY points_cost ASC',
            [id]
        );
        res.json({ partner: formattedPartner, rewards });
    } catch (error) {
        console.error('Error getting partner:', error);
        res.status(500).json({ error: 'Failed to get partner' });
    }
};

exports.getPartnerRewards = async (req, res) => {
    try {
        const { id } = req.params;
        const partner = await dbGet('SELECT id, name FROM partners WHERE id = $1 AND is_active = true', [id]);
        if (!partner) return res.status(404).json({ error: 'Partner not found' });
        const rewards = await dbAll(
            'SELECT id, name, description, points_cost, category FROM rewards WHERE partner_id = $1 AND is_active = true ORDER BY points_cost ASC',
            [id]
        );
        res.json({ partner: { id: partner.id, name: partner.name }, rewards });
    } catch (error) {
        console.error('Error getting partner rewards:', error);
        res.status(500).json({ error: 'Failed to get rewards' });
    }
};

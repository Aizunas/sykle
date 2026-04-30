// Database Initialization
// Sets up SQLite database with all required tables

const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const DB_PATH = path.join(__dirname, '../../data/sykle.db');

let db = null;

function getDatabase() {
    if (!db) {
        db = new sqlite3.Database(DB_PATH, (err) => {
            if (err) console.error('Error connecting to database:', err);
        });
    }
    return db;
}

function dbRun(sql, params = []) {
    return new Promise((resolve, reject) => {
        getDatabase().run(sql, params, function(err) {
            if (err) reject(err);
            else resolve({ lastID: this.lastID, changes: this.changes });
        });
    });
}

function dbGet(sql, params = []) {
    return new Promise((resolve, reject) => {
        getDatabase().get(sql, params, (err, row) => {
            if (err) reject(err);
            else resolve(row);
        });
    });
}

function dbAll(sql, params = []) {
    return new Promise((resolve, reject) => {
        getDatabase().all(sql, params, (err, rows) => {
            if (err) reject(err);
            else resolve(rows);
        });
    });
}

async function initializeDatabase() {
    console.log('Initializing database...');
    const db = getDatabase();

    db.serialize(() => {
        db.run(`CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY, email TEXT UNIQUE NOT NULL,
            first_name TEXT, last_name TEXT,
            total_points INTEGER DEFAULT 0, total_distance_km REAL DEFAULT 0,
            total_co2_saved_g REAL DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )`);

        db.run(`CREATE TABLE IF NOT EXISTS rides (
            id TEXT PRIMARY KEY, user_id TEXT NOT NULL,
            healthkit_uuid TEXT UNIQUE,
            start_date DATETIME NOT NULL, end_date DATETIME NOT NULL,
            distance_km REAL NOT NULL, duration_minutes REAL NOT NULL,
            calories_burned REAL, points_earned INTEGER NOT NULL,
            co2_saved_g REAL NOT NULL,
            synced_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )`);

        db.run(`CREATE TABLE IF NOT EXISTS partners (
            id TEXT PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL,
            address TEXT, latitude REAL, longitude REAL, image_name TEXT,
            syklers_visited TEXT DEFAULT '5+',
            weekday_open TEXT, weekday_close TEXT,
            weekend_open TEXT, weekend_close TEXT,
            is_active INTEGER DEFAULT 1,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )`);

        db.run(`CREATE TABLE IF NOT EXISTS rewards (
            id TEXT PRIMARY KEY, partner_id TEXT NOT NULL,
            name TEXT NOT NULL, description TEXT,
            points_cost INTEGER NOT NULL, category TEXT DEFAULT 'Food',
            is_active INTEGER DEFAULT 1,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (partner_id) REFERENCES partners(id)
        )`);

        db.run(`CREATE TABLE IF NOT EXISTS redemptions (
            id TEXT PRIMARY KEY, user_id TEXT NOT NULL,
            reward_id TEXT NOT NULL, partner_id TEXT NOT NULL,
            points_spent INTEGER NOT NULL, qr_code TEXT NOT NULL,
            status TEXT DEFAULT 'pending', expires_at DATETIME NOT NULL,
            redeemed_at DATETIME,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id),
            FOREIGN KEY (reward_id) REFERENCES rewards(id),
            FOREIGN KEY (partner_id) REFERENCES partners(id)
        )`);

        db.run(`CREATE TABLE IF NOT EXISTS favourites (
            id TEXT PRIMARY KEY, user_id TEXT NOT NULL, partner_id TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id),
            FOREIGN KEY (partner_id) REFERENCES partners(id),
            UNIQUE(user_id, partner_id)
        )`);

        db.get('SELECT COUNT(*) as count FROM partners', [], (err, row) => {
            if (err) { console.error('Error checking partners:', err); return; }
            if (row.count === 0) {
                console.log('Adding partners and rewards...');
                addSampleData(db);
            } else {
                console.log('Database has ' + row.count + ' partners');
            }
        });
    });

    console.log('Database initialized successfully');
    return db;
}

function addSampleData(db) {
    const partners = [
        { id: 'partner-been-bakery', name: 'Been Bakery', category: 'Bakery', address: '14 Redchurch St, Shoreditch, E2 7DJ', latitude: 51.5237, longitude: -0.0733, image_name: 'been_bakery', syklers_visited: '5+', weekday_open: '07:00', weekday_close: '18:00', weekend_open: '08:00', weekend_close: '17:00' },
        { id: 'partner-oa-coffee', name: 'OA Coffee', category: 'Coffee', address: '27 Calvert Ave, Shoreditch, E2 7JP', latitude: 51.5255, longitude: -0.0791, image_name: 'oa_coffee', syklers_visited: '5+', weekday_open: '08:00', weekday_close: '17:00', weekend_open: '09:00', weekend_close: '17:00' },
        { id: 'partner-lannan', name: 'Lannan', category: 'Coffee', address: '3 Boundary St, Shoreditch, E2 7JE', latitude: 51.5248, longitude: -0.0768, image_name: 'lannan', syklers_visited: '5+', weekday_open: '09:00', weekday_close: '16:00', weekend_open: '10:00', weekend_close: '15:00' },
        { id: 'partner-la-joconde', name: 'La Joconde', category: 'Bakery', address: '52 Columbia Rd, Bethnal Green, E2 7RG', latitude: 51.5285, longitude: -0.0724, image_name: 'la_joconde', syklers_visited: '10+', weekday_open: '08:00', weekday_close: '19:00', weekend_open: '09:00', weekend_close: '18:00' },
        { id: 'partner-rosemund-bakery', name: 'Rosemund Bakery', category: 'Bakery', address: '8 Ezra St, Bethnal Green, E2 7RH', latitude: 51.5291, longitude: -0.0741, image_name: 'rosemund', syklers_visited: '20+', weekday_open: '07:30', weekday_close: '17:30', weekend_open: '08:30', weekend_close: '16:30' },
        { id: 'partner-cremerie', name: 'Cremerie', category: 'Coffee', address: '19 Arnold Circus, Shoreditch, E2 7JP', latitude: 51.5261, longitude: -0.0779, image_name: 'cremerie', syklers_visited: '5+', weekday_open: '09:00', weekday_close: '15:00', weekend_open: '10:00', weekend_close: '14:00' },
        { id: 'partner-fifth-sip', name: 'Fifth Sip', category: 'Coffee', address: '41 Bethnal Green Rd, E1 6LA', latitude: 51.5224, longitude: -0.0756, image_name: 'fifth_sip', syklers_visited: '5+', weekday_open: '07:00', weekday_close: '18:00', weekend_open: '08:00', weekend_close: '17:00' },
        { id: 'partner-signorelli', name: 'Signorelli Pasticceria', category: 'Bakery', address: '7 Victory Parade, Stratford, E20 1AW', latitude: 51.5431, longitude: -0.0061, image_name: 'signorelli_pasticceria', syklers_visited: '20+', weekday_open: '08:00', weekday_close: '18:00', weekend_open: '09:00', weekend_close: '17:00' },
        { id: 'partner-sede', name: 'Sede', category: 'Coffee', address: '12 Exmouth Market, Clerkenwell, EC1R 4QE', latitude: 51.5267, longitude: -0.1091, image_name: 'sede', syklers_visited: '10+', weekday_open: '08:00', weekday_close: '17:00', weekend_open: '09:00', weekend_close: '16:00' },
        { id: 'partner-aleph', name: 'Aleph', category: 'Bakery', address: '34 Stoke Newington Church St, N16 0LU', latitude: 51.5635, longitude: -0.0749, image_name: 'aleph', syklers_visited: '15+', weekday_open: '07:30', weekday_close: '17:30', weekend_open: '08:00', weekend_close: '17:00' },
        { id: 'partner-browneria', name: 'Browneria', category: 'Bakery', address: '5 Broadway Market, Hackney, E8 4PH', latitude: 51.5358, longitude: -0.0576, image_name: 'browneria', syklers_visited: '25+', weekday_open: '09:00', weekday_close: '18:00', weekend_open: '09:00', weekend_close: '19:00' },
        { id: 'partner-cado-cado', name: 'Cado Cado', category: 'Coffee', address: '88 Lower Clapton Rd, Hackney, E5 0QR', latitude: 51.5498, longitude: -0.0571, image_name: 'cado_cado', syklers_visited: '8+', weekday_open: '08:00', weekday_close: '16:00', weekend_open: '09:00', weekend_close: '16:00' },
        { id: 'partner-dayz', name: 'Dayz', category: 'Coffee', address: '21 Kingsland Road, Hoxton, E2 8AA', latitude: 51.5312, longitude: -0.0784, image_name: 'dayz', syklers_visited: '12+', weekday_open: '07:30', weekday_close: '17:00', weekend_open: '09:00', weekend_close: '17:00' },
        { id: 'partner-fufu', name: 'Fufu', category: 'Bakery', address: '43 Maltby St, Bermondsey, SE1 3PA', latitude: 51.4997, longitude: -0.0793, image_name: 'fufu', syklers_visited: '6+', weekday_open: '08:00', weekday_close: '15:00', weekend_open: '10:00', weekend_close: '15:00' },
        { id: 'partner-honu', name: 'Honu', category: 'Coffee', address: "9 Gabriel's Wharf, South Bank, SE1 9PP", latitude: 51.5073, longitude: -0.1098, image_name: 'honu', syklers_visited: '30+', weekday_open: '08:00', weekday_close: '18:00', weekend_open: '09:00', weekend_close: '19:00' },
        { id: 'partner-latte-club', name: 'Latte Club', category: 'Coffee', address: '67 Brewer St, Soho, W1F 9US', latitude: 51.5117, longitude: -0.1358, image_name: 'latte_club', syklers_visited: '40+', weekday_open: '07:00', weekday_close: '19:00', weekend_open: '08:00', weekend_close: '18:00' },
        { id: 'partner-makeroom', name: 'Makeroom', category: 'Coffee', address: '15 Brixton Village, Coldharbour Ln, SW9 8PR', latitude: 51.4618, longitude: -0.1140, image_name: 'makeroom', syklers_visited: '18+', weekday_open: '09:00', weekday_close: '17:00', weekend_open: '10:00', weekend_close: '18:00' },
        { id: 'partner-neulo', name: 'Neulo', category: 'Bakery', address: '6 Turnham Green Terrace, Chiswick, W4 1QP', latitude: 51.4944, longitude: -0.2546, image_name: 'neulo', syklers_visited: '10+', weekday_open: '07:30', weekday_close: '17:30', weekend_open: '08:00', weekend_close: '17:00' },
        { id: 'partner-petibon', name: 'Petibon', category: 'Bakery', address: '22 Islington Green, Islington, N1 8DU', latitude: 51.5364, longitude: -0.1034, image_name: 'petibon', syklers_visited: '14+', weekday_open: '08:00', weekday_close: '18:00', weekend_open: '09:00', weekend_close: '17:00' },
        { id: 'partner-tamedfox', name: 'Tamed Fox', category: 'Coffee', address: '56 Peckham Rye, Peckham, SE15 4JR', latitude: 51.4702, longitude: -0.0662, image_name: 'tamedfox', syklers_visited: '22+', weekday_open: '08:00', weekday_close: '17:00', weekend_open: '09:00', weekend_close: '17:00' },
        { id: 'partner-tio', name: 'Tio', category: 'Coffee', address: '11 Portobello Rd, Notting Hill, W11 2DA', latitude: 51.5155, longitude: -0.2042, image_name: 'tio', syklers_visited: '35+', weekday_open: '08:00', weekday_close: '18:00', weekend_open: '08:00', weekend_close: '19:00' },
        { id: 'partner-varmuteo', name: 'Varmuteo', category: 'Coffee', address: '3 Bermondsey Square, SE1 3UN', latitude: 51.4985, longitude: -0.0802, image_name: 'varmuteo', syklers_visited: '9+', weekday_open: '09:00', weekday_close: '16:00', weekend_open: '10:00', weekend_close: '17:00' }
    ];

    const insertPartner = db.prepare(`INSERT OR IGNORE INTO partners (id, name, category, address, latitude, longitude, image_name, syklers_visited, weekday_open, weekday_close, weekend_open, weekend_close) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`);
    partners.forEach(p => insertPartner.run([p.id, p.name, p.category, p.address, p.latitude, p.longitude, p.image_name, p.syklers_visited, p.weekday_open, p.weekday_close, p.weekend_open, p.weekend_close]));
    insertPartner.finalize();

    const rewards = [
        { id: 'reward-been-1', partner_id: 'partner-been-bakery', name: 'Free pastry', points_cost: 4000, category: 'Food' },
        { id: 'reward-been-2', partner_id: 'partner-been-bakery', name: '£1 off any drink', points_cost: 3000, category: 'Drinks' },
        { id: 'reward-oa-1', partner_id: 'partner-oa-coffee', name: 'Free coffee', points_cost: 6000, category: 'Drinks' },
        { id: 'reward-oa-2', partner_id: 'partner-oa-coffee', name: 'Free cold brew', points_cost: 5000, category: 'Drinks' },
        { id: 'reward-lan-1', partner_id: 'partner-lannan', name: 'Free flat white', points_cost: 5000, category: 'Drinks' },
        { id: 'reward-laj-1', partner_id: 'partner-la-joconde', name: 'Free croissant', points_cost: 4500, category: 'Food' },
        { id: 'reward-laj-2', partner_id: 'partner-la-joconde', name: 'Free coffee', points_cost: 6000, category: 'Drinks' },
        { id: 'reward-ros-1', partner_id: 'partner-rosemund-bakery', name: 'Free slice of cake', points_cost: 5000, category: 'Food' },
        { id: 'reward-ros-2', partner_id: 'partner-rosemund-bakery', name: '£1 off any drink', points_cost: 3000, category: 'Drinks' },
        { id: 'reward-cre-1', partner_id: 'partner-cremerie', name: 'Free latte', points_cost: 6500, category: 'Drinks' },
        { id: 'reward-fif-1', partner_id: 'partner-fifth-sip', name: 'Free cold brew', points_cost: 5000, category: 'Drinks' },
        { id: 'reward-fif-2', partner_id: 'partner-fifth-sip', name: 'Free pastry', points_cost: 4000, category: 'Food' },
        { id: 'reward-sig-1', partner_id: 'partner-signorelli', name: '£1 off any pastry', points_cost: 5000, category: 'Food' },
        { id: 'reward-sig-2', partner_id: 'partner-signorelli', name: '£1 off any drink', points_cost: 5000, category: 'Drinks' },
        { id: 'reward-sig-3', partner_id: 'partner-signorelli', name: 'Free coffee', points_cost: 70000, category: 'Drinks' },
        { id: 'reward-sede-1', partner_id: 'partner-sede', name: 'Free espresso', points_cost: 4000, category: 'Drinks' },
        { id: 'reward-sede-2', partner_id: 'partner-sede', name: '£1 off any drink', points_cost: 3000, category: 'Drinks' },
        { id: 'reward-aleph-1', partner_id: 'partner-aleph', name: 'Free sourdough slice', points_cost: 4500, category: 'Food' },
        { id: 'reward-aleph-2', partner_id: 'partner-aleph', name: 'Free coffee', points_cost: 6000, category: 'Drinks' },
        { id: 'reward-brow-1', partner_id: 'partner-browneria', name: 'Free brownie', points_cost: 3500, category: 'Food' },
        { id: 'reward-brow-2', partner_id: 'partner-browneria', name: '£2 off any box', points_cost: 5000, category: 'Food' },
        { id: 'reward-cado-1', partner_id: 'partner-cado-cado', name: 'Free filter coffee', points_cost: 4000, category: 'Drinks' },
        { id: 'reward-cado-2', partner_id: 'partner-cado-cado', name: 'Free pastry', points_cost: 4500, category: 'Food' },
        { id: 'reward-dayz-1', partner_id: 'partner-dayz', name: 'Free oat latte', points_cost: 6000, category: 'Drinks' },
        { id: 'reward-fufu-1', partner_id: 'partner-fufu', name: 'Free cinnamon roll', points_cost: 4000, category: 'Food' },
        { id: 'reward-fufu-2', partner_id: 'partner-fufu', name: '£1 off any bake', points_cost: 3000, category: 'Food' },
        { id: 'reward-honu-1', partner_id: 'partner-honu', name: 'Free cold brew', points_cost: 5500, category: 'Drinks' },
        { id: 'reward-honu-2', partner_id: 'partner-honu', name: 'Free matcha', points_cost: 6000, category: 'Drinks' },
        { id: 'reward-latt-1', partner_id: 'partner-latte-club', name: 'Free latte', points_cost: 6000, category: 'Drinks' },
        { id: 'reward-latt-2', partner_id: 'partner-latte-club', name: '£1 off any drink', points_cost: 3000, category: 'Drinks' },
        { id: 'reward-make-1', partner_id: 'partner-makeroom', name: 'Free filter coffee', points_cost: 4000, category: 'Drinks' },
        { id: 'reward-make-2', partner_id: 'partner-makeroom', name: 'Free slice of cake', points_cost: 5000, category: 'Food' },
        { id: 'reward-neul-1', partner_id: 'partner-neulo', name: 'Free croissant', points_cost: 4500, category: 'Food' },
        { id: 'reward-neul-2', partner_id: 'partner-neulo', name: 'Free pain au chocolat', points_cost: 4500, category: 'Food' },
        { id: 'reward-peti-1', partner_id: 'partner-petibon', name: 'Free baguette', points_cost: 5000, category: 'Food' },
        { id: 'reward-peti-2', partner_id: 'partner-petibon', name: '£1 off any pastry', points_cost: 3000, category: 'Food' },
        { id: 'reward-tame-1', partner_id: 'partner-tamedfox', name: 'Free flat white', points_cost: 5500, category: 'Drinks' },
        { id: 'reward-tame-2', partner_id: 'partner-tamedfox', name: 'Free cookie', points_cost: 3000, category: 'Food' },
        { id: 'reward-tio-1', partner_id: 'partner-tio', name: 'Free espresso', points_cost: 4000, category: 'Drinks' },
        { id: 'reward-tio-2', partner_id: 'partner-tio', name: '£2 off any drink', points_cost: 5000, category: 'Drinks' },
        { id: 'reward-varm-1', partner_id: 'partner-varmuteo', name: 'Free cortado', points_cost: 4500, category: 'Drinks' },
        { id: 'reward-varm-2', partner_id: 'partner-varmuteo', name: 'Free pastry', points_cost: 4000, category: 'Food' }
    ];

    const insertReward = db.prepare(`INSERT OR IGNORE INTO rewards (id, partner_id, name, points_cost, category) VALUES (?, ?, ?, ?, ?)`);
    rewards.forEach(r => insertReward.run([r.id, r.partner_id, r.name, r.points_cost, r.category]));
    insertReward.finalize();

    console.log('Added ' + partners.length + ' partners and ' + rewards.length + ' rewards');
}

module.exports = { getDatabase, initializeDatabase, dbRun, dbGet, dbAll };

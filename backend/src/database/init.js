/**
 * Database Initialization
 * 
 * Sets up SQLite database with all required tables
 * Uses sqlite3 package (async callbacks)
 */

const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Database file path
const DB_PATH = path.join(__dirname, '../../data/sykle.db');

// Create database connection
let db = null;

function getDatabase() {
    if (!db) {
        db = new sqlite3.Database(DB_PATH, (err) => {
            if (err) {
                console.error('Error connecting to database:', err);
            }
        });
    }
    return db;
}

// Promisified db.run
function dbRun(sql, params = []) {
    return new Promise((resolve, reject) => {
        getDatabase().run(sql, params, function(err) {
            if (err) reject(err);
            else resolve({ lastID: this.lastID, changes: this.changes });
        });
    });
}

// Promisified db.get (single row)
function dbGet(sql, params = []) {
    return new Promise((resolve, reject) => {
        getDatabase().get(sql, params, (err, row) => {
            if (err) reject(err);
            else resolve(row);
        });
    });
}

// Promisified db.all (multiple rows)
function dbAll(sql, params = []) {
    return new Promise((resolve, reject) => {
        getDatabase().all(sql, params, (err, rows) => {
            if (err) reject(err);
            else resolve(rows);
        });
    });
}

async function initializeDatabase() {
    console.log('📦 Initializing database...');

    const db = getDatabase();

    // Create tables using serialize to ensure order
    db.serialize(() => {
        // USERS TABLE
        db.run(`
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                email TEXT UNIQUE NOT NULL,
                name TEXT,
                total_points INTEGER DEFAULT 0,
                total_distance_km REAL DEFAULT 0,
                total_co2_saved_g REAL DEFAULT 0,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        `);

        // RIDES TABLE
        db.run(`
            CREATE TABLE IF NOT EXISTS rides (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                healthkit_uuid TEXT UNIQUE,
                start_date DATETIME NOT NULL,
                end_date DATETIME NOT NULL,
                distance_km REAL NOT NULL,
                duration_minutes REAL NOT NULL,
                calories_burned REAL,
                points_earned INTEGER NOT NULL,
                co2_saved_g REAL NOT NULL,
                synced_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        `);

        // PARTNERS TABLE
        db.run(`
            CREATE TABLE IF NOT EXISTS partners (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                description TEXT,
                address TEXT,
                latitude REAL,
                longitude REAL,
                image_url TEXT,
                category TEXT DEFAULT 'cafe',
                is_active INTEGER DEFAULT 1,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        `);

        // REWARDS TABLE
        db.run(`
            CREATE TABLE IF NOT EXISTS rewards (
                id TEXT PRIMARY KEY,
                partner_id TEXT NOT NULL,
                name TEXT NOT NULL,
                description TEXT,
                points_cost INTEGER NOT NULL,
                image_url TEXT,
                is_active INTEGER DEFAULT 1,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (partner_id) REFERENCES partners(id)
            )
        `);

        // REDEMPTIONS TABLE
        db.run(`
            CREATE TABLE IF NOT EXISTS redemptions (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                reward_id TEXT NOT NULL,
                partner_id TEXT NOT NULL,
                points_spent INTEGER NOT NULL,
                qr_code TEXT NOT NULL,
                status TEXT DEFAULT 'pending',
                expires_at DATETIME NOT NULL,
                redeemed_at DATETIME,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id),
                FOREIGN KEY (reward_id) REFERENCES rewards(id),
                FOREIGN KEY (partner_id) REFERENCES partners(id)
            )
        `);

        // Check if we need to add sample data
        db.get('SELECT COUNT(*) as count FROM partners', [], (err, row) => {
            if (err) {
                console.error('Error checking partners:', err);
                return;
            }
            
            if (row.count === 0) {
                console.log('📝 Adding sample partners and rewards...');
                addSampleData(db);
            }
        });
    });

    console.log('✅ Database initialized successfully');
    return db;
}

function addSampleData(db) {
    // Sample Partners
    const partners = [
        ['partner-1', 'Signorelli Pasticceria', 'Authentic Italian pastries and coffee', '7 Victory Parade, London E20 1AW', 51.5387, -0.0166, 'cafe'],
        ['partner-2', 'Bean & Brew', 'Specialty coffee roasters', '23 High Street, London E15 2QB', 51.5432, -0.0211, 'cafe'],
        ['partner-3', 'Green Pedal Cafe', 'Cyclist-friendly cafe with bike parking', '45 Cycle Lane, London E3 4RT', 51.5301, -0.0298, 'cafe'],
        ['partner-4', 'OA Coffee', 'Organic artisan coffee', '12 Market Square, London E8 1HN', 51.5445, -0.0556, 'cafe']
    ];

    const insertPartner = db.prepare(`
        INSERT OR IGNORE INTO partners (id, name, description, address, latitude, longitude, category)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    `);

    partners.forEach(p => insertPartner.run(p));
    insertPartner.finalize();

    // Sample Rewards
    const rewards = [
        ['reward-1', 'partner-1', 'Free Espresso', 'One free espresso shot', 500],
        ['reward-2', 'partner-1', 'Pastry of the Day', 'Any pastry from the display', 750],
        ['reward-3', 'partner-2', 'Free Coffee', 'Any regular hot drink', 600],
        ['reward-4', 'partner-2', 'Coffee & Cake Combo', 'Regular coffee plus cake slice', 1200],
        ['reward-5', 'partner-3', 'Cyclist Breakfast', 'Full breakfast for cyclists', 2000],
        ['reward-6', 'partner-3', 'Energy Smoothie', 'Post-ride protein smoothie', 800],
        ['reward-7', 'partner-4', 'Organic Latte', 'Large organic latte', 700],
        ['reward-8', 'partner-4', 'Lunch Deal', 'Sandwich + drink combo', 1500]
    ];

    const insertReward = db.prepare(`
        INSERT OR IGNORE INTO rewards (id, partner_id, name, description, points_cost)
        VALUES (?, ?, ?, ?, ?)
    `);

    rewards.forEach(r => insertReward.run(r));
    insertReward.finalize();

    console.log('✅ Sample data added');
}

module.exports = {
    getDatabase,
    initializeDatabase,
    dbRun,
    dbGet,
    dbAll
};

const { Pool } = require('pg');

const pool = new Pool({
    host: 'localhost',
    database: 'sykle_db',
    user: process.env.DB_USER || require('os').userInfo().username,
    password: process.env.DB_PASSWORD || '',
    port: 5432,
});

// Test connection
pool.connect((err, client, release) => {
    if (err) {
        console.error('❌ PostgreSQL connection error:', err.message);
    } else {
        console.log('✅ Connected to PostgreSQL');
        release();
    }
});

// Helper functions to match existing SQLite interface
const dbGet = async (query, params = []) => {
    const result = await pool.query(query, params);
    return result.rows[0] || null;
};

const dbAll = async (query, params = []) => {
    const result = await pool.query(query, params);
    return result.rows;
};

const dbRun = async (query, params = []) => {
    const result = await pool.query(query, params);
    return result;
};

module.exports = { pool, dbGet, dbAll, dbRun };

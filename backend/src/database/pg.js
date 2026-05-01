const { Pool } = require('pg');

console.log('DATABASE_URL present:', !!process.env.DATABASE_URL);

const pool = new Pool(
    process.env.DATABASE_URL
        ? { connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } }
        : {
            host: 'localhost',
            database: 'sykle_db',
            user: require('os').userInfo().username,
            password: '',
            port: 5432
        }
);

pool.connect((err, client, release) => {
    if (err) {
        console.error('❌ PostgreSQL connection error:', err.message);
    } else {
        console.log('✅ Connected to PostgreSQL');
        release();
    }
});

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

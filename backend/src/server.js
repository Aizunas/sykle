/**
 * Sykle Backend Server
 * 
 * Main entry point for the Express API server
 */

const express = require('express');
const cors = require('cors');
const path = require('path');

// Import routes
const userRoutes = require('./routes/userRoutes');
const rideRoutes = require('./routes/rideRoutes');
const partnerRoutes = require('./routes/partnerRoutes');
const rewardRoutes = require('./routes/rewardRoutes');

// Import database initialization
const { initializeDatabase } = require('./database/init');

// Create Express app
const app = express();
const PORT = process.env.PORT || 3000;

// ===================
// Middleware
// ===================

// Enable CORS for iOS app to connect
app.use(cors());

// Parse JSON request bodies
app.use(express.json());

// Request logging (helpful for debugging)
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});

// ===================
// Routes
// ===================

// Health check endpoint
app.get('/', (req, res) => {
    res.json({
        message: 'Welcome to Sykle API',
        version: '1.0.0',
        endpoints: {
            users: '/api/users',
            rides: '/api/rides',
            partners: '/api/partners',
            rewards: '/api/rewards'
        }
    });
});

// API routes
app.use('/api/users', userRoutes);
app.use('/api/rides', rideRoutes);
app.use('/api/partners', partnerRoutes);
app.use('/api/rewards', rewardRoutes);

// ===================
// Error Handling
// ===================

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Endpoint not found' });
});

// Global error handler
app.use((err, req, res, next) => {
    console.error('Error:', err.message);
    res.status(500).json({ error: 'Internal server error' });
});

// ===================
// Start Server
// ===================

// Initialize database and start server
initializeDatabase();

app.listen(PORT, () => {
    console.log('========================================');
    console.log(`🚴 Sykle API Server running on port ${PORT}`);
    console.log(`📍 http://localhost:${PORT}`);
    console.log('========================================');
    console.log('Available endpoints:');
    console.log('  GET    /                     - API info');
    console.log('  POST   /api/users            - Create user');
    console.log('  GET    /api/users/:id        - Get user');
    console.log('  POST   /api/rides            - Sync rides');
    console.log('  GET    /api/rides/user/:id   - Get user rides');
    console.log('  GET    /api/partners         - List partners');
    console.log('  GET    /api/rewards          - List rewards');
    console.log('  POST   /api/rewards/redeem   - Redeem reward');
    console.log('========================================');
});

module.exports = app;

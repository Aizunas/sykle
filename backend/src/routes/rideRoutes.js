/**
 * Ride Routes
 * 
 * Handles syncing rides from iOS app and retrieving ride history
 */

const express = require('express');
const router = express.Router();
const rideController = require('../controllers/rideController');

// POST /api/rides - Sync rides from iOS app
router.post('/', rideController.syncRides);

// GET /api/rides/user/:userId - Get all rides for a user
router.get('/user/:userId', rideController.getUserRides);

// GET /api/rides/:id - Get a specific ride
router.get('/:id', rideController.getRide);

module.exports = router;

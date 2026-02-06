/**
 * Reward Routes
 * 
 * Handles reward listings and redemption
 */

const express = require('express');
const router = express.Router();
const rewardController = require('../controllers/rewardController');

// GET /api/rewards - List all rewards
router.get('/', rewardController.getAllRewards);

// GET /api/rewards/:id - Get reward details
router.get('/:id', rewardController.getReward);

// POST /api/rewards/redeem - Redeem a reward
router.post('/redeem', rewardController.redeemReward);

// GET /api/rewards/redemptions/:userId - Get user's redemption history
router.get('/redemptions/:userId', rewardController.getUserRedemptions);

// POST /api/rewards/verify - Verify a QR code (for partner use)
router.post('/verify', rewardController.verifyRedemption);

module.exports = router;

const express = require('express');
const router = express.Router();
const rewardController = require('../controllers/rewardController');

router.get('/', rewardController.getAllRewards);
router.get('/redemptions/:userId', rewardController.getUserRedemptions);
router.get('/:id', rewardController.getReward);
router.post('/redeem', rewardController.redeemReward);
router.post('/verify', rewardController.verifyRedemption);

module.exports = router;

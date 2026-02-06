/**
 * Partner Routes
 * 
 * Handles partner (cafe) listings and details
 */

const express = require('express');
const router = express.Router();
const partnerController = require('../controllers/partnerController');

// GET /api/partners - List all partners
router.get('/', partnerController.getAllPartners);

// GET /api/partners/:id - Get partner details
router.get('/:id', partnerController.getPartner);

// GET /api/partners/:id/rewards - Get rewards for a partner
router.get('/:id/rewards', partnerController.getPartnerRewards);

module.exports = router;

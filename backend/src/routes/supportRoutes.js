const express = require('express');
const router = express.Router();
const supportController = require('../controllers/supportController');

router.post('/chat', supportController.chat);

module.exports = router;

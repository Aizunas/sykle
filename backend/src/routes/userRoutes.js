/**
 * User Routes
 * 
 * Handles user registration and profile endpoints
 */

const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// POST /api/users - Create a new user
router.post('/', userController.createUser);

// GET /api/users/:id - Get user by ID
router.get('/:id', userController.getUser);

// GET /api/users/:id/stats - Get user statistics
router.get('/:id/stats', userController.getUserStats);

// PUT /api/users/:id - Update user
router.put('/:id', userController.updateUser);

module.exports = router;

/**
 * User Routes
 */

const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// POST /api/users/check - Check if email exists (must be before /:id)
router.post('/check', userController.checkEmail);

// POST /api/users - Create user (or login if exists)
router.post('/', userController.createUser);

// GET /api/users/:id - Get user by ID
router.get('/:id', userController.getUser);

// GET /api/users/email/:email - Get user by email (for login)
router.get('/email/:email', userController.getUserByEmail);

// GET /api/users/:id/stats - Get user statistics
router.get('/:id/stats', userController.getUserStats);

// PUT /api/users/:id - Update user
router.put('/:id', userController.updateUser);

// DELETE /api/users/:id - Delete user account
router.delete('/:id', userController.deleteUser);

module.exports = router;
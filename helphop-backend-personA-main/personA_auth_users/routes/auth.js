// routes/auth.js
const express = require('express');

// middleware
const authenticate = require('../middleware/auth');

// controllers
const {
  registerUser,
  loginUser,
  loginRescuer,
  getProfile,
  updateProfile,
} = require('../controllers/authController');

const router = express.Router();

/* =============================
   AUTH ROUTES (PUBLIC)
   ============================= */

// Register a new user
router.post('/register', registerUser);

// Login a normal user using deviceId
router.post('/login', loginUser);

// Rescuer PIN login
router.post('/rescuer/login', loginRescuer);


/* =============================
   PROTECTED ROUTES (JWT REQUIRED)
   ============================= */

// Get logged-in user profile
router.get('/profile', authenticate, getProfile);

// Update logged-in user profile
router.put('/update', authenticate, updateProfile);


/* =============================
   EXPORT ROUTER
   ============================= */
module.exports = router;
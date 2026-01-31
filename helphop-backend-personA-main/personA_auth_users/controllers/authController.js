const jwt = require('jsonwebtoken');
const User = require('../models/User');

// ============================
// REGISTER USER
// ============================
exports.registerUser = async (req, res) => {
  try {
    const {
      name,
      phone,
      deviceId,
      public_key,
      bloodGroup,
      allergies,
    } = req.body;

    if (!name || !deviceId) {
      return res.status(400).json({
        error: 'name and deviceId required',
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ deviceId });
    if (existingUser) {
      return res.status(409).json({
        error: 'User already exists',
      });
    }

    const user = await User.create({
      name,
      phone: phone || '',
      deviceId,
      public_key: public_key || '',
      bloodGroup: bloodGroup || '',
      allergies: Array.isArray(allergies) ? allergies : [],
    });

    console.log('🟢 New user registered:', deviceId);

    return res.status(201).json({
      message: 'User registered successfully',
      user,
    });

  } catch (err) {
    console.error('❌ Register error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ============================
// LOGIN USER
// ============================
exports.loginUser = async (req, res) => {
  try {
    const { deviceId } = req.body;

    if (!deviceId) {
      return res.status(400).json({ error: 'deviceId required' });
    }

    const user = await User.findOne({ deviceId });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (!process.env.JWT_SECRET) {
      return res.status(500).json({
        error: 'JWT_SECRET not configured',
      });
    }

    const payload = { role: 'user', id: user._id };

    const token = jwt.sign(
      payload,
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.json({
      message: 'Login success',
      token,
      user,
    });

  } catch (err) {
    console.error('❌ Login error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ============================
// LOGIN RESCUER
// ============================
exports.loginRescuer = (req, res) => {
  const correctPin = process.env.RESCUER_PIN || '1234';
  const { pin } = req.body;

  if (!pin) {
    return res.status(400).json({ error: 'pin required' });
  }

  if (pin !== correctPin) {
    return res.status(401).json({ error: 'Invalid PIN' });
  }

  if (!process.env.JWT_SECRET) {
    return res.status(500).json({
      error: 'JWT_SECRET not configured',
    });
  }

  const payload = { role: 'rescuer' };

  const token = jwt.sign(
    payload,
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );

  res.json({
    message: 'Login success',
    token,
  });
};

// ============================
// GET PROFILE
// ============================
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ user });

  } catch (err) {
    console.error('❌ Get profile error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ============================
// UPDATE PROFILE
// ============================
exports.updateProfile = async (req, res) => {
  try {
    const allowedFields = [
      'name',
      'phone',
      'location',
      'bloodGroup',
      'allergies',
      'emergencyName',
      'emergencyPhone',
      'allowGPS',
    ];

    const updates = {};
    allowedFields.forEach((field) => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    });

    const user = await User.findByIdAndUpdate(
      req.user.id,
      updates,
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      message: 'Profile updated',
      user,
    });

  } catch (err) {
    console.error('❌ Update profile error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

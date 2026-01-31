const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: String,
  phone: String,
  deviceId: { type: String, unique: true },
  public_key: String,
  bloodGroup: String,
  allergies: [String],
  location: String,
  emergencyName: String,
  emergencyPhone: String,
  allowGPS: Boolean,
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
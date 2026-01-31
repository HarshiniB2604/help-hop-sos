const mongoose = require('../../helphop_backend/mongoose');

const AlertSchema = new mongoose.Schema({
  senderId: String,
  ciphertext: String,
  iv: String,
  tag: String,
  plaintextHash: { type: String, unique: true },
  metadata: Object
}, { timestamps: true });

module.exports = mongoose.model('Alert', AlertSchema);
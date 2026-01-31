const mongoose = require('../../helphop_backend/mongoose');

const KeySchema = new mongoose.Schema({
  ownerId: String,
  wrappedKey: String
}, { timestamps: true });

module.exports = mongoose.model('Key', KeySchema);
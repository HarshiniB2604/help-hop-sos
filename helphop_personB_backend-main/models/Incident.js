const mongoose = require('../../helphop_backend/mongoose'); // ✅ SAME INSTANCE

const IncidentSchema = new mongoose.Schema(
  {
    senderId: { type: String, required: true },
    message: String,
    lat: Number,
    lon: Number,
    distance: Number,
    direction: String,
    messages: [
      {
        from: String,
        text: String,
        timestamp: { type: Date, default: Date.now },
      }
    ],
    status: { type: String, default: 'pending' },
    rescuerId: String
  },
  { timestamps: true }
);

module.exports = mongoose.model('Incident', IncidentSchema);
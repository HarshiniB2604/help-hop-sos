const mongoose = require("mongoose");
const Incident = require("../models/Incident");
const {
  getDistance,
  getBearing,
  bearingToDirection,
} = require("../utils/geoUtils");

// Static rescue center
const RESCUE_CENTER = {
  lat: 12.9716,
  lon: 77.5946,
};

/* ================================
   CREATE INCIDENT
================================ */
exports.createIncident = async (req, res) => {
  try {
    const { senderId, message, encryptedPayload, lat, lon } = req.body;
    const finalMessage = message || encryptedPayload;

    console.log("📥 Incoming SOS from device:", senderId);
    console.log("📍 Location:", lat, lon);

    if (!senderId || typeof lat !== "number" || typeof lon !== "number") {
      console.log("❌ Invalid SOS payload");
      return res.status(400).json({
        error: "senderId, lat and lon are required",
      });
    }

    // 🔁 DUPLICATE CHECK (same device, same location, still pending)
    const existing = await Incident.findOne({
      senderId,
      lat,
      lon,
      status: "pending",
    });

    if (existing) {
      console.log("⚠️ Duplicate SOS ignored for device:", senderId);
      return res.status(200).json({ success: true, incident: existing });
    }

    const distanceKm = getDistance(
      lat,
      lon,
      RESCUE_CENTER.lat,
      RESCUE_CENTER.lon
    );

    const bearing = getBearing(
      lat,
      lon,
      RESCUE_CENTER.lat,
      RESCUE_CENTER.lon
    );
    const direction = bearingToDirection(bearing);

    console.log(
      `📏 Distance: ${distanceKm.toFixed(2)} km | Direction: ${direction}`
    );

    const incident = await Incident.create({
      senderId,
      message: finalMessage,
      lat,
      lon,
      distance: distanceKm,
      direction,
      status: "pending",
    });

    console.log("🆕 Incident CREATED:", incident._id.toString());

    res.status(201).json({ success: true, incident });
  } catch (err) {
    console.error("❌ Create incident error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
};

/* ================================
   GET PENDING INCIDENTS
================================ */
exports.getPendingIncidents = async (req, res) => {
  try {
    const incidents = await Incident.find({ status: "pending" })
      .sort({ createdAt: -1 });

    console.log(`📡 Rescuer fetched ${incidents.length} pending incidents`);

    res.json(incidents);
  } catch (err) {
    console.error("❌ Fetch pending incidents failed:", err);
    res.status(500).json({ error: "Fetch failed" });
  }
};

/* ================================
   ACCEPT INCIDENT
================================ */
exports.acceptIncidentById = async (req, res) => {
  try {
    const incident = await Incident.findByIdAndUpdate(
      req.params.id,
      { status: "accepted" },
      { new: true }
    );

    if (!incident) {
      console.log("❌ Incident not found for ACCEPT:", req.params.id);
      return res.status(404).json({ error: "Incident not found" });
    }

    console.log("🤝 Incident ACCEPTED:", incident._id.toString());

    res.json({ success: true, incident });
  } catch (err) {
    console.error("❌ Accept failed:", err);
    res.status(500).json({ error: "Accept failed" });
  }
};

/* ================================
   RESOLVE INCIDENT
================================ */
exports.resolveIncident = async (req, res) => {
  try {
    console.log("🟡 RESOLVE REQUEST RECEIVED:", req.body);

    const { incidentId } = req.body;

    if (!incidentId) {
      console.log("❌ Missing incidentId");
      return res.status(400).json({ error: "incidentId required" });
    }

    const incident = await Incident.findByIdAndUpdate(
      incidentId,
      { status: "resolved" },
      { new: true }
    );

    if (!incident) {
      console.log("❌ Incident not found:", incidentId);
      return res.status(404).json({ error: "Incident not found" });
    }

    console.log("✅ INCIDENT RESOLVED:", incident._id);

    res.json({ success: true, incident });
  } catch (err) {
    console.error("❌ Resolve failed:", err);
    res.status(500).json({ error: "Resolve failed" });
  }
};

/* ================================
   GET INCIDENT BY ID
================================ */
exports.getIncidentById = async (req, res) => {
  try {
    const incident = await Incident.findById(req.params.id);

    if (!incident) {
      console.log("❌ Incident not found:", req.params.id);
      return res.status(404).json({ error: "Incident not found" });
    }

    console.log("🔍 Incident FETCHED:", incident._id.toString());

    res.json(incident);
  } catch (err) {
    console.error("❌ Fetch failed:", err);
    res.status(500).json({ error: "Fetch failed" });
  }
};

/* ================================
   ADD CHAT MESSAGE
================================ */
exports.addMessage = async (req, res) => {
  try {
    const { text, from } = req.body;

    const incident = await Incident.findByIdAndUpdate(
      req.params.id,
      {
        $push: {
          messages: { text, from, timestamp: new Date() },
        },
      },
      { new: true }
    );

    if (!incident) {
      console.log("❌ Incident not found for CHAT:", req.params.id);
      return res.status(404).json({ error: "Incident not found" });
    }

    console.log(
      `💬 New CHAT message on Incident ${incident._id.toString()} from ${from}`
    );

    res.json(incident);
  } catch (err) {
    console.error("❌ Chat failed:", err);
    res.status(500).json({ error: "Chat failed" });
  }
};

/* ================================
   DEBUG
================================ */
exports.getAllIncidents = async (req, res) => {
  const incidents = await Incident.find();
  console.log(`🧪 DEBUG: Total incidents = ${incidents.length}`);
  res.json({ incidents });
};

exports.getIncidentsByUser = async (req, res) => {
  const incidents = await Incident.find({ senderId: req.params.userId });
  console.log(
    `👤 User ${req.params.userId} has ${incidents.length} incidents`
  );
  res.json({ incidents });
};
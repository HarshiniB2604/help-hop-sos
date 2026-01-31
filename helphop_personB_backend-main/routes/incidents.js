const express = require("express");
const router = express.Router();

const controller = require("../controllers/incidentsController");

// Health check
router.get("/", (req, res) => {
  res.send("Incidents API running");
});

// CREATE incident (from victim / crypto service)
router.post("/", controller.createIncident);

// FETCH pending incidents (rescuer dashboard)
router.get("/pending", controller.getPendingIncidents);

// FETCH single incident (chat screen)
router.get("/:id", controller.getIncidentById);

// ACCEPT incident
router.patch("/:id/accept", controller.acceptIncidentById);

// RESOLVE incident
router.post("/resolve", controller.resolveIncident);

// ADD chat message
router.post("/:id/message", controller.addMessage);

module.exports = router;
const express = require("express");
const router = express.Router();
const controller = require("../controller_crypto");

// Send encrypted SOS
router.post("/alerts/send", controller.sendAlert);

// Fetch alerts (rescuer feed / debug)
router.get("/alerts/feed", controller.getFeed);

module.exports = router;


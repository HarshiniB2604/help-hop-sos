require("dotenv").config();
console.log("Loaded MONGO_URI =", process.env.MONGO_URI);
const express = require("express");
const mongoose = require('mongoose');
const cors = require("cors");

const incidentRoutes = require("./routes/incidents");

const app = express();
console.log("🔥 PERSON B APP.JS LOADED 🔥");
// Middlewares
app.use(cors());
app.use(express.json());

// Routes
app.use("/incidents", incidentRoutes);

// MONGO CONNECTION
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => {
    console.log("✅ MongoDB Connected");

    // app.post("/incidents", (req, res) => {
    //   console.log("📥 New incident received from Person C:");
    //   console.log(req.body);

    //   res.json({ ok: true });
    // });

    // Start Server
    app.listen(process.env.PORT, () => {
      console.log(`🚀 Server running on port ${process.env.PORT}`);
    });
  })
  .catch((err) => console.log("❌ MongoDB Error:", err));

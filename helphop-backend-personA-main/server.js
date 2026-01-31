const mongoose = require('mongoose');
require('dotenv').config();
require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// import routes
const authRoutes = require('./personA_auth_users/routes/auth');

// health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'Backend running OK!', time: new Date() });
});

// mount routes
app.use('/auth', authRoutes);
mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log('MongoDB connected');
  })
  .catch((err) => {
    console.error('MongoDB connection error:', err.message);
  });
// start server
app.listen(3000, () => {
  console.log('Server running at http://localhost:3000');
});
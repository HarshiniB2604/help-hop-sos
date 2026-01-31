require('dotenv').config();

const express = require('express');
const mongoose = require('./mongoose'); // ✅ IMPORTANT
const cors = require('cors');
const helmet = require('helmet');
const http = require('http');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));

app.get('/api/health', (req, res) => {
  res.json({ ok: true });
});

const PORT = process.env.PORT || 4000;

mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log('✅ MongoDB connected (SINGLE CONNECTION)');
    console.log('📌 DB name:', mongoose.connection.name);

    // 🔥 REGISTER MODELS (AFTER CONNECT)
    require('../personC_crypto_alerts/models/Alert');
    require('../personC_crypto_alerts/models/Key');
    require('../helphop_personB_backend-main/models/Incident');

    console.log('📦 All models registered');

    // 🔥 LOAD ROUTES
    app.use('/auth',
      require('../helphop-backend-personA-main/personA_auth_users/routes/auth')
    );
    app.use('/incidents',
      require('../helphop_personB_backend-main/routes/incidents')
    );
    app.use('/personC',
      require('../personC_crypto_alerts/routes_crypto')
    );

    const server = http.createServer(app);
    require('../personC_crypto_alerts/realtime').init(server);

    app.listen(PORT, '0.0.0.0',() => {
      console.log(`🚀 Integrated backend running on ${PORT}`);
    });
  })
  .catch(err => {
    console.error('❌ Mongo connection failed:', err);
    process.exit(1);
  });
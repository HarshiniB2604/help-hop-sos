require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const http = require('http');

const cryptoRoutes = require('./routes_crypto');
const realtime = require('./realtime');

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));

app.use('/personC', cryptoRoutes);

const server = http.createServer(app);

const PORT = process.env.PORT || 4001;

// connect to mongo
mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log('Mongo connected')
    const io = realtime.init(server)
    server.listen(PORT, () => console.log('Person C service running on', PORT))
  })
  .catch(err => {
    console.error('mongo connect err', err)
    process.exit(1)
  })

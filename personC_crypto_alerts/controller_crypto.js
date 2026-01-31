const Key = require('./models/Key');
const Alert = require('./models/Alert');
const axios = require("axios");

const {
  generateSymKey,
  wrapKey,
  unwrapKey,
  aesGcmEncrypt,
  aesGcmDecrypt
} = require('./crypto_logic');

/* ===========================
   CREATE KEY
=========================== */
async function createKey(req, res) {
  try {
    const { ownerId } = req.body;
    if (!ownerId) return res.status(400).json({ error: 'ownerId required' });

    const symKey = generateSymKey();
    const wrapped = wrapKey(symKey);

    const keyDoc = await Key.create({ ownerId, wrappedKey: wrapped });
    return res.json({ keyId: keyDoc._id });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'server error' });
  }
}

/* ===========================
   ENCRYPT
=========================== */
async function encryptWithOwnerKey(req, res) {
  try {
    const { ownerId, plaintext } = req.body;
    if (!ownerId || plaintext === undefined)
      return res.status(400).json({ error: 'ownerId and plaintext required' });

    const keyDoc = await Key.findOne({ ownerId }).sort({ createdAt: -1 });
    if (!keyDoc) return res.status(404).json({ error: 'key not found' });

    const symKey = unwrapKey(keyDoc.wrappedKey);
    const encrypted = aesGcmEncrypt(Buffer.from(String(plaintext)), symKey);

    return res.json(encrypted);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'server error' });
  }
}

/* ===========================
   DECRYPT
=========================== */
async function decryptWithOwnerKey(req, res) {
  try {
    const { ownerId, iv, ciphertext, tag } = req.body;
    if (!ownerId || !iv || !ciphertext || !tag)
      return res.status(400).json({ error: 'missing fields' });

    const keyDoc = await Key.findOne({ ownerId }).sort({ createdAt: -1 });
    if (!keyDoc) return res.status(404).json({ error: 'key not found' });

    const symKey = unwrapKey(keyDoc.wrappedKey);
    const plain = aesGcmDecrypt({ iv, ciphertext, tag }, symKey);

    return res.json({ plaintext: plain.toString() });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'decryption failed' });
  }
}

/* ===========================
   SEND ALERT (MAX 5 SOS)
=========================== */
async function sendAlert(req, res) {
  try {
    const { senderId, plaintext, metadata } = req.body;

    if (!senderId || plaintext === undefined) {
      return res.status(400).json({ error: "senderId & plaintext required" });
    }

    // 🔒 LIMIT: MAX 5 SOS PER USER
    const sosCount = await Alert.countDocuments({ senderId });

    if (sosCount >= 10) {
      return res.status(429).json({
        ok: false,
        message: "SOS limit reached (max 5 allowed)"
      });
    }

    // 🔐 Encrypt message
    const alertKey = generateSymKey();
    const encrypted = aesGcmEncrypt(
      Buffer.from(String(plaintext)),
      alertKey
    );

    // 💾 Store alert
    const alertDoc = await Alert.create({
      senderId,
      ciphertext: encrypted.ciphertext,
      iv: encrypted.iv,
      tag: encrypted.tag,
      metadata: metadata || {},
      createdAt: new Date(),
    });

    console.log(`🚨 SOS ${sosCount + 1}/5 stored for ${senderId}`);

    // 🔗 Forward to Incident Service
    try {
      await axios.post('${process.env.BASE_BACKEND_URL}/incidents', {
        senderId,
        message: plaintext,
        lat: metadata?.lat,
        lon: metadata?.lon,
        timestamp: Date.now(),
      });
    } catch (err) {
      console.error("⚠️ Forwarding to incidents failed:", err.message);
    }

    // 📡 Realtime broadcast
    const io = require("./realtime").getIo();
    if (io) {
      io.emit("new_alert", {
        id: alertDoc._id,
        senderId,
        metadata: alertDoc.metadata,
        createdAt: alertDoc.createdAt,
      });
    }

    return res.json({
      ok: true,
      alertId: alertDoc._id,
      count: sosCount + 1
    });

  } catch (err) {
    console.error("ALERT ERROR:", err);
    return res.status(500).json({ error: "send failed" });
  }
}

/* ===========================
   ALERT FEED
=========================== */
async function getFeed(req, res) {
  try {
    const alerts = await Alert.find()
      .sort({ createdAt: -1 })
      .limit(50);
    return res.json({ alerts });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'server error' });
  }
}

module.exports = {
  createKey,
  encryptWithOwnerKey,
  decryptWithOwnerKey,
  sendAlert,
  getFeed
};
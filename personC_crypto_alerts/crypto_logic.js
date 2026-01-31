const crypto = require('crypto');

const MASTER_KEY = Buffer.from(process.env.MASTER_KEY_BASE64, 'base64'); // 32 bytes

if (MASTER_KEY.length !== 32) {
  throw new Error('MASTER_KEY must decode to 32 bytes');
}

// Utility: AES-256-GCM encrypt
function aesGcmEncrypt(plainBuffer, keyBuffer) {
  const iv = crypto.randomBytes(12); // 12 bytes recommended for GCM
  const cipher = crypto.createCipheriv('aes-256-gcm', keyBuffer, iv);
  const ciphertext = Buffer.concat([cipher.update(plainBuffer), cipher.final()]);
  const tag = cipher.getAuthTag();
  return {
    iv: iv.toString('base64'),
    ciphertext: ciphertext.toString('base64'),
    tag: tag.toString('base64')
  };
}

// Utility: AES-256-GCM decrypt
function aesGcmDecrypt({iv, ciphertext, tag}, keyBuffer) {
  const ivBuf = Buffer.from(iv, 'base64');
  const ctBuf = Buffer.from(ciphertext, 'base64');
  const tagBuf = Buffer.from(tag, 'base64');

  const decipher = crypto.createDecipheriv('aes-256-gcm', keyBuffer, ivBuf);
  decipher.setAuthTag(tagBuf);
  const plain = Buffer.concat([decipher.update(ctBuf), decipher.final()]);
  return plain; // Buffer
}

// Generate a new random symmetric key (32 bytes)
function generateSymKey() {
  return crypto.randomBytes(32); // Buffer
}

// Wrap (encrypt) a symmetric key with MASTER_KEY
function wrapKey(symKeyBuffer) {
  // we use AES-GCM with MASTER_KEY to wrap keys
  const wrapped = aesGcmEncrypt(symKeyBuffer, MASTER_KEY);
  // return JSON string base64 fields
  return JSON.stringify(wrapped);
}

// Unwrap (decrypt) wrapped key with MASTER_KEY
function unwrapKey(wrappedJson) {
  const parsed = JSON.parse(wrappedJson);
  const keyBuf = aesGcmDecrypt(parsed, MASTER_KEY); // Buffer
  return keyBuf; // Buffer (32 bytes)
}

module.exports = {
  aesGcmEncrypt,
  aesGcmDecrypt,
  generateSymKey,
  wrapKey,
  unwrapKey
};

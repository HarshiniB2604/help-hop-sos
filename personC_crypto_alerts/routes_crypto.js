const express = require('express');
const router = express.Router();
const ctrl = require('./controller_crypto');

router.post('/key/create', ctrl.createKey);
router.post('/crypto/encrypt', ctrl.encryptWithOwnerKey);
router.post('/crypto/decrypt', ctrl.decryptWithOwnerKey);
router.post('/alerts/send', ctrl.sendAlert);
router.get('/alerts/feed', ctrl.getFeed);

module.exports = router;

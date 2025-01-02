const express = require('express');
const router = express.Router();
const emotionController = require('../controllers/emotions');

router.post('/', emotionController.createEmotion);
router.get('/', emotionController.getAllEmotions);

module.exports = router;

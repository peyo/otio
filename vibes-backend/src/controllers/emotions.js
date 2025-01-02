const prisma = require('../config/db');

const emotionController = {
    // Create new emotion
    createEmotion: async (req, res) => {
        try {
            const { type, intensity } = req.body;
            
            // Validate emotion type
            const validEmotions = ['Happy', 'Sad', 'Anxious', 'Angry', 'Neutral'];
            if (!validEmotions.includes(type)) {
                return res.status(400).json({
                    success: false,
                    message: 'Invalid emotion type'
                });
            }

            // Validate intensity for non-neutral emotions
            if (type !== 'Neutral' && (!intensity || intensity < 1 || intensity > 3)) {
                return res.status(400).json({
                    success: false,
                    message: 'Intensity must be between 1 and 3 for non-neutral emotions'
                });
            }

            const emotion = await prisma.emotion.create({
                data: {
                    type,
                    intensity: type === 'Neutral' ? 0 : intensity
                }
            });

            res.status(201).json({
                success: true,
                data: emotion
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                message: 'Failed to create emotion',
                error: error.message
            });
        }
    },

    // Get all emotions
    getAllEmotions: async (req, res) => {
        try {
            const emotions = await prisma.emotion.findMany({
                orderBy: {
                    createdAt: 'desc'
                }
            });
            
            res.json({
                success: true,
                data: emotions
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                message: 'Failed to fetch emotions',
                error: error.message
            });
        }
    }
};

module.exports = emotionController;

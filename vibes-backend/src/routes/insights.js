const express = require('express');
const router = express.Router();
const axios = require('axios');

// Helper function to generate the prompt
const generatePrompt = (emotions) => {
    const emotionSummary = emotions
        .map(emotion => `- ${emotion.type} (Intensity: ${emotion.intensity}) on ${emotion.date}`)
        .join('\n');

    return `
        Based on the following emotional data for the past week:
        
        ${emotionSummary}
        
        Generate 3 meaningful insights about the emotional patterns. Each insight MUST follow this exact format:
        emoji|title|description

        Requirements for each insight:
        1. Emoji must be relevant to the insight's message (e.g., 🌟 for positive trends, 🧘‍♀️ for mindfulness, etc.)
        2. Title should be short and clear (2-4 words)
        3. Description should be encouraging and supportive (max 2 sentences)
        4. Focus on patterns and trends
        5. Provide gentle suggestions when relevant

        Example format:
        🌱|Growth Mindset|Your emotional awareness is growing stronger each day.
        
        Do not number the insights or add any additional formatting.
    `;
};

// POST /api/insights
router.post('/', async (req, res) => {
    try {
        const { emotions } = req.body;

        // Validate emotions data
        if (!emotions || !Array.isArray(emotions) || emotions.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Valid emotions data is required',
            });
        }

        // Generate prompt
        const prompt = generatePrompt(emotions);

         // Log the prompt for debugging
         console.log('Generated Prompt:', prompt);

        // Call OpenAI API
        const openAIResponse = await axios.post(
            'https://api.openai.com/v1/chat/completions',
            {
                model: 'gpt-3.5-turbo', // Adjust as needed
                messages: [{ role: 'user', content: prompt }],
                max_tokens: 150,
            },
            {
                headers: {
                    Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
                    'Content-Type': 'application/json',
                },
            }
        );

        // Log the response from GPT
        console.log('GPT Response:', openAIResponse.data);

        // Extract insights from OpenAI response
        const rawOutput = openAIResponse.data.choices[0].message.content.trim();
        const insights = rawOutput
            .split('\n')
            .map(line => {
                const [emoji, title, description] = line.split('|').map(part => part.trim());
                return { emoji, title, description };
            })
            .filter(insight => insight.title && insight.description);

        return res.json({
            success: true,
            insights,
        });
    } catch (error) {
        console.error('Error generating insights:', error.message);

        // Handle specific error cases
        if (error.response) {
            // Error from OpenAI API
            console.error('OpenAI API Error:', error.response.data);
            return res.status(error.response.status).json({
                success: false,
                message: 'Failed to generate insights',
                error: error.response.data.error || 'Unexpected error from OpenAI API',
            });
        } else {
            // General server error
            return res.status(500).json({
                success: false,
                message: 'Internal server error',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined,
            });
        }
    }
});

module.exports = router;

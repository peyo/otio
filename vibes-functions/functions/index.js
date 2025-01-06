const functions = require('firebase-functions');
const axios = require('axios');
const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp();

exports.generateInsights = functions.https.onCall(async (data, context) => {
    console.log('Function started');
    
    // Fix auth context handling - but don't try to log the entire data object
    const auth = context.auth || (data.auth ? { uid: data.auth.uid, token: data.auth.token } : null);
    
    console.log('Debug: 🔍 Auth context:', {
        hasAuth: !!auth,
        uid: auth?.uid,
        email: auth?.token?.email
    });

    // Verify auth
    if (!auth) {
        console.error('Debug: ❌ No auth context');
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }

    try {
        // Extract emotions from the correct location in data
        const emotions = data.data?.emotions || [];
        console.log('Debug: 📊 Processing emotions:', JSON.stringify(emotions));
        
        if (!Array.isArray(emotions) || emotions.length === 0) {
            throw new functions.https.HttpsError(
                'invalid-argument',
                'Valid emotions data is required'
            );
        }

        // Get OpenAI key directly from process.env
        const openAIKey = process.env.OPENAI_API_KEY;
        if (!openAIKey) {
            console.error('Debug: ❌ Missing OpenAI API key. Available env vars:', Object.keys(process.env));
            throw new functions.https.HttpsError('failed-precondition', 'OpenAI API key not configured');
        }

        // Format emotions for the prompt
        const emotionsText = emotions
            .map(e => `- ${e.type} (Intensity: ${e.intensity}) on ${e.date}`)
            .join('\n');

        const prompt = `As an empathetic AI, analyze these emotions deeply:

${emotionsText}

Consider:
- Patterns and relationships between emotions
- Intensity levels and their significance
- Daily emotional balance
- Potential impacts on well-being

Provide 3 insights that are specific, empathetic, and actionable. Each should reference the actual emotions shown.

Format: emoji|title|description
Example: 🌊|Emotional Balance|Your mix of joy (3) and anxiety (2) shows emotional complexity...

Keep descriptions personal and include gentle guidance.`;

        console.log('Debug: 📤 Sending request to OpenAI');
        
        const openAIResponse = await axios.post(
            'https://api.openai.com/v1/chat/completions',
            {
                model: 'gpt-3.5-turbo',
                messages: [{ role: 'user', content: prompt }],
                temperature: 0.7,
                max_tokens: 400,
            },
            {
                headers: {
                    'Authorization': `Bearer ${openAIKey}`,
                    'Content-Type': 'application/json',
                },
            }
        );

        console.log('Debug: 📥 OpenAI response received');

        const rawOutput = openAIResponse.data.choices[0].message.content.trim();
        console.log('Debug: 📝 Processing output:', rawOutput);

        const insights = rawOutput
            .split('\n')
            .map(line => {
                const [emoji, title, description] = line.split('|').map(part => part.trim());
                return { emoji, title, description };
            })
            .filter(insight => insight.emoji && insight.title && insight.description);

        console.log('Debug: ✅ Final insights:', JSON.stringify(insights));
        return { success: true, insights };

    } catch (error) {
        console.error('Function error:', error.message);
        if (error.response) {
            console.error('OpenAI API error:', error.response.data);
        }
        throw new functions.https.HttpsError(
            'internal', 
            `Error processing insights: ${error.message}`
        );
    }
});
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
            throw new functions.https.HttpsError('invalid-argument', 'Valid emotions data is required');
        }

        // Get OpenAI key directly from process.env
        const openAIKey = process.env.OPENAI_API_KEY;
        if (!openAIKey) {
            console.error('Debug: ❌ Missing OpenAI API key. Available env vars:', Object.keys(process.env));
            throw new functions.https.HttpsError('failed-precondition', 'OpenAI API key not configured');
        }

        const db = admin.database();
        const userRef = db.ref(`users/${auth.uid}/insights`);

        // Check the latest insights and their timestamp
        const snapshot = await userRef.orderByChild('timestamp').limitToLast(3).once('value');
        let lastTimestamp = 0;
        let insights = [];
        snapshot.forEach(childSnapshot => {
            const insight = childSnapshot.val();
            lastTimestamp = Math.max(lastTimestamp, insight.timestamp); // Get the most recent timestamp
            insights.push(insight);
        });

        const currentTime = Date.now();
        const cooldownPeriod = 3 * 60 * 60 * 1000; // 3 hours in milliseconds

        // Fix: Check if there's a valid lastTimestamp and if we're within cooldown period
        if (lastTimestamp > 0 && currentTime - lastTimestamp < cooldownPeriod) {
            const cooldownRemaining = cooldownPeriod - (currentTime - lastTimestamp);
            console.log('Debug: ⏳ Cooldown active, returning existing insights');
            console.log('Debug: Cooldown remaining:', cooldownRemaining);
            return { 
                success: true, 
                insights: insights.slice(-3), // Return last 3 insights
                cooldownRemaining 
            };
        }

        // If there are fewer than three insights, generate new ones
        if (insights.length < 3) {
            console.log('Debug: Generating new insights to ensure three are available');
            // Call the function to generate new insights here
            // Example: const newInsights = await generateNewInsights();
            // insights.push(...newInsights);
        }

        // Ensure there are exactly three insights
        while (insights.length < 3) {
            insights.push({
                title: 'Generated Insight',
                description: 'This is a generated insight to ensure three insights are always returned.',
                timestamp: currentTime
            });
        }

        // Format emotions for the prompt
        const emotionsText = emotions
            .map(e => `- ${e.type} (Intensity: ${e.intensity}) on ${e.date}`)
            .join('\n');

            const prompt = `As an empathetic AI, analyze these emotions deeply:

                ${emotionsText}
                
                Focus on these areas for your insights:

                The first insight should be a trend-based feedback insight: Identify explicit temporal patterns in the data, such as daily or weekly trends.
                - Use specific language to make insights relatable (e.g., "over the past week," "in the evenings").
                - Highlight trends in emotion frequency, intensity, or timing.
                
                The second insight should be a self-reflection insight: Pose general, open-ended questions to encourage self-awareness and exploration.
                - Frame questions to help users connect with their experiences (e.g., "What was happening when you felt this way?" or "What helped you feel calmer during similar times?").
                
                The third insight should be a general tips insight: Provide universal, actionable advice tailored to the emotions recorded for the week.
                - Align tips with recorded emotions (e.g., for anxiety: "Try a short breathing exercise," for happiness: "Reflect on what brought you joy today").
                - Avoid assumptions about specific triggers, focusing on practical and empathetic guidance.
                
                **Instruction**: Generate exactly **three** insights, one for each focus area above.
                
                **Format**:
                Example: Your anxiety levels have been higher in the evenings. Consider journaling or practicing mindfulness before bed.
                
                Keep insights specific, empathetic, and actionable, referencing the actual emotions provided. Do not number them.`;    
            
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

        insights = rawOutput
            .split('\n\n')
            .map((description, index) => {
                console.log('Debug: Processing insight:', description);
                const emojiNames = ['emotional-pattern', 'self-reflection', 'encouraging-tip'];
                const titles = ['weekly emotional patterns', 'self-reflection', 'encouraging tips'];
                
                const emojiName = emojiNames[index % emojiNames.length];
                const title = titles[index % titles.length];
                
                return {
                    emojiName,
                    title,
                    description: description.trim().toLowerCase(),
                    timestamp: currentTime
                };
            })
            .filter(insight => insight.emojiName && insight.title && insight.description);

        // Store the new insights in the database
        await userRef.set(insights);

        console.log('Debug: ✅ Final insights:', JSON.stringify(insights));
        return { success: true, insights, cooldownRemaining: 0 };

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
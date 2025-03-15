const functions = require("firebase-functions/v2");
const { defineSecret } = require("firebase-functions/params");
const axios = require("axios");
const admin = require("firebase-admin");

// Initialize Firebase Admin
admin.initializeApp();

const openAIKey = defineSecret("OPENAI_API_KEY");

exports.generateInsights = functions.https.onCall(
  { secrets: [openAIKey] },
  async (data, context) => {
    console.log("Function started");

    // Fix auth context handling - but don't try to log the entire data object
    const auth =
      context.auth || (data.auth ? { uid: data.auth.uid, token: data.auth.token } : null);

    console.log("Debug: 🔍 Auth context:", {
      hasAuth: !!auth,
      uid: auth?.uid,
      email: auth?.token?.email,
    });

    // Verify auth
    if (!auth) {
      console.error("Debug: ❌ No auth context");
      throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }

    try {
      // Extract emotions from the correct location in data
      const emotions = data.data?.emotions || [];
      console.log("Debug: 📊 Processing emotions:", JSON.stringify(emotions));

      if (!Array.isArray(emotions) || emotions.length === 0) {
        throw new functions.https.HttpsError("invalid-argument", "Valid emotions data is required");
      }

      // Get OpenAI key from environment variables
      const apiKey = await openAIKey.value();
      if (!apiKey) {
        console.error("Debug: ❌ Missing OpenAI API key.");
        throw new functions.https.HttpsError("failed-precondition", "OpenAI API key not configured");
      }

      const db = admin.database();
      const userRef = db.ref(`users/${auth.uid}/insights`);

      // Check the latest insights and their timestamp
      const snapshot = await userRef.orderByChild("timestamp").limitToLast(3).once("value");
      let lastTimestamp = 0;
      let insights = [];
      snapshot.forEach((childSnapshot) => {
        const insight = childSnapshot.val();
        lastTimestamp = Math.max(lastTimestamp, insight.timestamp); // Get the most recent timestamp
        insights.push(insight);
      });

      const currentTime = Date.now();
      const cooldownPeriod = 3 * 60 * 60 * 1000; // 3 hours in milliseconds "3 * 60 * 60 * 1000"

      // Fix: Check if there's a valid lastTimestamp and if we're within cooldown period
      if (lastTimestamp > 0 && currentTime - lastTimestamp < cooldownPeriod) {
        const cooldownRemaining = cooldownPeriod - (currentTime - lastTimestamp);
        console.log("Debug: ⏳ Cooldown active, returning existing insights");
        console.log("Debug: Cooldown remaining:", cooldownRemaining);
        return {
          success: true,
          insights: insights.slice(-3), // Return last 3 insights
          cooldownRemaining,
        };
      }

      // If there are fewer than three insights, generate new ones
      if (insights.length < 3) {
        console.log("Debug: Generating new insights to ensure three are available");
        // Call the function to generate new insights here
        // Example: const newInsights = await generateNewInsights();
        // insights.push(...newInsights);
      }

      // Ensure there are exactly three insights
      while (insights.length < 3) {
        insights.push({
          title: "Generated Insight",
          description: "This is a generated insight to ensure three insights are always returned.",
          timestamp: currentTime,
        });
      }

      // Format emotions for the prompt
      const emotionsText = emotions
        .map((e) => `- ${e.type} on ${e.date}`)
        .join("\n");

        const prompt = `As an empathetic AI, analyze these emotions deeply and compassionately.

        ${emotionsText}
        
        Focus on the following categories of insights:
        
        The first category is a trend-based feedback insight:
        - Provide an observational statement about explicit temporal patterns in the data, such as daily or weekly trends.
        - Do not ask questions in this insight. Focus on giving the user a clear, empathetic summary of their trends.
        - Use specific language to make insights relatable (e.g., "over the past week," "in the evenings").
        - Highlight patterns in emotion frequency or timing in a clear and supportive tone.
        
        The second category is a self-reflection insight:
        - Pose general, open-ended questions to encourage self-awareness and personal exploration.
        - Use specific language to make the reflection relatable (e.g., "over the past week," "in the evenings").
        - Frame questions to help users connect with their experiences (e.g., "What was happening when you felt this way?" or "What helped you feel calmer during similar times?").
        - Maintain a gentle, non-judgmental tone.
        
        The third category is a general tips insight:
        - Provide universal, actionable advice tailored to the emotions recorded for the week.
        - Align tips with recorded emotions (e.g., for anxiety: "Try a short breathing exercise," for happiness: "Reflect on what brought you joy today").
        - Frame suggestions gently, using language like "consider," "you might try," or "it could be helpful to..."
        - Avoid assumptions about specific triggers, focusing on practical and empathetic guidance.
        
        ---
        
        In each category, incorporate techniques from evidence-based therapeutic approaches to enhance the insights:
        - From CBT: Help users reflect on thought patterns linked to their emotions and consider alternative perspectives or coping strategies.
        - From Positive Psychology: Highlight positive moments and strengths, and encourage gratitude or reflection on what brings joy.
        - From Mindfulness: Encourage present-moment awareness and gentle, non-judgmental observation of emotions.
        
        Maintain a warm, empathetic tone that fosters self-compassion and growth.
        
        ---
        
        Instructions:
        - Assume the emotion data spans the past week unless stated otherwise.
        - Generate exactly three insights, one for each focus area above.
        - Keep insights specific, empathetic, and actionable, referencing the actual emotions provided.
        - Keep each insight concise but meaningful, focusing on clarity and impact.
        - Maintain a warm, supportive, and non-judgmental tone.
        - Do not ask questions in the first or third insights. Only the second insight should contain open-ended questions.
        - Do not number the insights.
        - Do not lead the insights with any symbols.
        
        Your goal is to provide a supportive, thoughtful experience that helps users reflect on their emotions and discover helpful patterns and strategies.
        
        Format:
        Example: Your anxiety levels have been higher in the evenings. Consider journaling or practicing mindfulness before bed.`;

      console.log("Debug: 📤 Sending request to OpenAI");

      const openAIResponse = await axios.post(
        "https://api.openai.com/v1/chat/completions",
        {
          model: "gpt-3.5-turbo",
          messages: [{ role: "user", content: prompt }],
          temperature: 0.7,
          max_tokens: 400,
        },
        {
          headers: {
            "Authorization": `Bearer ${apiKey}`,
            "Content-Type": "application/json",
          },
        }
      );

      console.log("Debug: 📥 OpenAI response received");

      const rawOutput = openAIResponse.data.choices[0].message.content.trim();
      console.log("Debug: 📝 Processing output:", rawOutput);

      insights = rawOutput
        .split("\n\n")
        .map((description, index) => {
          console.log("Debug: Processing insight:", description);
          const emojiNames = ["emotional-pattern", "self-reflection", "encouraging-tip"];
          const titles = ["weekly emotional patterns", "self-reflection", "encouraging tips"];

          const emojiName = emojiNames[index % emojiNames.length];
          const title = titles[index % titles.length];

          return {
            emojiName,
            title,
            description: description.trim().toLowerCase(),
            timestamp: currentTime,
          };
        })
        .filter((insight) => insight.emojiName && insight.title && insight.description);

      // Store the new insights in the database
      await userRef.set(insights);

      console.log("Debug: ✅ Final insights:", JSON.stringify(insights));
      return { success: true, insights, cooldownRemaining: 0 };
    } catch (error) {
      console.error("Function error:", error.message);
      if (error.response) {
        console.error("OpenAI API error:", error.response.data);
      }
      throw new functions.https.HttpsError(
        "internal",
        `Error processing insights: ${error.message}`
      );
    }
  }
);
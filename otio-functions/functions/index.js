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
        .sort((a, b) => a.timestamp - b.timestamp)  // Sort by timestamp
        .map((e) => {
          const date = new Date(e.timestamp).toLocaleString();
          const energyLevel = e.energy_level ? ` (energy: ${e.energy_level})` : '';
          const log = e.log ? `\n   log: ${e.log}` : '';
          return `- ${e.emotion}${energyLevel} on ${date}${log}`;
        })
        .join("\n");

      // Validate the indexed data structure
      const invalidEmotions = emotions.filter(e => 
        !e.timestamp || 
        typeof e.timestamp !== 'number' ||
        (e.energy_level && (typeof e.energy_level !== 'number' || e.energy_level < 1 || e.energy_level > 5)) ||
        (e.log && typeof e.log !== 'string')
      );
      
      if (invalidEmotions.length > 0) {
        console.error("Debug: ❌ Invalid emotion data structure:", invalidEmotions);
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Invalid emotion data structure: missing or invalid fields"
        );
      }

      const prompt = `As an empathetic AI, analyze these emotions deeply and compassionately.

        ${emotionsText}
        
        Focus on the following categories of insights:
        
        The first category is a trend-based feedback insight:
        - Provide an observational statement about explicit temporal patterns in the data, such as daily or weekly trends.
        - Consider both emotion types and energy levels when identifying patterns.
        - Do not ask questions in this insight. Focus on giving the user a clear, empathetic summary of their trends.
        - Use specific language to make insights relatable (e.g., "over the past week," "in the evenings").
        - Highlight patterns in emotion frequency, timing, and energy levels in a clear and supportive tone.
        - Reference specific notes when they provide context for patterns.
        
        The second category is a self-reflection insight:
        - Pose specific, open-ended questions to encourage self-awareness and personal exploration.
        - Consider energy levels and notes when framing questions about emotional experiences.
        - Use specific language to make the reflection relatable (e.g., "over the past week," "in the evenings").
        - Frame questions to help users connect with their experiences (e.g., "What was happening when you felt this way?" or "What helped you feel calmer during similar times?").
        - Maintain a gentle, non-judgmental tone.
        
        The third category is a general tips insight:
        - Provide universal, actionable advice tailored to the emotions and energy levels recorded for the week.
        - Align tips with both emotions and energy levels (e.g., for high energy anxiety: "Try a vigorous exercise," for low energy sadness: "Consider a gentle walk").
        - Frame suggestions gently, using language like "consider," "you might try," or "it could be helpful to..."
        - Avoid assumptions about specific triggers, focusing on practical and empathetic guidance.
        - Consider the user's energy levels when suggesting activities.
        
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
        - Keep insights specific, empathetic, and actionable, referencing the actual emotions, energy levels, and notes provided.
        - Keep each insight concise but meaningful, focusing on clarity and impact.
        - Maintain a warm, supportive, and non-judgmental tone.
        - Do not ask questions in the first or third insights. Only the second insight should contain open-ended questions.
        - Do not number the insights.
        - Do not lead the insights with any symbols.
        
        Your goal is to provide a supportive, thoughtful experience that helps users reflect on their emotions and discover helpful patterns and strategies.
        
        Format:
        Example: Your anxiety levels have been higher in the evenings, particularly when your energy is low. Consider a gentle breathing exercise or journaling before bed to help wind down.`;

      console.log("Debug: 📤 Sending request to OpenAI");

      const openAIResponse = await axios.post(
        "https://api.openai.com/v1/chat/completions",
        {
          model: "gpt-4o",
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

      // Split the output into insights
      let rawInsights = rawOutput.split("\n\n");
      
      // Validate the number of insights
      if (rawInsights.length < 3) {
        console.warn("Debug: ⚠️ GPT returned fewer than 3 insights, using fallbacks");
        rawInsights = generateFallbackInsights(emotions);
      }

      // Process and validate each insight
      let processedInsights = rawInsights
        .map((description, index) => {
          console.log("Debug: Processing insight:", description);
          
          // Validate insight content
          if (!description || description.trim().length === 0) {
            console.warn(`Debug: ⚠️ Empty insight at index ${index}, using fallback`);
            return generateFallbackInsight(index, emotions);
          }

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

      // If we still don't have 3 valid insights, use fallbacks
      if (processedInsights.length < 3) {
        console.warn("Debug: ⚠️ Not enough valid insights after processing, using fallbacks");
        processedInsights = generateFallbackInsights(emotions);
      }

      // Store the new insights in the database
      await userRef.set(processedInsights);

      console.log("Debug: ✅ Final insights:", JSON.stringify(processedInsights));
      return { success: true, insights: processedInsights, cooldownRemaining: 0 };
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

// Helper function to generate fallback insights
function generateFallbackInsights(emotions) {
  const fallbacks = [];
  
  // Generate fallback for pattern insight
  const patternFallback = generatePatternFallback(emotions);
  fallbacks.push({
    emojiName: "emotional-pattern",
    title: "weekly emotional patterns",
    description: patternFallback,
    timestamp: Date.now()
  });
  
  // Generate fallback for reflection insight
  const reflectionFallback = generateReflectionFallback(emotions);
  fallbacks.push({
    emojiName: "self-reflection",
    title: "self-reflection",
    description: reflectionFallback,
    timestamp: Date.now()
  });
  
  // Generate fallback for tips insight
  const tipsFallback = generateTipsFallback(emotions);
  fallbacks.push({
    emojiName: "encouraging-tip",
    title: "encouraging tips",
    description: tipsFallback,
    timestamp: Date.now()
  });
  
  return fallbacks;
}

// Helper function to generate a fallback pattern insight
function generatePatternFallback(emotions) {
  const emotionCounts = {};
  const energyLevels = [];
  
  emotions.forEach(e => {
    emotionCounts[e.emotion] = (emotionCounts[e.emotion] || 0) + 1;
    if (e.energy_level) energyLevels.push(e.energy_level);
  });
  
  const mostFrequent = Object.entries(emotionCounts)
    .sort((a, b) => b[1] - a[1])[0];
  
  const avgEnergy = energyLevels.length > 0 
    ? energyLevels.reduce((a, b) => a + b, 0) / energyLevels.length 
    : null;
  
  let insight = `our ai engine is temporarily unavailable, but i can still share what i notice: you've been feeling ${mostFrequent[0]} most often this week.`;
  
  if (avgEnergy !== null) {
    insight += ` your energy levels have been around ${Math.round(avgEnergy)} out of 5.`;
  }
  
  return insight;
}

// Helper function to generate a fallback reflection insight
function generateReflectionFallback(emotions) {
  const uniqueEmotions = [...new Set(emotions.map(e => e.emotion))];
  const emotionList = uniqueEmotions.join(", ");
  
  return `what was happening when you felt ${emotionList}? how did these emotions affect your day?`;
}

// Helper function to generate a fallback tips insight
function generateTipsFallback(emotions) {
  const hasHighEnergy = emotions.some(e => e.energy_level && e.energy_level >= 4);
  const hasLowEnergy = emotions.some(e => e.energy_level && e.energy_level <= 2);
  
  let tip = "here's a gentle suggestion: consider taking a moment to breathe and reflect on your emotions.";
  
  if (hasHighEnergy) {
    tip += " when you feel high energy, try channeling it into something creative or physical.";
  }
  
  if (hasLowEnergy) {
    tip += " when you feel low energy, gentle movement or a short walk might help.";
  }
  
  return tip;
}

// Helper function to generate a single fallback insight
function generateFallbackInsight(index, emotions) {
  switch (index) {
    case 0:
      return generatePatternFallback(emotions);
    case 1:
      return generateReflectionFallback(emotions);
    case 2:
      return generateTipsFallback(emotions);
    default:
      return "i encourage you to take a moment to reflect on your emotions this week.";
  }
}
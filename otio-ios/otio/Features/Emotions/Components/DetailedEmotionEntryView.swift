import SwiftUI
import FirebaseAuth

struct DetailedEmotionEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var emotionService: EmotionService
    @StateObject private var cooldownService = EmotionCooldownService()
    
    let emotionType: String
    
    @State private var text: String = ""
    @State private var energyLevel: Int? = nil
    @State private var showCooldownAlert = false
    @State private var errorMessage: String = ""
    @State private var showError = false
    
    private let maxCharacters = 100
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Emotion type display
                    Text("emotion: \(emotionType)")
                        .font(.custom("IBMPlexMono-Light", size: 17))
                        .fontWeight(.medium)
                        .padding(.top)
                    
                    // Energy level selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("energy level (optional)")
                            .font(.custom("IBMPlexMono-Light", size: 15))
                        
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { level in
                                Button {
                                    if energyLevel == level {
                                        energyLevel = nil
                                    } else {
                                        energyLevel = level
                                    }
                                } label: {
                                    ZStack {
                                        Rectangle()
                                            .fill(Color.clear)
                                            .overlay(
                                                Rectangle()
                                                    .strokeBorder(energyLevel == level ? Color.secondary : Color.primary, lineWidth: 1)
                                            )
                                        
                                        Text("\(level)")
                                            .font(.custom("IBMPlexMono-Light", size: 15))
                                            .foregroundColor(energyLevel == level ? Color.secondary : Color.primary)
                                    }
                                }
                                .aspectRatio(1, contentMode: .fit)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        
                        Text("low → high")
                            .font(.custom("IBMPlexMono-Light", size: 13))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    // Text input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("notes (optional)")
                            .font(.custom("IBMPlexMono-Light", size: 15))
                        
                        ZStack(alignment: .topLeading) {
                            // First, create a transparent background
                            Color.clear
                                .frame(height: 120)
                            
                            // Then add the TextEditor with modifications to make it transparent
                            TextEditor(text: $text)
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .padding(8)
                                .scrollContentBackground(.hidden) // This hides the default background on iOS 16+
                                .background(Color.clear) // Set background to clear
                                .overlay(
                                    Rectangle()
                                        .strokeBorder(Color.primary, lineWidth: 1)
                                )
                                .frame(height: 120)
                                .onChange(of: text) { newValue in
                                    if newValue.count > maxCharacters {
                                        text = String(newValue.prefix(maxCharacters))
                                    }
                                }
                            
                            if text.isEmpty {
                                Text("what's that feeling tied to?")
                                    .font(.custom("IBMPlexMono-Light", size: 15))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                            }
                        }
                        
                        Text("\(maxCharacters - text.count)")
                            .font(.custom("IBMPlexMono-Light", size: 13))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack {
                        Spacer() // Center the button
                        Button(action: handleSubmit) {
                            Text("save")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .overlay(
                                    Rectangle()
                                        .strokeBorder(Color.primary, lineWidth: 1)
                                )
                        }
                        Spacer() // Center the button
                    }
                }
                .padding()
                
                // Cooldown alert overlay
                if showCooldownAlert {
                    // Semi-transparent background
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    // Alert content
                    VStack(spacing: 24) {
                        Text("take a moment")
                            .font(.custom("IBMPlexMono-Light", size: 17))
                            .fontWeight(.semibold)
                        
                        Text("pause and sit with your emotions. a short cooldown follows to support mindful logging.")
                            .font(.custom("IBMPlexMono-Light", size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("next log available in: \(cooldownService.formattedRemainingTime())")
                            .font(.custom("IBMPlexMono-Light", size: 15))
                            .foregroundColor(.primary)
                        
                        Button {
                            showCooldownAlert = false
                        } label: {
                            Text("ok")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .overlay(
                                    Rectangle()
                                        .strokeBorder(Color.primary, lineWidth: 1)
                                )
                        }
                    }
                    .padding(24)
                    .background(Color.appBackground)
                    .padding(.horizontal, 40)
                }
                
                if showError {
                    // Semi-transparent background
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    // Alert content
                    VStack(spacing: 24) {
                        Text("oops")
                            .font(.custom("IBMPlexMono-Light", size: 17))
                            .fontWeight(.semibold)
                        
                        Text(errorMessage)
                            .font(.custom("IBMPlexMono-Light", size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            showError = false
                        } label: {
                            Text("ok")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .overlay(
                                    Rectangle()
                                        .strokeBorder(Color.primary, lineWidth: 1)
                                )
                        }
                    }
                    .padding(24)
                    .background(Color.appBackground)
                    .padding(.horizontal, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("log")
                        .font(.custom("IBMPlexMono-Light", size: 22))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17))  // Adjust size to match iOS standard
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
    
    // Modify the save button action
    private func handleSubmit() {
        // Check if we can log an emotion
        if cooldownService.canLogEmotion() {
            // Try to log the emotion
            if cooldownService.tryLogEmotion() {
                // Proceed with saving
                let capturedType = emotionType
                let capturedText = text.isEmpty ? nil : text
                let capturedEnergyLevel = energyLevel
                
                Task {
                    do {
                        try await emotionService.logEmotion(
                            type: capturedType,
                            text: capturedText,
                            energyLevel: capturedEnergyLevel
                        )
                        await MainActor.run {
                            NotificationCenter.default.post(name: NSNotification.Name("EmotionSaved"), object: nil)
                        }
                        dismiss()
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        } else {
            // Show cooldown alert
            showCooldownAlert = true
        }
    }
}
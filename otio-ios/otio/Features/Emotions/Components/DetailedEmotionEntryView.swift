import SwiftUI
import FirebaseAuth

struct DetailedEmotionEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var emotionService: EmotionService
    @StateObject private var cooldownService = EmotionCooldownService()
    
    let emotionName: String
    
    @State private var log: String = ""
    @State private var energyLevel: Int? = nil
    @State private var showCooldownAlert = false
    @State private var errorMessage: String = ""
    @State private var showError = false
    @State private var keyboardHeight: CGFloat = 0
    
    private let maxCharacters = 100
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                ZStack {
                    Color.appBackground
                        .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        // Emotion name display
                        Text("emotion: \(emotionName)")
                            .font(.custom("IBMPlexMono-Light", size: 17))
                            .fontWeight(.medium)
                            .padding(.top)
                        
                        // Energy level selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("energy level (optional)")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                            
                            GeometryReader { geometry in
                                let availableWidth = geometry.size.width
                                let spacing: CGFloat = 8
                                let buttonWidth = (availableWidth - (spacing * 4)) / 5
                                
                                HStack(spacing: spacing) {
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
                                                    .fill(energyLevel == level ? Color.primary : Color.clear)
                                                    .overlay(
                                                        Rectangle()
                                                            .strokeBorder(Color.primary, lineWidth: 1)
                                                    )
                                                
                                                Text("\(level)")
                                                    .font(.custom("IBMPlexMono-Light", size: 15))
                                                    .foregroundColor(energyLevel == level ? Color.appBackground : Color.primary)
                                            }
                                        }
                                        .frame(width: buttonWidth, height: buttonWidth)
                                    }
                                }
                            }
                            .frame(height: (UIScreen.main.bounds.width - 40 - 32) / 5) // Match width for square aspect ratio
                            
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
                                TextEditor(text: $log)
                                    .font(.custom("IBMPlexMono-Light", size: 15))
                                    .padding(8)
                                    .scrollContentBackground(.hidden) // This hides the default background on iOS 16+
                                    .background(Color.clear) // Set background to clear
                                    .overlay(
                                        Rectangle()
                                            .strokeBorder(Color.primary, lineWidth: 1)
                                    )
                                    .frame(height: 120)
                                    .onChange(of: log) { newValue in
                                        if newValue.count > maxCharacters {
                                            log = String(newValue.prefix(maxCharacters))
                                        }
                                    }
                                
                                if log.isEmpty {
                                    Text("what's that feeling tied to?")
                                        .font(.custom("IBMPlexMono-Light", size: 15))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 16)
                                }
                            }
                            
                            Text("\(maxCharacters - log.count)")
                                .font(.custom("IBMPlexMono-Light", size: 13))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        
                        Spacer()
                            .frame(height: 200) // Fixed space for save button
                    }
                    .padding()
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                            to: nil, 
                                            from: nil, 
                                            for: nil)
            }
            .background(Color.appBackground)
            .overlay(alignment: .bottom) {
                VStack {
                    Button(action: handleSubmit) {
                        Text("save")
                            .font(.custom("IBMPlexMono-Light", size: 15))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(keyboardHeight > 0 ? Color.appCardBackground : Color.appBackground)
                            .overlay(
                                Rectangle()
                                    .strokeBorder(Color.primary, lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 16)
                }
                .frame(maxWidth: .infinity)
                .background(
                    (keyboardHeight > 0 ? Color.appCardBackground : Color.appBackground)
                        .edgesIgnoringSafeArea(.bottom)
                )
                .padding(.bottom, keyboardHeight > 0 ? 0 : 16)
            }
            .overlay {
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
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                    let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
                    keyboardHeight = keyboardFrame.height
                }
                
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    keyboardHeight = 0
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
                let capturedEmotion = emotionName
                let capturedLog = log.isEmpty ? nil : log
                let capturedEnergyLevel = energyLevel
                
                Task {
                    do {
                        try await emotionService.logEmotion(
                            emotion: capturedEmotion,
                            log: capturedLog,
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
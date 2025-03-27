import SwiftUI

struct EmotionDetailView: View {
    let emotion: String
    let deeperEmotions: [String]
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var emotionService: EmotionService
    @State private var showCooldownAlert = false

    private func dynamicFontSize(for text: String) -> CGFloat {
        switch text.count {
        case 0...10:
            return 14    // Default size for most words
        default:
            return 12    // Smaller size for words with 11+ characters
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.appBackground
                        .ignoresSafeArea()
                    
                    VStack(spacing: geometry.size.height * 0.06) {  // Responsive spacing
                        Text("share your feelings")
                            .font(.custom("IBMPlexMono-Light", size: 15))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .padding(.top, geometry.size.height * 0.02)

                        let buttonSize = min(geometry.size.width * 0.25, 100)  // Responsive button size
                        let gridSpacing = geometry.size.width * 0.1  // Responsive grid spacing
                        
                        let columns = [
                            GridItem(.fixed(buttonSize), spacing: gridSpacing),
                            GridItem(.fixed(buttonSize), spacing: gridSpacing)
                        ]
                        
                        if deeperEmotions.count == 1 {
                            // Single emotion - centered
                            HStack {
                                Spacer()
                                emotionButton(
                                    emotion: deeperEmotions[0],
                                    size: buttonSize
                                )
                                .padding(.vertical, 8)
                                Spacer()
                            }
                        } else {
                            // Multiple emotions - grid
                            LazyVGrid(columns: columns, spacing: geometry.size.height * 0.025) {
                                ForEach(deeperEmotions, id: \.self) { deeperEmotion in
                                    emotionButton(
                                        emotion: deeperEmotion,
                                        size: buttonSize
                                    )
                                    .padding(.vertical, 8)
                                }
                            }
                            .padding(.horizontal, geometry.size.width * 0.05)
                            .frame(maxWidth: .infinity)
                        }

                        Spacer()
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("experience")
                            .font(.custom("IBMPlexMono-Light", size: 22))
                            .fontWeight(.semibold)
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.primary)
                        }
                    }
                }
                .gesture(
                    DragGesture()
                        .onEnded { gesture in
                            if gesture.translation.width > 100 {
                                dismiss()
                            }
                        }
                )
                .overlay(cooldownAlertOverlay)
            }
        }
    }
    
    // Cooldown alert overlay with Group wrapper
    private var cooldownAlertOverlay: some View {
        Group {
            if showCooldownAlert {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(cooldownAlertContent)
                    .transition(.opacity)
            }
        }
    }

    // Cooldown alert content styled like insight view
    private var cooldownAlertContent: some View {
        VStack(spacing: 24) {
            Text("take a moment")
                .font(.custom("IBMPlexMono-Light", size: 17))
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                Text("take a moment to pause and sit with your emotions. a short cooldown follows to support mindful logging.")
                    .font(.custom("IBMPlexMono-Light", size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 8) {
                    Text("next log available in:")
                        .font(.custom("IBMPlexMono-Light", size: 15))
                        .foregroundColor(.primary)
                    
                    Text(emotionService.formattedRemainingTime())
                        .font(.custom("IBMPlexMono-Light", size: 15))
                        .foregroundColor(.primary)
                }
            }
            
            HStack(spacing: 16) {
                okButton
            }
        }
        .padding(24)
        .background(Color.appBackground)
        .padding(.horizontal, 40)
    }
    
    // OK button component
    private var okButton: some View {
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

    // Helper function to create emotion buttons
    private func emotionButton(emotion: String, size: CGFloat) -> some View {
        Button {
            let impactGenerator = UIImpactFeedbackGenerator(style: .soft)
            impactGenerator.impactOccurred()
            
            // Check if we can log an emotion
            if emotionService.canLogEmotion() {
                // Try to log the emotion
                if emotionService.tryLogEmotion() {
                    // Proceed with normal emotion logging
                    onSelect(emotion)
                    dismiss()
                }
            } else {
                // Show cooldown alert
                showCooldownAlert = true
            }
        } label: {
            Rectangle()
                .fill(Color.clear)
                .frame(width: size, height: size)
                .overlay(
                    Rectangle()
                        .strokeBorder(Color.primary, lineWidth: 1)
                )
                .overlay(
                    VStack(spacing: 4) {
                        Text(emotion)
                            .font(.custom("IBMPlexMono-Light", size: dynamicFontSize(for: emotion)))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                )
        }
    }
}
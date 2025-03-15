import SwiftUI

struct EmotionDetailView: View {
    let emotion: String
    let deeperEmotions: [String]
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

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
            }
        }
    }

    // Helper function to create emotion buttons
    private func emotionButton(emotion: String, size: CGFloat) -> some View {
        Button {
            let impactGenerator = UIImpactFeedbackGenerator(style: .soft)
            impactGenerator.impactOccurred()
            
            onSelect(emotion)
            dismiss()
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
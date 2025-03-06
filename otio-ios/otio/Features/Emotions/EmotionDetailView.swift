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
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 48) {
                    Text("share your feelings")
                        .font(.custom("IBMPlexMono-Light", size: 15))
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .padding(.top, 10)

                    let columns = [
                        GridItem(.fixed(100), spacing: 40),
                        GridItem(.fixed(100), spacing: 40)
                    ]
                    
                    if deeperEmotions.count == 1 {
                        // Single emotion - centered
                        HStack {
                            Spacer()
                            Button {
                                onSelect(deeperEmotions[0])
                                dismiss()
                            } label: {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Rectangle()
                                            .strokeBorder(Color.primary, lineWidth: 1)
                                    )
                                    .overlay(
                                        VStack(spacing: 4) {
                                            Text(deeperEmotions[0])
                                                .font(.custom("IBMPlexMono-Light", size: dynamicFontSize(for: deeperEmotions[0])))
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                        }
                                    )
                            }
                            .padding(.vertical, 8)
                            Spacer()
                        }
                    } else {
                        // Multiple emotions - grid
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(deeperEmotions, id: \.self) { deeperEmotion in
                                Button {
                                    // Add gentle haptic feedback
                                    let impactGenerator = UIImpactFeedbackGenerator(style: .soft)
                                    impactGenerator.impactOccurred()
                                    
                                    onSelect(deeperEmotion)
                                    dismiss()
                                } label: {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Rectangle()
                                                .strokeBorder(Color.primary, lineWidth: 1)
                                        )
                                        .overlay(
                                            VStack(spacing: 4) {
                                                Text(deeperEmotion)
                                                    .font(.custom("IBMPlexMono-Light", size: dynamicFontSize(for: deeperEmotion)))
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.primary)
                                            }
                                        )
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                    }

                    Spacer()
                }
            }

            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
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
                            .foregroundColor(.appAccent)
                    }
                }
            }
        }
    }
}
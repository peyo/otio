import SwiftUI

struct EmotionDetailView: View {
    let emotion: String
    let deeperEmotions: [String]
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var emotionService: EmotionService
    @State private var showDetailedEntry = false
    @State private var selectedDeeperEmotion: String?
    @State private var energyLevel: Int?
    @Binding var showEmotionDetail: Bool

    private func dynamicFontSize(for text: String) -> CGFloat {
        switch text.count {
        case 0...10:
            return 14    // Default size for most words
        default:
            return 12    // Smaller size for words with 11+ characters
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        Text("share your feelings")
                            .font(.custom("IBMPlexMono-Light", size: 17))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .padding(.top, -32)  // Adjusted padding

                        let buttonSize = min(geometry.size.width * 0.25, 100)
                        let gridSpacing = geometry.size.width * 0.1
                        
                        let columns = [
                            GridItem(.fixed(buttonSize), spacing: gridSpacing),
                            GridItem(.fixed(buttonSize), spacing: gridSpacing)
                        ]
                        
                        if deeperEmotions.count == 1 {
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
                    .padding(.vertical, geometry.size.height * 0.05)
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("experience")
                    .font(.custom("IBMPlexMono-Light", size: 22))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
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
        .sheet(isPresented: $showDetailedEntry) {
            if let selectedDeeperEmotion = selectedDeeperEmotion {
                DetailedEmotionEntryView(emotionType: selectedDeeperEmotion)
            }
        }
    }
    
    private func emotionButton(emotion: String, size: CGFloat) -> some View {
        Button {
            let impactGenerator = UIImpactFeedbackGenerator(style: .soft)
            impactGenerator.impactOccurred()
            
            selectedDeeperEmotion = emotion
            showDetailedEntry = true
            
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
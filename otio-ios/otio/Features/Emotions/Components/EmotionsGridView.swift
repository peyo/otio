import SwiftUI

struct EmotionsGridView: View {
    let emotionOrder: [String]
    let selectedEmotion: String?
    let onEmotionTap: (String) -> Void
    
    var body: some View {
        VStack {
            Color.appBackground
                .ignoresSafeArea(edges: .bottom)
            
            VStack(spacing: 16) {
                let columns = [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ]
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(emotionOrder, id: \.self) { emotion in
                        EmotionButton(
                            type: emotion,
                            isSelected: selectedEmotion == emotion,
                            onTap: { onEmotionTap(emotion) }
                        )
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.top, 0)
        }
    }
}
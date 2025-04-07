import SwiftUI

struct EmotionCard: View {
    let emotion: EmotionData
    let timeString: (Date) -> String
    let onDelete: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var showEditSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top row with emotion name and edit button
            HStack(alignment: .center, spacing: 24) {
                Text(emotion.type)
                    .font(.custom("IBMPlexMono-Light", size: 15))
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    showEditSheet = true
                } label: {
                    Text("edit")
                        .font(.custom("IBMPlexMono-Light", size: 15))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(
                            Rectangle()
                                .strokeBorder(Color.primary, lineWidth: 1)
                        )
                }
            }
            
            // Energy level if available
            if let energyLevel = emotion.energyLevel {
                HStack(spacing: 8) {
                    Text("energy: \(energyLevel)")
                        .font(.custom("IBMPlexMono-Light", size: 15))
                    
                    // Visual indicator
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { level in
                            Circle()
                                .fill(level <= energyLevel ? Color.primary : Color.secondary.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
            
            // Text preview if available
            if let text = emotion.text, !text.isEmpty {
                Text(text)
                    .font(.custom("IBMPlexMono-Light", size: 15))
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            
            // Timestamp at bottom
            Text(timeString(emotion.date))
                .font(.custom("IBMPlexMono-Light", size: 13))
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Rectangle()
                .fill(Color.appCardBackground)
        )
        .sheet(isPresented: $showEditSheet) {
            EditEmotionView(
                emotion: emotion,
                onUpdate: { /* Will be handled by EmotionService */ },
                onDelete: onDelete
            )
        }
    }
}
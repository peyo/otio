import SwiftUI

struct EmotionCard: View {
    let emotion: EmotionData
    let timeString: (Date) -> String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(emotion.type)
                            .font(.custom("IBMPlexMono-Light", size: 15))
                            .fontWeight(.semibold)
                    }

                    Text(timeString(emotion.date))
                        .font(.custom("IBMPlexMono-Light", size: 15))
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Rectangle()
                .fill(Color.appCardBackground)
        )
    }
}
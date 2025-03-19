import SwiftUI

// Removed the Color extension for emotion colors since they're no longer used

extension EmotionData {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
import SwiftUI

struct SoundCard: View {
    let sound: SoundType
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(sound.rawValue)
                .font(.custom("IBMPlexMono-Light", size: 15))
                .fontWeight(.medium)
                .foregroundColor(isSelected || isPressed ? Color.secondary : Color.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .frame(height: 50)
        .background(Color.clear)
        .overlay(
            Rectangle()
                .strokeBorder(isSelected || isPressed ? Color.secondary : Color.primary, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    // User is pressing down
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    // User released
                    isPressed = false
                    onTap()  // Changed from 'action()' to 'onTap()'
                }
        )
    }
}

Button {
    Task {
        if let userId = Auth.auth().currentUser?.uid {
            do {
                try await updateEmotion(userId: userId)
                onUpdate()
                dismiss()
            } catch {
                print("Error updating emotion: \(error.localizedDescription)")
            }
        }
    }
} label: {
    Text("update")
        .font(.custom("IBMPlexMono-Light", size: 15))
        .foregroundColor(.primary)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .overlay(
            Rectangle()
                .strokeBorder(Color.primary, lineWidth: 1)
        )
} 
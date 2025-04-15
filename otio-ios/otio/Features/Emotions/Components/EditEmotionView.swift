import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct EditEmotionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var emotionService: EmotionService
    
    let emotion: EmotionData
    let onUpdate: () -> Void
    let onDelete: () -> Void
    
    @State private var text: String
    @State private var energyLevel: Int?
    @State private var showDeleteConfirmation = false
    @State private var keyboardHeight: CGFloat = 0
    
    private let maxCharacters = 100
    
    init(emotion: EmotionData, onUpdate: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.emotion = emotion
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _text = State(initialValue: emotion.text ?? "")
        _energyLevel = State(initialValue: emotion.energyLevel)
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                ZStack {
                    Color.appBackground
                        .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        Text("emotion: \(emotion.type)")
                            .font(.custom("IBMPlexMono-Light", size: 17))
                            .fontWeight(.medium)
                            .padding(.top)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("energy level (optional)")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                            
                            GeometryReader { geometry in
                                let availableWidth = geometry.size.width
                                let spacing: CGFloat = 8
                                let buttonWidth = (availableWidth - (spacing * 4)) / 5
                                
                                HStack(spacing: spacing) {
                                    ForEach(1...5, id: \.self) { level in
                                        Button {
                                            if energyLevel == level {
                                                energyLevel = nil
                                            } else {
                                                energyLevel = level
                                            }
                                        } label: {
                                            ZStack {
                                                Rectangle()
                                                    .fill(Color.clear)
                                                    .overlay(
                                                        Rectangle()
                                                            .strokeBorder(energyLevel == level ? Color.secondary : Color.primary, lineWidth: 1)
                                                    )
                                                
                                                Text("\(level)")
                                                    .font(.custom("IBMPlexMono-Light", size: 15))
                                                    .foregroundColor(energyLevel == level ? Color.secondary : Color.primary)
                                            }
                                        }
                                        .frame(width: buttonWidth, height: buttonWidth)
                                    }
                                }
                            }
                            .frame(height: (UIScreen.main.bounds.width - 40 - 32) / 5)
                            
                            Text("low → high")
                                .font(.custom("IBMPlexMono-Light", size: 13))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("notes (optional)")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                            
                            ZStack(alignment: .topLeading) {
                                Color.clear
                                    .frame(height: 120)
                                
                                TextEditor(text: $text)
                                    .font(.custom("IBMPlexMono-Light", size: 15))
                                    .padding(8)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .overlay(
                                        Rectangle()
                                            .strokeBorder(Color.primary, lineWidth: 1)
                                    )
                                    .frame(height: 120)
                                
                                if text.isEmpty {
                                    Text("what's that feeling tied to?")
                                        .font(.custom("IBMPlexMono-Light", size: 15))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 16)
                                }
                            }
                        }
                        
                        Spacer()
                            .frame(height: 200)
                    }
                    .padding()
                }
            }
            .background(Color.appBackground)
            .overlay(alignment: .bottom) {
                VStack(spacing: 16) {
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
                            .background(Color.appBackground)
                            .overlay(
                                Rectangle()
                                    .strokeBorder(Color.primary, lineWidth: 1)
                            )
                    }
                    
                    Button {
                        Task {
                            if let userId = Auth.auth().currentUser?.uid {
                                do {
                                    try await deleteEmotion(userId: userId)
                                    onDelete()
                                    dismiss()
                                } catch {
                                    print("Error deleting emotion: \(error.localizedDescription)")
                                }
                            }
                        }
                    } label: {
                        Text("delete")
                            .font(.custom("IBMPlexMono-Light", size: 15))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.appBackground)
                            .overlay(
                                Rectangle()
                                    .strokeBorder(Color.primary, lineWidth: 1)
                            )
                    }
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    (keyboardHeight > 0 ? Color.appCardBackground : Color.appBackground)
                        .edgesIgnoringSafeArea(.bottom)
                )
                .padding(.bottom, keyboardHeight > 0 ? 0 : 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("edit")
                        .font(.custom("IBMPlexMono-Light", size: 22))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                    let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
                    keyboardHeight = keyboardFrame.height
                }
                
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    keyboardHeight = 0
                }
            }
        }
    }
    
    private func updateEmotion(userId: String) async throws {
        try await emotionService.updateEmotion(
            id: emotion.id,
            type: emotion.type,
            text: text.isEmpty ? nil : text,
            energyLevel: energyLevel
        )
        
        await MainActor.run {
            NotificationCenter.default.post(name: NSNotification.Name("RefreshEmotions"), object: nil)
        }
    }
    
    private func deleteEmotion(userId: String) async throws {
        try await emotionService.deleteEmotion(id: emotion.id)
        
        await MainActor.run {
            NotificationCenter.default.post(name: NSNotification.Name("RefreshEmotions"), object: nil)
        }
    }
}

struct EditEmotionViewWrapper: View {
    let emotion: EmotionData
    let onUpdate: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        EditEmotionView(
            emotion: emotion,
            onUpdate: onUpdate,
            onDelete: onDelete
        )
        .environmentObject(EmotionService.shared)
    }
}
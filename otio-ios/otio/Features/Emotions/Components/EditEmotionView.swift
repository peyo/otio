import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct EditEmotionView: View {
    @Environment(\.dismiss) private var dismiss
    
    let emotion: EmotionData
    let onUpdate: () -> Void
    let onDelete: () -> Void
    
    @State private var text: String
    @State private var energyLevel: Int?
    @State private var showDeleteConfirmation = false
    
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
                        
                        HStack(spacing: 8) {
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
                                .aspectRatio(1, contentMode: .fit)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        
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
                                .onChange(of: text) { newValue in
                                    if newValue.count > maxCharacters {
                                        text = String(newValue.prefix(maxCharacters))
                                    }
                                }
                            
                            if text.isEmpty {
                                Text("what's that feeling tied to?")
                                    .font(.custom("IBMPlexMono-Light", size: 15))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                            }
                        }
                        
                        Text("\(maxCharacters - text.count)")
                            .font(.custom("IBMPlexMono-Light", size: 13))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Button {
                            Task {
                                if let userId = Auth.auth().currentUser?.uid {
                                    do {
                                        try await updateEmotion(userId: userId)
                                        DispatchQueue.main.async {
                                            NotificationCenter.default.post(name: NSNotification.Name("RefreshEmotions"), object: nil)
                                        }
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
                        
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Text("delete")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .overlay(
                                    Rectangle()
                                        .strokeBorder(Color.primary, lineWidth: 1)
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                
                // Add the overlay for delete confirmation
                if showDeleteConfirmation {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(deleteConfirmationContent)
                        .transition(.opacity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
        }
    }
    
    private func updateEmotion(userId: String) async throws {
        let ref = Database.database().reference()
            .child("users")
            .child(userId)
            .child("emotions")
            .child(emotion.id)
        
        var updates: [String: Any] = [:]
        
        // Only update the fields that can be edited
        if !text.isEmpty {
            updates["text"] = text
        } else {
            updates["text"] = NSNull()  // Remove the field if empty
        }
        
        updates["energy_level"] = energyLevel
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.updateChildValues(updates) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    private var deleteConfirmationContent: some View {
        VStack(spacing: 24) {
            Text("delete emotion")
                .font(.custom("IBMPlexMono-Light", size: 17))
                .fontWeight(.semibold)
            
            Text("let go of this emotion?")
                .font(.custom("IBMPlexMono-Light", size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                // Cancel button
                Button {
                    showDeleteConfirmation = false
                } label: {
                    Text("cancel")
                        .font(.custom("IBMPlexMono-Light", size: 15))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            Rectangle()
                                .strokeBorder(Color.primary, lineWidth: 1)
                        )
                }
                
                // Delete button
                Button {
                    onDelete()
                    dismiss()
                } label: {
                    Text("delete")
                        .font(.custom("IBMPlexMono-Light", size: 15))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            Rectangle()
                                .strokeBorder(Color.primary, lineWidth: 1)
                        )
                }
            }
        }
        .padding(24)
        .background(Color.appBackground)
        .padding(.horizontal, 40)
    }
}
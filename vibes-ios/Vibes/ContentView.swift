//
//  ContentView.swift
//  Feelings
//
//  Created by Peter Yoon on 1/1/25.
//

import SwiftUI

struct EmotionOption: Identifiable {
    let id = UUID()
    let type: String
    let icon: String
}

struct ContentView: View {
    private let emotions = ["Happy", "Sad", "Anxious", "Angry", "Neutral"]
    private let buttonSpacing: CGFloat = 12  // Reduced for better visual balance
    
    @State private var selectedEmotion: EmotionOption?
    @State private var showingIntensitySheet = false
    @State private var recentEmotions: [EmotionData] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {  // Main container with generous spacing
                    // Emotion Input Section
                    VStack(spacing: 16) {
                        // First row: 3 buttons
                        HStack(spacing: buttonSpacing) {
                            Spacer()
                            ForEach(0..<3) { index in
                                EmotionButton(
                                    type: emotions[index],
                                    isSelected: selectedEmotion?.type == emotions[index],
                                    onTap: {
                                        handleEmotionTap(emotions[index])
                                    }
                                )
                            }
                            Spacer()
                        }
                        
                        // Second row: 2 buttons
                        HStack(spacing: buttonSpacing) {
                            Spacer()
                            ForEach(3..<5) { index in
                                EmotionButton(
                                    type: emotions[index],
                                    isSelected: selectedEmotion?.type == emotions[index],
                                    onTap: {
                                        handleEmotionTap(emotions[index])
                                    }
                                )
                            }
                            Spacer()
                        }
                    }
                    .padding(.top, 16)
                    
                    // Recent Emotions Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if recentEmotions.isEmpty {
                            Text("No recent emotions")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(recentEmotions) { emotion in
                                    EmotionCard(
                                        emotion: emotion,
                                        timeString: relativeTimeString(from:)
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Vibes")
            .toolbar {
                NavigationLink {
                    EmotionsAnalyticsView()
                } label: {
                    Label("Analytics", systemImage: "chart.xyaxis.line")
                }
            }
            .sheet(isPresented: $showingIntensitySheet) {
                IntensitySelectionView(emotion: selectedEmotion!) { intensity in
                    submitEmotion(type: selectedEmotion!.type, intensity: intensity)
                }
            }
            .task {
                await fetchEmotions()
            }
        }
    }
    
    private func handleEmotionTap(_ type: String) {
        if type == "Neutral" {
            submitEmotion(type: "Neutral", intensity: 0)
        } else {
            selectedEmotion = EmotionOption(
                type: type,
                icon: type  // We'll use the type directly since we're using emojis
            )
            showingIntensitySheet = true
        }
    }
    
    private func relativeTimeString(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "yesterday" : "\(day) days ago"
        }
        
        if let hour = components.hour, hour > 0 {
            return hour == 1 ? "an hour ago" : "\(hour) hours ago"
        }
        
        if let minute = components.minute, minute > 0 {
            return minute == 1 ? "a minute ago" : "\(minute) minutes ago"
        }
        
        return "just now"
    }

    private func submitEmotion(type: String, intensity: Int) {
        Task {
            guard let url = URL(string: "http://localhost:3000/api/emotions") else { return }
            
            let emotion = ["type": type, "intensity": intensity]
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: emotion)
                request.httpBody = jsonData
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 201 {
                    selectedEmotion = nil
                    await fetchEmotions()
                }
            } catch {
                print("Error submitting emotion:", error)
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func fetchEmotions() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: "http://localhost:3000/api/emotions") else {
            print("Error: Invalid URL")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            print("Raw data:", String(data: data, encoding: .utf8) ?? "Could not convert data to string")
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let emotionsResponse = try decoder.decode(EmotionsResponse.self, from: data)
            print("Decoded response:", emotionsResponse)
            
            recentEmotions = emotionsResponse.data
                .sorted { $0.date > $1.date }
                .prefix(3)
                .map { $0 }
            
            print("Recent emotions:", recentEmotions)
            
        } catch {
            print("Error fetching emotions:", error)
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// New component for emotion cards
struct EmotionCard: View {
    let emotion: EmotionData
    let timeString: (Date) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row: Emoji and time
            HStack {
                Text(emojiFor(emotion.type))
                    .font(.title)
                Spacer()
                Text(timeString(emotion.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Bottom row: Type and intensity
            HStack {
                Text(emotion.type)
                    .fontWeight(.medium)
                
                if emotion.type != "Neutral" {
                    Spacer()
                    Text("Intensity \(emotion.intensity)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6))
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    private func emojiFor(_ type: String) -> String {
        switch type {
        case "Happy": return "😊"
        case "Sad": return "😢"
        case "Anxious": return "😰"
        case "Angry": return "😠"
        case "Neutral": return "😐"
        default: return "❓"
        }
    }
}

struct EmotionButton: View {
    let type: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                Text(emojiFor(type))
                    .font(.system(size: 40))
                Text(type)
                    .font(.caption)
            }
            .frame(width: 100, height: 100)
            .background(Color.forEmotion(type).opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.forEmotion(type) : .clear, lineWidth: 2)
            )
        }
        .foregroundColor(.primary)
    }
    
    private func emojiFor(_ emotion: String) -> String {
        switch emotion {
        case "Happy": return "😊"
        case "Sad": return "😢"
        case "Anxious": return "😰"
        case "Angry": return "😠"
        case "Neutral": return "😐"
        default: return "❓"
        }
    }
}

struct IntensitySelectionView: View {
    let emotion: EmotionOption
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header with emoji and title
            HStack(spacing: 12) {
                Text(emotion.type == "Neutral" ? "😐" : emojiFor(emotion.type))
                    .font(.system(size: 44))
                Text("Select intensity")
                    .font(.title2)
                    .fontWeight(.medium)
            }
            .padding(.top)
            
            // Intensity buttons
            HStack(spacing: 24) {
                ForEach(1...3, id: \.self) { intensity in
                    IntensityButton(
                        intensity: intensity,
                        emotion: emotion.type,
                        action: {
                            withAnimation {
                                onSelect(intensity)
                                dismiss()
                            }
                        }
                    )
                }
            }
            .padding(.vertical, 32)
            
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    private func emojiFor(_ type: String) -> String {
        switch type {
        case "Happy": return "😊"
        case "Sad": return "😢"
        case "Anxious": return "😰"
        case "Angry": return "😠"
        default: return "❓"
        }
    }
}

// Simplified intensity button component
struct IntensityButton: View {
    let intensity: Int
    let emotion: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            VStack(spacing: 4) {
                Text("\(intensity)")
                    .font(.title2)
                    .fontWeight(.medium)
                Text(intensityLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, height: 80)
            .background(
                Circle()
                    .fill(Color.forEmotion(emotion).opacity(Double(intensity) / 5.0))
            )
        }
        .buttonStyle(IntensityButtonStyle())
    }
    
    private var intensityLabel: String {
        switch intensity {
        case 1: return "Light"
        case 2: return "Medium"
        case 3: return "Strong"
        default: return ""
        }
    }
}

// Custom button style for intensity buttons
struct IntensityButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}


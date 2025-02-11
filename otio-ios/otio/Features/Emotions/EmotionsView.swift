import SwiftUI
import FirebaseAuth
import Foundation

struct EmotionsView: View {
    @EnvironmentObject var userService: UserService
    private var emotionOrder: [String] { EmotionData.emotionOrder }
    private var emotions: [String: [String]] { EmotionData.emotions }

    @State private var selectedEmotion: String?
    @State private var weekEmotions: [EmotionData] = []
    @State private var recentEmotions: [EmotionData] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var normalizedScore: Double = 0.0
    @State private var showEmotionDetail = false

    var body: some View {
        Group {
            if userService.isAuthenticated {
                NavigationStack {
                    ZStack {
                        Color.appBackground
                            .ignoresSafeArea()
                        
                        ScrollView {
                            VStack(spacing: 0) {
                                emotionInputSection
                                    .padding(.top, 16)
                                
                                Spacer()
                                    .frame(minHeight: 32, maxHeight: 48)
                                
                                RecentEmotionsView(
                                    isLoading: isLoading,
                                    recentEmotions: recentEmotions,
                                    timeString: relativeTimeString
                                )
                                
                                Spacer(minLength: 16)
                            }
                            .padding(.top, -8)
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Text("otio")
                                .font(.custom("IBMPlexMono-Light", size: 22))
                                .fontWeight(.semibold)
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            EmotionsToolbarView(
                                weekEmotions: weekEmotions,
                                normalizedScore: normalizedScore
                            )
                        }
                    }
                    .navigationDestination(isPresented: $showEmotionDetail) {
                        EmotionDetailView(
                            emotion: selectedEmotion ?? "",
                            deeperEmotions: emotions[selectedEmotion ?? ""] ?? [],
                            onSelect: { deeperEmotion in
                                Task {
                                    guard let userId = userService.userId else { return }
                                    do {
                                        try await EmotionService.submitEmotion(type: deeperEmotion, userId: userId)
                                        await fetchEmotions()
                                    } catch {
                                        errorMessage = error.localizedDescription
                                        showError = true
                                    }
                                }
                            }
                        )
                    }
                }
                .task {
                    await fetchEmotions()
                    normalizedScore = EmotionCalculator.calculateAndNormalizeWeeklyScore(emotions: weekEmotions)
                    print("Normalized Weekly Score: \(normalizedScore)")
                }
            } else {
                SignInView()
            }
        }
    }
    
    private var emotionInputSection: some View {
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
                            onTap: {
                                handleEmotionTap(emotion)
                            }
                        )
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.top, 0)
        }
    }

    private func handleEmotionTap(_ type: String) {
        selectedEmotion = type
        showEmotionDetail = true
    }

    private func fetchEmotions() async {
        guard let userId = userService.userId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let (all, recent) = try await EmotionService.fetchEmotions(userId: userId)
            
            await MainActor.run {
                self.weekEmotions = all
                self.recentEmotions = recent
                self.normalizedScore = EmotionCalculator.calculateAndNormalizeWeeklyScore(emotions: all)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
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
}
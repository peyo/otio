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
    @State private var navigationId = UUID()

    var body: some View {
        NavigationStack {
            Group {
                if userService.isAuthenticated {
                    authenticatedContent
                } else {
                    SignInView()
                        .environmentObject(userService)
                        .onAppear(perform: clearState)
                }
            }
            .id(navigationId)
        }
    }
    
    private var authenticatedContent: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    EmotionsGridView(
                        emotionOrder: emotionOrder,
                        selectedEmotion: selectedEmotion,
                        onEmotionTap: handleEmotionTap
                    )
                    .padding(.top, 16)
                    
                    Spacer()
                        .frame(minHeight: 32, maxHeight: 48)
                    
                    RecentEmotionsView(
                        isLoading: isLoading,
                        recentEmotions: recentEmotions,
                        timeString: RelativeDateFormatter.relativeTimeString
                    )
                    
                    Spacer(minLength: 16)
                }
                .padding(.top, -8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showEmotionDetail) {
            emotionDetailDestination
        }
        .task {
            await fetchEmotions()
            normalizedScore = EmotionCalculator.calculateAndNormalizeWeeklyScore(emotions: weekEmotions)
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Text("otio")
                    .font(.custom("IBMPlexMono-Light", size: 22))
                    .fontWeight(.semibold)
            }
            
            ToolbarItem(placement: .principal) {
                EmptyView()
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                EmotionsToolbarView(
                    weekEmotions: weekEmotions,
                    normalizedScore: normalizedScore
                )
            }
        }
    }
    
    private var emotionDetailDestination: some View {
        EmotionDetailView(
            emotion: selectedEmotion ?? "",
            deeperEmotions: emotions[selectedEmotion ?? ""] ?? [],
            onSelect: handleDeeperEmotionSelect
        )
    }
    
    private func clearState() {
        weekEmotions = []
        recentEmotions = []
        navigationId = UUID()
    }
    
    private func handleEmotionTap(_ type: String) {
        selectedEmotion = type
        showEmotionDetail = true
    }
    
    private func handleDeeperEmotionSelect(_ deeperEmotion: String) {
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
    
    private func fetchEmotions() async {
        guard let userId = userService.userId else { 
            weekEmotions = []
            recentEmotions = []
            return 
        }
        
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
}
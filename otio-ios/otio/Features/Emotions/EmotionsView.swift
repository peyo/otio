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
    @State private var showDeleteConfirmation = false
    @State private var emotionToDelete: EmotionData?

    var body: some View {
        NavigationStack {
            Group {
                if userService.isAuthenticated {
                    GeometryReader { geometry in
                        authenticatedContent(geometry: geometry)
                    }
                } else {
                    SignInView()
                        .environmentObject(userService)
                        .onAppear(perform: clearState)
                }
            }
            .id(navigationId)
            .overlay {
                if showDeleteConfirmation {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: 24) {
                                Text("delete emotion")
                                    .font(.custom("IBMPlexMono-Light", size: 17))
                                    .fontWeight(.semibold)
                                
                                Text("let go of this emotion?")
                                    .font(.custom("IBMPlexMono-Light", size: 15))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                HStack(spacing: 16) {
                                    Button {
                                        emotionToDelete = nil
                                        showDeleteConfirmation = false
                                    } label: {
                                        Text("cancel")
                                            .font(.custom("IBMPlexMono-Light", size: 15))
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.appCardBackground)
                                    }
                                    
                                    Button {
                                        if let emotion = emotionToDelete,
                                           let userId = userService.userId {
                                            Task {
                                                do {
                                                    try await EmotionService.deleteEmotion(emotionId: emotion.id, userId: userId)
                                                    await fetchEmotions()
                                                } catch {
                                                    errorMessage = error.localizedDescription
                                                    showError = true
                                                }
                                            }
                                        }
                                        emotionToDelete = nil
                                        showDeleteConfirmation = false
                                    } label: {
                                        Text("delete")
                                            .font(.custom("IBMPlexMono-Light", size: 15))
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.appCardBackground)
                                    }
                                }
                            }
                            .padding(24)
                            .background(Color.appBackground)
                            .padding(.horizontal, 40)
                        }
                        .transition(.opacity)
                }
            }
        }
    }
    
    private func authenticatedContent(geometry: GeometryProxy) -> some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    EmotionsGridView(
                        emotionOrder: emotionOrder,
                        selectedEmotion: selectedEmotion,
                        onEmotionTap: handleEmotionTap,
                        geometry: geometry
                    )
                    .padding(.top, geometry.size.height * 0.04)
                    
                    Spacer()
                        .frame(
                            minHeight: geometry.size.height * 0.04,
                            maxHeight: geometry.size.height * 0.06
                        )
                    
                    RecentEmotionsView(
                        isLoading: isLoading,
                        recentEmotions: recentEmotions,
                        timeString: RelativeDateFormatter.relativeTimeString,
                        onDelete: { emotion in
                            emotionToDelete = emotion
                            showDeleteConfirmation = true
                        },
                        geometry: geometry
                    )
                }
                .padding(.top, -8)
                .padding(.bottom, geometry.size.height * 0.05)
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
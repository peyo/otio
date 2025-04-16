import SwiftUI
import FirebaseAuth
import Foundation

struct EmotionsView: View {
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var emotionService: EmotionService
    @State private var selectedTab = 0
    @State private var showingBreathingView = false
    @State private var showingListeningView = false
    @State private var showingInsightsView = false
    @State private var showingAccountView = false
    @State private var showingCalendarView = false
    
    private var emotionOrder: [String] { EmotionData.emotionOrder }
    private var emotions: [String: [String]] { EmotionData.emotions }

    @State private var selectedEmotion: String?
    @State private var weekEmotions: [EmotionData] = []
    @State private var recentEmotions: [EmotionData] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showEmotionDetail = false
    @State private var navigationId = UUID()
    @StateObject private var tutorialState = TutorialState()
    @State private var showTutorial = false
    @State private var showDownloadView = false

    var body: some View {
        mainNavigationStack
            .onAppear {
                setupNotifications()
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self)
            }
    }

    private func setupNotifications() {
        // Remove the old observers
        NotificationCenter.default.removeObserver(self)
        
        // Add observer for refreshing emotions
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RefreshEmotions"),
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await fetchEmotions()
            }
        }
        
        // Add observer for emotion saved
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("EmotionSaved"),
            object: nil,
            queue: .main
        ) { _ in
            // Reset navigation
            showEmotionDetail = false
        }
    }

    private var mainNavigationStack: some View {
        NavigationStack {
            mainContent
                .id(navigationId)
                .onAppear {
                    showTutorial = TutorialState.shouldShowTutorial()
                }
                .fullScreenCover(isPresented: $showTutorial) {
                    TutorialView()
                }
        }
    }

    private var mainContent: some View {
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
                    .padding(.top, geometry.size.height * ViewSpacing.contentSpacing)
                    
                    Spacer()
                        .frame(
                            minHeight: geometry.size.height * 0.06,
                            maxHeight: geometry.size.height * 0.08
                        )
                    
                    RecentEmotionsView(
                        isLoading: isLoading,
                        recentEmotions: recentEmotions,
                        timeString: RelativeDateFormatter.relativeTimeString,
                        geometry: geometry
                    )
                    
                    Spacer()
                        .frame(height: geometry.size.height * ViewSpacing.contentSpacing)
                    
                    Button {
                        showDownloadView = true
                    } label: {
                        HStack {
                            Text("download your data")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.appBackground)
                        .overlay(
                            Rectangle()
                                .strokeBorder(Color.primary, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
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
        .sheet(isPresented: $showDownloadView) {
            DownloadView()
        }
        .task {
            await fetchEmotions()
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
                    weekEmotions: weekEmotions
                )
            }
        }
    }
    
    private var emotionDetailDestination: some View {
        EmotionDetailView(
            emotion: selectedEmotion ?? "",
            deeperEmotions: emotions[selectedEmotion ?? ""] ?? [],
            onSelect: handleDeeperEmotionSelect,
            showEmotionDetail: $showEmotionDetail
        )
        .environmentObject(emotionService)
    }
    
    private func clearState() {
        weekEmotions = []
        recentEmotions = []
        navigationId = UUID()
    }
    
    private func handleEmotionTap(_ emotion: String) {
        selectedEmotion = emotion
        showEmotionDetail = true
    }
    
    private func handleDeeperEmotionSelect(_ deeperEmotion: String) {
        Task {
            do {
                try await emotionService.logEmotion(emotion: deeperEmotion)
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
            let (all, recent) = try await EmotionDatabaseService.fetchEmotions(userId: userId)
            
            await MainActor.run {
                self.weekEmotions = all
                self.recentEmotions = recent
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
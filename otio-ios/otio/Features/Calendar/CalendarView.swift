import SwiftUI

struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var emotionService: EmotionService
    @State private var isInitializing = true
    @State private var selectedDate = Date()
    @State private var viewMode: CalendarViewMode = .month
    
    // Z-index layers
    private enum ZIndex {
        static let calendar = 0.0
        static let controls = 1.0
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.appBackground
                        .ignoresSafeArea()
                    
                    if isInitializing {
                        VStack {
                            ProgressView()
                                .padding(.bottom, 8)
                            Text("preparing your calendar")
                                .font(.custom("IBMPlexMono-Light", size: 13))
                                .foregroundColor(.primary)
                        }
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: ViewSpacing.subtitleToContent) {
                                Text("trace your steps")
                                    .font(.custom("IBMPlexMono-Light", size: 17))
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    // .padding(.top, -32)
                                
                                CalendarControlBar(selectedDate: $selectedDate, viewMode: $viewMode, geometry: geometry)
                                    // .padding(.top, 16)
                                    .zIndex(ZIndex.controls)
                                
                                mainContent(geometry: geometry)
                                    .zIndex(ZIndex.calendar)
                            }
                            .padding(.vertical, ViewSpacing.screenVerticalPadding)
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("review")
                        .font(.custom("IBMPlexMono-Light", size: 22))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                            .imageScale(.medium)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await fetchCalendarData()
            }
            .onChange(of: selectedDate) { newDate in
                // Only fetch if we're moving to a different month
                let calendar = Calendar.current
                let oldComponents = calendar.dateComponents([.year, .month], from: selectedDate)
                let newComponents = calendar.dateComponents([.year, .month], from: newDate)
                
                if oldComponents.year != newComponents.year || oldComponents.month != newComponents.month {
                    Task {
                        await fetchCalendarData()
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { gesture in
                        if gesture.translation.width > 100 {
                            dismiss()
                        }
                    }
            )
        }
    }
    
    private func fetchCalendarData() async {
        do {
            try await emotionService.fetchEmotionsForMonth(selectedDate)
            if isInitializing {
                isInitializing = false
            }
        } catch {
            print("Error fetching calendar data:", error)
            isInitializing = false
        }
    }
    
    @ViewBuilder
    private func mainContent(geometry: GeometryProxy) -> some View {
        switch viewMode {
        case .month:
            MonthView(selectedDate: $selectedDate, viewMode: $viewMode, geometry: geometry)
        case .day:
            DayView(selectedDate: $selectedDate, geometry: geometry)
        }
    }
} 
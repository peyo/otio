import SwiftUI

public struct DayView: View {
    @EnvironmentObject var emotionService: EmotionService
    @Binding var selectedDate: Date
    let geometry: GeometryProxy
    @State private var dayEmotions: [EmotionData] = []
    @Environment(\.dismiss) private var dismiss
    
    public init(selectedDate: Binding<Date>, geometry: GeometryProxy) {
        self._selectedDate = selectedDate
        self.geometry = geometry
    }
    
    public var body: some View {
        VStack(spacing: 32) {
            // Day header
            Text(calendar.weekdaySymbols[calendar.component(.weekday, from: selectedDate) - 1].lowercased())
                .font(.custom("IBMPlexMono-Light", size: 15))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            // Emotions list
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if dayEmotions.isEmpty {
                        // Empty state
                        HStack(spacing: 16) {
                            Image(systemName: "leaf.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40)
                                .foregroundColor(.primary)
                            
                            Text("nothing recorded, and that's okay.")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.appCardBackground)
                    } else {
                        ForEach(dayEmotions) { emotion in
                            EmotionCard(
                                emotion: emotion,
                                timeString: { date in
                                    RelativeDateFormatter.relativeTimeString(from: date)
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .onAppear {
            updateDayEmotions()
        }
        .onChange(of: emotionService.calendarEmotions) { _ in
            updateDayEmotions()
        }
        .onChange(of: selectedDate) { _ in
            updateDayEmotions()
        }
    }
    
    private let calendar = Calendar.current
    
    private func updateDayEmotions() {
        let dayStart = calendar.startOfDay(for: selectedDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        
        dayEmotions = emotionService.calendarEmotions
            .filter { emotion in
                emotion.date >= dayStart && emotion.date < dayEnd
            }
            .sorted { $0.date > $1.date }
    }
} 
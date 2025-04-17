import SwiftUI

struct MonthView: View {
    @EnvironmentObject var emotionService: EmotionService
    @Binding var selectedDate: Date
    @Binding var viewMode: CalendarViewMode
    let geometry: GeometryProxy
    @State private var emotionsByDate: [Date: [EmotionData]] = [:]
    @Environment(\.dismiss) private var dismiss
    
    init(selectedDate: Binding<Date>, viewMode: Binding<CalendarViewMode>, geometry: GeometryProxy) {
        self._selectedDate = selectedDate
        self._viewMode = viewMode
        self.geometry = geometry
    }
    
    // private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols
    private let weekdaySymbols = ["su", "m", "t", "w", "th", "f", "s"]
    
    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        
        // Get the first day of the month
        guard let firstDayOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: selectedDate)
        ) else { return [] }
        
        // Get the last day of the month
        guard let lastDayOfMonth = calendar.date(
            byAdding: DateComponents(month: 1, day: -1),
            to: firstDayOfMonth
        ) else { return [] }
        
        // Calculate the first weekday of the month (0 = Sunday, 1 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        // Calculate leading empty cells
        let leadingEmptyCells = firstWeekday - 1
        
        // Calculate total days in the month
        let daysInMonth = calendar.component(.day, from: lastDayOfMonth)
        
        // Create array with empty cells and dates
        var days: [Date?] = Array(repeating: nil, count: leadingEmptyCells)
        
        // Add actual dates
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        // Add trailing empty cells to complete the grid
        let totalCells = 42 // 6 rows × 7 columns
        let trailingEmptyCells = totalCells - days.count
        days.append(contentsOf: Array(repeating: nil, count: trailingEmptyCells))
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                    Text(symbol)
                        .font(.custom("IBMPlexMono-Light", size: 15))
                        .foregroundColor(.primary)
                        .frame(width: (geometry.size.width - 32) / 7)
                }
            }
            .padding(.top, 16)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                    calendarCell(for: date)
                }
            }
            .padding(.horizontal, 16)
        }
        .onAppear {
            updateEmotionsByDate()
        }
        .onChange(of: emotionService.calendarEmotions) { _ in
            updateEmotionsByDate()
        }
    }
    
    @ViewBuilder
    private func calendarCell(for date: Date?) -> some View {
        let cellWidth = (geometry.size.width - 32) / 7
        let cellHeight = cellWidth * 1.2  // Make cells slightly taller than wide
        
        Group {
            if let date = date {
                let day = Calendar.current.component(.day, from: date)
                let isToday = Calendar.current.isDate(date, inSameDayAs: Date())
                let emotions = emotionsForDate(date)
                
                Button {
                    selectedDate = date
                    withAnimation {
                        viewMode = .day
                    }
                } label: {
                    VStack(alignment: .center, spacing: 4) {
                        // Date number - always at the top
                        Text("\(day)")
                            .font(.custom("IBMPlexMono-Light", size: 15))
                            .foregroundColor(.primary)
                            .padding(.top, 4)
                        
                        Spacer()
                            .frame(height: 2)
                        
                        // Emotion count or empty space to maintain consistent height
                        if !emotions.isEmpty {
                            Text("\(emotions.count)")
                                .font(.custom("IBMPlexMono-Light", size: 13))
                                .foregroundColor(.primary)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 6)
                                .background(
                                    Rectangle()
                                        .fill(Color.appCardBackground)
                                )
                        } else {
                            Spacer()
                                .frame(height: 23) // Match height of emotion count with padding
                        }
                        
                        Spacer()
                    }
                    .frame(width: cellWidth, height: cellHeight)
                    .background(
                        // Today indicator
                        isToday ? Rectangle()
                            .strokeBorder(Color.primary, lineWidth: 1) : nil
                    )
                }
            } else {
                // Empty cell
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: cellWidth, height: cellHeight)
            }
        }
    }
    
    private func emotionsForDate(_ date: Date) -> [EmotionData] {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let emotions = emotionsByDate[normalizedDate] ?? []
        if !emotions.isEmpty {
            print("Found \(emotions.count) emotions for \(normalizedDate)")
        }
        return emotions
    }
    
    private func updateEmotionsByDate() {
        let calendar = Calendar.current
        var newEmotionsByDate: [Date: [EmotionData]] = [:]
        
        print("Calendar emotions count: \(emotionService.calendarEmotions.count)")
        
        for emotion in emotionService.calendarEmotions {
            let normalizedDate = calendar.startOfDay(for: emotion.date)
            var emotions = newEmotionsByDate[normalizedDate] ?? []
            emotions.append(emotion)
            newEmotionsByDate[normalizedDate] = emotions
            print("Added emotion for date: \(normalizedDate), total for this date: \(emotions.count)")
        }
        
        emotionsByDate = newEmotionsByDate
        print("Total dates with emotions: \(emotionsByDate.count)")
    }
} 
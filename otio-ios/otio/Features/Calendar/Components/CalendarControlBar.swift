import SwiftUI

struct CalendarControlBar: View {
    @Binding var selectedDate: Date
    @Binding var viewMode: CalendarViewMode
    @State private var isShowingViewModeSelector = false
    @Environment(\.dismiss) private var dismiss
    let geometry: GeometryProxy
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()
    
    // Width for the dropdown menu based on "month" text
    private var dropdownWidth: CGFloat {
        let font = UIFont(name: "IBMPlexMono-Light", size: 15) ?? .systemFont(ofSize: 15)
        let monthText = "month"
        let textWidth = (monthText as NSString).size(withAttributes: [.font: font]).width
        return textWidth + 41 // Adding padding and chevron space
    }
    
    private func isLongMonth(_ date: Date) -> Bool {
        let month = monthFormatter.string(from: date)
        return month.count > 6  // September and December are the longest
    }
    
    private func formattedDate() -> String {
        let formatter = viewMode == .month ? monthFormatter : dayFormatter
        return formatter.string(from: selectedDate).lowercased()
    }
    
    private func fontSize() -> CGFloat {
        return 13
    }
    
    private func navigateBackward() {
        let calendar = Calendar.current
        switch viewMode {
        case .month:
            if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
                selectedDate = newDate
            }
        case .day:
            if let newDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
                selectedDate = newDate
            }
        }
    }
    
    private func navigateForward() {
        let calendar = Calendar.current
        switch viewMode {
        case .month:
            if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
                selectedDate = newDate
            }
        case .day:
            if let newDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
                selectedDate = newDate
            }
        }
    }
    
    private func goToToday() {
        selectedDate = Date()
    }
    
    private func handleViewModeChange(to newMode: CalendarViewMode) {
        let calendar = Calendar.current
        if viewMode == .month && newMode == .day {
            // When switching from month to day, go to the first day of the current month
            if let firstDayOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: selectedDate)
            ) {
                selectedDate = firstDayOfMonth
            }
        }
        viewMode = newMode
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Today button
            Button(action: goToToday) {
                Text("today")
                    .font(.custom("IBMPlexMono-Light", size: 15))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.primary, lineWidth: 1)
                    )
            }
            
            // Month navigation
            HStack(spacing: 8) {
                HStack(spacing: 12) {
                    Button(action: navigateBackward) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: navigateForward) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.primary)
                    }
                }
                
                Text(formattedDate())
                    .font(.custom("IBMPlexMono-Light", size: fontSize()))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // View mode selector button
            Button {
                withAnimation {
                    isShowingViewModeSelector.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewMode.rawValue)
                        .font(.custom("IBMPlexMono-Light", size: 15))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Rectangle()
                        .stroke(Color.primary, lineWidth: 1)
                )
            }
            .overlay(alignment: .trailing) {
                if isShowingViewModeSelector {
                    ZStack {
                        // Background overlay for dismissal
                        Color.black.opacity(0.01) // Tiny bit of opacity to ensure it captures taps
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation {
                                    isShowingViewModeSelector = false
                                }
                            }
                        
                        // Dropdown menu
                        VStack(spacing: 0) {
                            ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                                Button {
                                    handleViewModeChange(to: mode)
                                    withAnimation {
                                        isShowingViewModeSelector = false
                                    }
                                } label: {
                                    Text(mode.rawValue)
                                        .font(.custom("IBMPlexMono-Light", size: 15))
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(mode == viewMode ? Color.appCardBackground : Color.appBackground)
                                }
                            }
                        }
                        .background(Color.appBackground)
                        .overlay(
                            Rectangle()
                                .stroke(Color.primary, lineWidth: 1)
                        )
                        .frame(width: dropdownWidth)
                        .offset(y: 59)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }
}

struct ConditionalFrame: ViewModifier {
    let condition: Bool
    let width: CGFloat
    var alignment: Alignment = .center
    
    func body(content: Content) -> some View {
        if condition {
            content.frame(width: width, alignment: alignment)
        } else {
            content
        }
    }
} 
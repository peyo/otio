import SwiftUI

struct DayToggleButton: View {
    let day: Weekday
    let isSelected: Bool
    let action: () -> Void
    
    private let buttonSize: CGFloat = 24
    
    var body: some View {
        Button(action: action) {
            Text(day.rawValue)
                .font(.custom("IBMPlexMono-Light", size: 15))
                .frame(width: buttonSize, height: buttonSize)
                .foregroundColor(isSelected ? .appBackground : .primary)
                .background(
                    Rectangle()
                        .fill(isSelected ? Color.primary : Color.clear)
                )
                .overlay(
                    Rectangle()
                        .strokeBorder(Color.primary, lineWidth: 1)
                )
        }
    }
}

struct TimeField: View {
    @Binding var hour: Int
    @Binding var minute: Int
    @FocusState private var isFocused: Bool
    @State private var timeText: String = ""
    
    var body: some View {
        TextField("00:00", text: $timeText)
            .font(.custom("IBMPlexMono-Light", size: 15))
            .foregroundColor(.primary)
            .frame(width: 60, height: 24)
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .focused($isFocused)
            .overlay(
                Rectangle()
                    .strokeBorder(Color.primary, lineWidth: 1)
            )
            .onAppear {
                timeText = String(format: "%02d:%02d", hour, minute)
            }
            .onChange(of: isFocused) { focused in
                if focused {
                    // Clear text when field is focused
                    timeText = ""
                } else {
                    // Restore formatted time when field loses focus
                    timeText = String(format: "%02d:%02d", hour, minute)
                }
            }
            .onChange(of: timeText) { newValue in
                let numbers = newValue.filter { $0.isNumber }
                let limited = String(numbers.prefix(4))
                
                if limited.count >= 2 {
                    let index = limited.index(limited.startIndex, offsetBy: 2)
                    let hourStr = String(limited[..<index])
                    let minuteStr = limited.count > 2 ? String(limited[index...]) : "00"
                    
                    if let newHour = Int(hourStr), let newMinute = Int(minuteStr) {
                        hour = max(1, min(newHour, 12))
                        minute = max(0, min(newMinute, 59))
                    }
                }
            }
    }
}

struct AMPMToggle: View {
    @Binding var isAM: Bool
    
    private let buttonSize: CGFloat = 24
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                isAM = true
            } label: {
                Text("am")
                    .font(.custom("IBMPlexMono-Light", size: 15))
                    .foregroundColor(isAM ? .appBackground : .primary)
                    .frame(width: buttonSize, height: buttonSize)
                    .background(
                        Rectangle()
                            .fill(isAM ? Color.primary : Color.clear)
                    )
                    .overlay(
                        Rectangle()
                            .strokeBorder(Color.primary, lineWidth: 1)
                    )
            }
            
            Button {
                isAM = false
            } label: {
                Text("pm")
                    .font(.custom("IBMPlexMono-Light", size: 15))
                    .foregroundColor(!isAM ? .appBackground : .primary)
                    .frame(width: buttonSize, height: buttonSize)
                    .background(
                        Rectangle()
                            .fill(!isAM ? Color.primary : Color.clear)
                    )
                    .overlay(
                        Rectangle()
                            .strokeBorder(Color.primary, lineWidth: 1)
                    )
            }
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Rectangle()
                .fill(configuration.isOn ? Color.primary : Color.clear)
                .frame(width: 20, height: 20)
                .overlay(
                    Rectangle()
                        .strokeBorder(Color.primary, lineWidth: 1)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}
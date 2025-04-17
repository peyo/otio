import SwiftUI

struct ReminderSettingsView: View {
    @ObservedObject var reminderManager: ReminderManager
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 16) {
                // Enable/Disable Toggle
                Toggle(isOn: $reminderManager.preferences.isEnabled) {
                    Text("self-compassion reminders")
                        .font(.custom("IBMPlexMono-Light", size: 15))
                }
                .toggleStyle(CheckboxToggleStyle())
                
                if reminderManager.preferences.isEnabled {
                    // Day Selection
                    HStack(spacing: 12) {
                        ForEach(Weekday.allCases, id: \.self) { day in
                            DayToggleButton(
                                day: day,
                                isSelected: reminderManager.preferences.selectedDays.contains(day),
                                action: {
                                    if reminderManager.preferences.selectedDays.contains(day) {
                                        reminderManager.preferences.selectedDays.remove(day)
                                    } else {
                                        reminderManager.preferences.selectedDays.insert(day)
                                    }
                                }
                            )
                        }
                    }
                    
                    // Time Selection
                    HStack(spacing: 16) {
                        TimeField(
                            hour: Binding(
                                get: { reminderManager.preferences.hour },
                                set: { reminderManager.preferences.hour = $0 }
                            ),
                            minute: Binding(
                                get: { reminderManager.preferences.minute },
                                set: { reminderManager.preferences.minute = $0 }
                            )
                        )
                        
                        AMPMToggle(
                            isAM: Binding(
                                get: { reminderManager.preferences.isAM },
                                set: { reminderManager.preferences.isAM = $0 }
                            )
                        )
                    }
                    
                    // Example notification
                    VStack(alignment: .leading, spacing: 8) {
                        Text("example:")
                            .font(.custom("IBMPlexMono-Light", size: 13))
                            .foregroundColor(.secondary)
                        
                        Text("there's strength in stillness. doing nothing is sometimes exactly what you need.")
                            .font(.custom("IBMPlexMono-Light", size: 15))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .background(Color.appCardBackground)
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
}
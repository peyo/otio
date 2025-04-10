import SwiftUI
import FirebaseAuth

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userService: UserService
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    
                    // Subtitle
                    Text("celebrate your progress")
                        .font(.custom("IBMPlexMono-Light", size: 17))
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .padding(.top, 6)
                    
                    // User Information
                    VStack(alignment: .leading, spacing: 16) {
                        if let email = userService.userEmail {
                            Text("email address: \(email)")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .foregroundColor(.primary)
                        }
                        
                        if let joinDate = userService.joinDate {
                            Text("join date: \(formatDate(joinDate))")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .foregroundColor(.primary)
                        }
                        
                        Text("total breath time: \(formatMinutes(userService.totalBreathingMinutes))")
                            .font(.custom("IBMPlexMono-Light", size: 15))
                            .foregroundColor(.primary)
                        
                        Text("total meditation time: \(formatMinutes(userService.totalMeditationMinutes))")
                            .font(.custom("IBMPlexMono-Light", size: 15))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Credits and Logout Buttons
                    VStack(spacing: 24) {
                        NavigationLink {
                            ManifestoCreditsView()
                        } label: {
                            Text("manifesto / credits")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .foregroundColor(.primary)
                                .frame(height: 50)
                                .padding(.horizontal)
                                .overlay(
                                    Rectangle()
                                        .strokeBorder(Color.primary, lineWidth: 1)
                                )
                        }
                        
                        Button(action: {
                            userService.signOut()
                        }) {
                            Text("log out")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .foregroundColor(.primary)
                                .frame(height: 50)
                                .padding(.horizontal)
                                .overlay(
                                    Rectangle()
                                        .strokeBorder(Color.primary, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.bottom, 40)
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("overview")
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
        .onAppear {
            userService.fetchUserStats()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"  // Use custom format
        let formattedDate = formatter.string(from: date)
        return formattedDate.lowercased()  // Convert to lowercase
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
}
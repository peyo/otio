import SwiftUI
import FirebaseAuth
import UserNotifications

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userService: UserService
    @StateObject private var reminderManager = ReminderManager()
    @State private var isKeyboardVisible = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Subtitle
                            Text("review your details")
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
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            
                            // Add Divider
                            Rectangle()
                                .fill(Color.appCardBackground)
                                .frame(height: 1)
                                .padding(.horizontal, 20)
                            
                            // Reminder Settings
                            ReminderSettingsView(reminderManager: reminderManager)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 140)
                        }
                    }
                    
                    Spacer()
                    
                    // Bottom buttons
                    VStack(spacing: 24) {
                        NavigationLink {
                            ManifestoCreditsView()
                        } label: {
                            Text("manifesto / credits")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(isKeyboardVisible ? Color.appCardBackground : Color.appBackground)
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
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(isKeyboardVisible ? Color.appCardBackground : Color.appBackground)
                                .overlay(
                                    Rectangle()
                                        .strokeBorder(Color.primary, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        (isKeyboardVisible ? Color.appCardBackground : Color.appBackground)
                            .edgesIgnoringSafeArea(.bottom)
                    )
                    .padding(.bottom, isKeyboardVisible ? 0 : 16)
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                             to: nil, 
                                             from: nil, 
                                             for: nil)
            }
            .gesture(
                DragGesture()
                    .onEnded { gesture in
                        if gesture.translation.width > 100 {
                            dismiss()
                        }
                    }
            )
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
        }
        .onAppear {
            userService.fetchUserStats()
            setupKeyboardObservers()
        }
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { _ in
            isKeyboardVisible = true
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            isKeyboardVisible = false
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let formattedDate = formatter.string(from: date)
        return formattedDate.lowercased()
    }
}
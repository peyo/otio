import SwiftUI
import FirebaseAuth

struct DownloadView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fromDateText = ""
    @State private var toDateText = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var isShowingShareSheet = false
    @State private var shareURL: URL? = nil
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }()
    
    private func formatDateString(_ input: String, oldValue: String) -> String {
        // Remove any non-numeric characters
        let numbers = input.filter { $0.isNumber }
        
        // Limit to 8 digits (MMDDYYYY)
        let limited = String(numbers.prefix(8))
        
        // Add formatting
        var formatted = ""
        for (index, char) in limited.enumerated() {
            if index == 2 || index == 4 {
                formatted += "/"
            }
            formatted += String(char)
        }
        
        return formatted
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                ZStack {
                    Color.appBackground
                        .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("date range (required)")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text("from")
                                    .font(.custom("IBMPlexMono-Light", size: 15))
                                    .foregroundColor(.primary)
                                    .frame(width: 40, alignment: .leading)
                                
                                TextField("mm/dd/yyyy", text: Binding(
                                    get: { fromDateText },
                                    set: { fromDateText = formatDateString($0, oldValue: fromDateText) }
                                ))
                                    .font(.custom("IBMPlexMono-Light", size: 15))
                                    .foregroundColor(.primary)
                                    .keyboardType(.numberPad)
                                    .textContentType(.none)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.appBackground)
                                    .overlay(
                                        Rectangle()
                                            .strokeBorder(Color.primary, lineWidth: 1)
                                    )
                            }
                            
                            HStack {
                                Text("to")
                                    .font(.custom("IBMPlexMono-Light", size: 15))
                                    .foregroundColor(.primary)
                                    .frame(width: 40, alignment: .leading)
                                
                                TextField("mm/dd/yyyy", text: Binding(
                                    get: { toDateText },
                                    set: { toDateText = formatDateString($0, oldValue: toDateText) }
                                ))
                                    .font(.custom("IBMPlexMono-Light", size: 15))
                                    .foregroundColor(.primary)
                                    .keyboardType(.numberPad)
                                    .textContentType(.none)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.appBackground)
                                    .overlay(
                                        Rectangle()
                                            .strokeBorder(Color.primary, lineWidth: 1)
                                    )
                            }
                        }
                        //.padding(.horizontal, 20)
                        
                        Spacer()
                            .frame(height: 200)  // Fixed space for download button
                    }
                    .padding()
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                             to: nil, 
                                             from: nil, 
                                             for: nil)
            }
            .background(Color.appBackground)
            .overlay(alignment: .bottom) {
                VStack {
                    Button(action: handleDownload) {
                        if isLoading {
                            ProgressView()
                                .tint(.primary)
                        } else {
                            Text("download")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(keyboardHeight > 0 ? Color.appCardBackground : Color.appBackground)
                                .overlay(
                                    Rectangle()
                                        .strokeBorder(Color.primary, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.vertical, 16)
                }
                .frame(maxWidth: .infinity)
                .background(
                    (keyboardHeight > 0 ? Color.appCardBackground : Color.appBackground)
                        .edgesIgnoringSafeArea(.bottom)
                )
                .padding(.bottom, keyboardHeight > 0 ? 0 : 16)
            }
            .overlay {
                if showError {
                    // Semi-transparent background
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    // Alert content
                    VStack(spacing: 24) {
                        Text("oops")
                            .font(.custom("IBMPlexMono-Light", size: 17))
                            .fontWeight(.semibold)
                        
                        Text(errorMessage)
                            .font(.custom("IBMPlexMono-Light", size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            showError = false
                        } label: {
                            Text("ok")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .overlay(
                                    Rectangle()
                                        .strokeBorder(Color.primary, lineWidth: 1)
                                )
                        }
                    }
                    .padding(24)
                    .background(Color.appBackground)
                    .padding(.horizontal, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("download")
                        .font(.custom("IBMPlexMono-Light", size: 22))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                    let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
                    keyboardHeight = keyboardFrame.height
                }
                
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    keyboardHeight = 0
                }
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    private func handleDownload() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Debug: No user ID found")
            errorMessage = "User not logged in"
            showError = true
            return
        }
        
        print("Debug: User ID found:", userId)
        
        // Validate dates
        guard !fromDateText.isEmpty, !toDateText.isEmpty else {
            print("Debug: Empty date fields")
            errorMessage = "Please enter both dates"
            showError = true
            return
        }
        
        print("Debug: Dates entered - from:", fromDateText, "to:", toDateText)
        
        // Parse dates and set them to start/end of day
        guard let fromDate = dateFormatter.date(from: fromDateText),
              let toDate = dateFormatter.date(from: toDateText) else {
            print("Debug: Failed to parse dates")
            errorMessage = "Invalid date format"
            showError = true
            return
        }
        
        // Set fromDate to start of day (00:00:00)
        let calendar = Calendar.current
        let fromStartOfDay = calendar.startOfDay(for: fromDate)
        
        // Set toDate to end of day (23:59:59)
        guard let toEndOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: toDate) else {
            print("Debug: Failed to set end of day")
            errorMessage = "Invalid date"
            showError = true
            return
        }
        
        print("Debug: Adjusted dates - from:", fromStartOfDay, "to:", toEndOfDay)
        print("Debug: Timestamps - from:", fromStartOfDay.timeIntervalSince1970 * 1000, "to:", toEndOfDay.timeIntervalSince1970 * 1000)
        
        // Validate date range
        guard fromStartOfDay <= toEndOfDay else {
            print("Debug: Invalid date range")
            errorMessage = "Start date must be before or equal to end date"
            showError = true
            return
        }
        
        print("Debug: Starting download process")
        isLoading = true
        
        Task {
            do {
                print("Debug: Fetching emotions")
                // Fetch emotions for the date range
                let emotions = try await EmotionDatabaseService.fetchEmotionsForDateRange(
                    userId: userId,
                    startDate: fromStartOfDay,
                    endDate: toEndOfDay
                )
                
                print("Debug: Found \(emotions.count) emotions")
                
                // Convert emotions to a format for export (e.g., CSV)
                let csvData = formatEmotionsForExport(emotions)
                print("Debug: CSV data created, length:", csvData.count)
                
                // Create temporary file
                let temporaryDirectoryURL = FileManager.default.temporaryDirectory
                let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent("otio_emotions.csv")
                
                try csvData.data(using: .utf8)?.write(to: temporaryFileURL)
                print("Debug: CSV file created at:", temporaryFileURL.path)
                
                await MainActor.run {
                    shareURL = temporaryFileURL
                    isShowingShareSheet = true
                    isLoading = false
                }
            } catch {
                print("Debug: Error occurred:", error)
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func formatEmotionsForExport(_ emotions: [EmotionData]) -> String {
        var csv = "Date,Emotion,Energy Level,Log\n"
        
        // Format each emotion as a CSV row
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for emotion in emotions {
            let date = dateFormatter.string(from: emotion.date)
            let emotionName = emotion.emotion
            let energyLevel = emotion.energyLevel.map { String($0) } ?? ""
            let log = emotion.log?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            csv += "\(date),\(emotionName),\(energyLevel),\(log)\n"
        }
        
        return csv
    }
    
    private func shareData(_ data: String) {
        let csvData = data.data(using: .utf8) ?? Data()
        
        // Create a temporary file
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent("otio_emotions.csv")
        
        do {
            try csvData.write(to: temporaryFileURL)
            print("Debug: CSV file created at:", temporaryFileURL.path)
            
            // Set the URL and show share sheet
            shareURL = temporaryFileURL
            isShowingShareSheet = true
            
        } catch {
            print("Debug: Error creating temporary file:", error)
            errorMessage = "Failed to create export file"
            showError = true
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
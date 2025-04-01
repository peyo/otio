import SwiftUI

struct TutorialView: View {
    @StateObject private var tutorialState = TutorialState()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme  // Get the current color scheme
    @State private var showSwipeHint = true
    
    var body: some View {
        TabView(selection: $tutorialState.currentSlide) {
            ForEach(tutorialState.slides.indices, id: \.self) { index in
                VStack(spacing: 20) {
                    // Image - choose based on color scheme
                    let imageName = colorScheme == .dark ? 
                        tutorialState.slides[index].darkModeImage : 
                        tutorialState.slides[index].lightModeImage
                    
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: UIScreen.main.bounds.height * 0.6)
                        .padding(.top, 40)
                    
                    // Title
                    /*
                    Text(tutorialState.slides[index].title)
                        .font(.custom("IBMPlexMono-Light", size: 17))
                        .fontWeight(.semibold)
                    */
                    
                    // Description
                    Text(tutorialState.slides[index].description)
                        .font(.custom("IBMPlexMono-Light", size: 15))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                }
                // Swipe hint overlay
                .overlay(
                    Group {
                        if showSwipeHint && index == 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("swipe")
                                    .font(.custom("IBMPlexMono-Light", size: 15))
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.primary.opacity(0.7))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.appCardBackground.opacity(0.8))
                            .opacity(showSwipeHint ? 1 : 0)
                            .animation(
                                Animation
                                    .easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true),
                                value: showSwipeHint
                            )
                        }
                    }
                    , alignment: .center
                )
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .background(Color.appBackground)
        
        // Skip button in top-right
        .overlay(
            Button(tutorialState.isLastSlide ? "continue" : "skip") {
                tutorialState.completeTutorial()
                dismiss()
            }
            .font(.custom("IBMPlexMono-Light", size: 17))
            .foregroundColor(.primary)
            .padding()
            , alignment: .topTrailing
        )
        .onAppear {
            // Hide swipe hint after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showSwipeHint = false
                }
            }
            
            // Convert SwiftUI colors to UIColors for the page control
            let appTextUIColor = UIColor.label // This is what Color.appText uses
            let appCardBackgroundUIColor = UIColor.systemGray5 // This is what Color.appCardBackground uses
            
            // Customize the page indicator dots
            UIPageControl.appearance().currentPageIndicatorTintColor = appTextUIColor
            UIPageControl.appearance().pageIndicatorTintColor = appCardBackgroundUIColor
        }
        // Dismiss swipe hint on first swipe
        .onChange(of: tutorialState.currentSlide) { _ in
            if showSwipeHint {
                withAnimation {
                    showSwipeHint = false
                }
            }
        }
    }
}
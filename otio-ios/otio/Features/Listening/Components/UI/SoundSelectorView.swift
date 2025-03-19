import SwiftUI

struct SoundSelectorView: View {
    @Binding var currentSound: SoundType
    let isPlaying: Bool
    let geometry: GeometryProxy
    let onSoundSelected: (SoundType, Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 12) {
                    // Add an invisible spacer at the beginning to allow the first card to center
                    Spacer()
                        .frame(width: geometry.size.width / 2 - 50)
                        .opacity(0)
                    
                    // Show recommended sound first
                    VStack {
                        SoundCard(sound: .recommendedSound, isSelected: currentSound == .recommendedSound) {
                            if currentSound != .recommendedSound {
                                onSoundSelected(.recommendedSound, 0)
                                
                                // Scroll to center the selected sound
                                withAnimation {
                                    proxy.scrollTo(SoundType.recommendedSound, anchor: .center)
                                }
                            }
                        }
                        .font(.custom("IBMPlexMono-Light", size: 17))
                    }
                    .frame(height: 100)
                    .id(SoundType.recommendedSound)
                    
                    // Show remaining sounds
                    ForEach(SoundType.allCases.filter { $0 != .recommendedSound }, id: \.self) { sound in
                        VStack {
                            SoundCard(sound: sound, isSelected: currentSound == sound) {
                                if currentSound != sound {
                                    onSoundSelected(sound, 0)
                                    
                                    // Scroll to center the selected sound
                                    withAnimation {
                                        proxy.scrollTo(sound, anchor: .center)
                                    }
                                }
                            }
                            .font(.custom("IBMPlexMono-Light", size: 17))
                        }
                        .frame(height: 100)
                        .id(sound)
                    }
                    
                    // Add an invisible spacer at the end to allow the last card to center
                    Spacer()
                        .frame(width: geometry.size.width / 2 - 50)
                        .opacity(0)
                }
                .onAppear {
                    // Center the initial sound immediately without animation
                    proxy.scrollTo(currentSound, anchor: .center)
                }
            }
        }
        .padding(.horizontal)
    }
}
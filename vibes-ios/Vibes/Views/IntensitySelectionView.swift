import SwiftUI

struct IntensitySelectionView: View {
    let emotion: String
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Image(emojiFor(emotion))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)

                        Text("how \(emotion.lowercased()) are you feeling?")
                            .font(.headline)
                    }
                    .padding(.top, 40)

                    HStack(spacing: 20) {
                        ForEach(1...3, id: \.self) { intensity in
                            Button {
                                onSelect(intensity)
                                dismiss()
                            } label: {
                                Rectangle()
                                    .fill(Color.forEmotion(emotion).opacity(Double(intensity) / 3.0))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        VStack(spacing: 4) {
                                            Text("\(intensity)")
                                                .font(.title2)
                                            Text(intensityLabel(for: intensity))
                                                .font(.caption)
                                        }
                                            .foregroundColor(.primary)
                                    )
                            }
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("select intensity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func intensityLabel(for intensity: Int) -> String {
        switch intensity {
        case 1: return "a little"
        case 2: return "somewhat"
        case 3: return "very"
        default: return ""
        }
    }
}
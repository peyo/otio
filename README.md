# otio

## Project Overview

otio is a mobile application designed to help users track and analyze their emotional states. The app provides insights into users' emotional journeys, allowing them to understand their feelings better and recognize patterns in their emotional well-being.

## Features

- **Emotion Tracking**: Users can log their emotions, categorized by type (e.g., Happy, Sad, Anxious) and intensity. This data is securely stored in Firebase Realtime Database.
- **AI-Powered Insights**: The app generates personalized insights using OpenAI's GPT model, providing users with meaningful feedback about their emotional patterns.
- **Breathing Techniques**: Includes guided breathing exercises, such as box breathing, to help users manage stress and anxiety. Each exercise is paired with an instructional intro and a calming animation to guide the practice effectively.
- **Binaural Beats**: The app offers thoughtfully curate binaural beats designed to enhance your meditation practice, pairing each beat with guided introductions for every emotion. This approach invites you to sit, reflect, and ground yourself while enjoying oscillator-generated tones that promote mental clarity alongside a serene recording from Rancheria Falls, Yosemite.

## Technology Stack

- **Frontend**: 
  - SwiftUI for the iOS application
  - Firebase SDK for authentication and data management

- **Backend & Infrastructure**: 
  - Firebase Authentication for secure user management
  - Firebase Realtime Database for data storage
  - Firebase Cloud Functions for serverless operations
  - OpenAI GPT API for generating personalized emotional insights

## Installation

### iOS App

1. Open the `otio.xcodeproj` in Xcode.
2. Ensure you have the latest version of Xcode and the necessary iOS SDK.
3. Run the app on a simulator or a physical device.

### Firebase Setup

1. Create a new Firebase project in the [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication with Google Sign-In
3. Set up Realtime Database
4. Configure Cloud Functions with OpenAI integration

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue for any suggestions or improvements.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
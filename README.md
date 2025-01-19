# otio

## Project Overview

otio is a mobile application designed to help users track and analyze their emotional states. The app provides insights into users' emotional journeys, allowing them to understand their feelings better and recognize patterns in their emotional well-being.

## Features

- **Emotion Tracking**: Users can log their emotions, categorized by type (e.g., Happy, Sad, Anxious) and intensity. This data is stored securely in Firebase Realtime Database.
- **AI-Powered Insights**: The app generates personalized insights using OpenAI's GPT model, providing users with meaningful feedback about their emotional patterns.
- **Soundscapes for Focus and Calm**: The app includes carefully curated soundscapes designed to help users focus or relax. These include oscillator-generated tones for mental clarity and grounding, as well as a serene sound recording from Rancheria Falls, Yosemite, bringing nature's tranquility to your fingertips.
- **User Interface**: The app features a clean and intuitive interface built with SwiftUI, allowing users to easily input their emotions and view insights.

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

1. Open the `puls.xcodeproj` in Xcode.
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
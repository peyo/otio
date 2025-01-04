# Vibes

## Project Overview

Vibes is a mobile application designed to help users track and analyze their emotional states over time. The app provides insights into users' emotional journeys, allowing them to understand their feelings better and recognize patterns in their emotional well-being.

## Features

- **Emotion Tracking**: Users can log their emotions, categorized by type (e.g., Happy, Sad, Anxious) and intensity. This data is stored and can be analyzed over time.
- **Insights Generation**: The app generates insights based on the logged emotional data, providing users with meaningful feedback about their emotional patterns.
- **User Interface**: The app features a clean and intuitive interface built with SwiftUI, allowing users to easily input their emotions and view insights.

## Technology Stack

- **Backend**: 
  - Node.js with Express for the server.
  - Prisma ORM for database interactions with PostgreSQL.
  - OpenAI API for generating insights based on user data.

- **Frontend**: 
  - SwiftUI for the iOS application.
  - Integration with RESTful APIs for data submission and retrieval.

## Installation

### Backend

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd vibes-backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Set up environment variables in a `.env` file:
   ```
   DATABASE_URL=<your-database-url>
   OPENAI_API_KEY=<your-openai-api-key>
   ```

4. Run the server:
   ```bash
   npm start
   ```

### iOS App

1. Open the `Vibes.xcodeproj` in Xcode.
2. Ensure you have the latest version of Xcode and the necessary iOS SDK.
3. Run the app on a simulator or a physical device.

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue for any suggestions or improvements.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
# otio

## project overview

otio is a mobile application designed to help users track and analyze their emotional states. the app provides insights into users' emotional journeys, allowing them to understand their feelings better and recognize patterns in their emotional well-being.

## features

- **emotion tracking**: users can log their emotions—categorized by type (e.g., happy, sad, anxious) and their current energy level and an optional 100-character journal entry. all data is securely stored in firebase realtime database.
- **ai-powered insights**: the app generates personalized insights using openai's gpt model, providing users with meaningful feedback about their emotional patterns.

## technology stack

- **frontend**: 
  - swiftui for the ios application
  - firebase sdk for authentication and data management

- **backend & infrastructure**: 
  - firebase authentication for secure user management
  - firebase realtime database for data storage
  - firebase cloud functions for serverless operations
  - openai gpt api for generating personalized emotional insights

## installation

### ios app

1. open the `otio.xcodeproj` in xcode.
2. ensure you have the latest version of xcode and the necessary ios sdk.
3. run the app on a simulator or a physical device.

### firebase setup

1. create a new firebase project in the [firebase console](https://console.firebase.google.com)
2. enable authentication with google sign-in
3. set up realtime database
4. configure cloud functions with openai integration

## contributing

contributions are welcome! please feel free to submit a pull request or open an issue for any suggestions or improvements.

## license

this project is licensed under the mit license - see the [license](license) file for details.
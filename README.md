# otio

## project overview

otio is a mobile application designed to help users track and analyze their emotional states. the app provides insights into users' emotional journeys, allowing them to understand their feelings better and recognize patterns in their emotional well-being.

## features

- **emotion tracking**: users can log their emotions, categorized by type (e.g., happy, sad, anxious) and intensity. this data is securely stored in firebase realtime database.
- **ai-powered insights**: the app generates personalized insights using openai's gpt model, providing users with meaningful feedback about their emotional patterns.
- **breathing techniques**: includes guided breathing exercises, such as box breathing, to help users manage stress and anxiety. each exercise is paired with an instructional intro and a calming animation to guide the practice effectively.
- **binaural beats**: the app offers thoughtfully curate binaural beats designed to enhance your meditation practice, pairing each beat with guided introductions for every emotion. this approach invites you to sit, reflect, and ground yourself while enjoying oscillator-generated tones that promote mental clarity alongside a serene recording from rancheria falls, yosemite.

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
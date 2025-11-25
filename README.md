# [Sendbird](https://sendbird.com) UIKit for Flutter

[![Platform](https://img.shields.io/badge/platform-flutter-blue)](https://flutter.dev/)
[![Language](https://img.shields.io/badge/language-dart-blue)](https://dart.dev/)

Sendbird UIKit for Flutter is a set of prebuilt UI components that allows you to easily craft an in-app chat with all the essential messaging features. Our development kit includes light and dark themes, fonts, colors and more. You can customize these components to create an interactive messaging interface unique to your brand identity.

Sendbird UIKit supports only group channels currently. Follow the guide below to start sending a message from scratch.

## Requirements

The minimum requirements for UIKit for Flutter are:

- Dart 3.3.0 or later
- Flutter 3.19.0 or later

> **Note**: To support apple privacy manifest, add the contents of the `ios/Resources/PrivacyInfo.xcprivacy` file to the project’s `PrivacyInfo.xcprivacy`.

## Get started

You can start building a messaging experience in your app by installing Sendbird UIKit.

> **Note**: The quickest way to get started is by using the sample app from the [sample repo](https://github.com/sendbird/sendbird-uikit-sample-flutter).

### **Step 1** Create a Sendbird application from your dashboard

You need to create a Sendbird application on the [Sendbird Dashboard](https://dashboard.sendbird.com). You will need the App ID of your Sendbird application when initializing Sendbird UIKit.

> **Note**: Each Sendbird application can be integrated with a single client app. Within the same application, users can communicate with each other across all platforms, whether they are on mobile devices or on the web.

### **Step 2** Create a project

Create a new flutter project.

### **Step 3** Install UIKit

Add following dependencies and fonts for `SendbirdIcons` in `pubspec.yaml`.

```yaml
dependencies:
  sendbird_uikit: ^1.2.1
  sendbird_chat_sdk: ^4.7.0

flutter:
  fonts:
    - family: SendbirdIcons
      fonts:
        - asset: packages/sendbird_uikit/fonts/SendbirdIcons.ttf
```

Run `flutter pub get` command in your project directory.

### **Step 4** Initialize UIKit

You have to call `SendbirdUIKit.init()`, `SendbirdUIKit.connect()` and `SendbirdUIKit.provider()` before using UIKit.

```dart
import 'package:flutter/material.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SendbirdUIKit.init(appId: 'YOUR_APP_ID');
  await SendbirdUIKit.connect('YOUR_USER_ID');

  runApp(const MyApp());
}
```

### **Step 5** Apply UIKit screens

You can easily add `SBUGroupChannelListScreen`, `SBUGroupChannelCreateScreen` and `SBUGroupChannelScreen`. The main customizable classes are `SBUGroupChannelListScreen` and `SBUGroupChannelScreen`.

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return SendbirdUIKit.provider(
          child: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (context) => child!,
            ),
          ),
        );
      },
      home: const HomeScreen(), // Separate screen widget
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SBUGroupChannelListScreen(
          onCreateButtonClicked: () {
            moveToGroupChannelCreateScreen(context);
          },
          onListItemClicked: (channel) {
            moveToGroupChannelScreen(context, channel.channelUrl);
          },
        ),
      ),
    );
  }

  void moveToGroupChannelCreateScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: SBUGroupChannelCreateScreen(
              onChannelCreated: (channel) {
                moveToGroupChannelScreen(context, channel.channelUrl);
              },
            ),
          ),
        ),
      ),
    );
  }

  void moveToGroupChannelScreen(BuildContext context, String channelUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: SBUGroupChannelScreen(
              channelUrl: channelUrl,
            ),
          ),
        ),
      ),
    );
  }
}
```

### **Step 6** Send your first message

You can now run the application on an emulator or a plugged-in device. To send a message, you must first create a group channel by clicking on the icon in the top-right corner. Then, you can select users you wish to invite as members to your channel. Once the channel has been created, type your first message and press send. You've successfully sent your first message with Sendbird.

## Customizations

In the customizations section, we introduce ways to apply customization across the entire Sendbird UIKit for Flutter, as well as specific customization options for individual screens.

### Resource customization

- `SBUThemeProvider`
- `SBUStringProvider`
- `SBUColors`
- `SBUIcons`

### Screen customization

- `SBUGroupChannelListScreen`
  - `SBUGroupChannelCreateScreen`
- `SBUGroupChannelScreen`
  - `SBUGroupChannelInformationScreen`
  - `SBUGroupChannelMembersScreen`
    - `SBUGroupChannelInviteScreen`
  - `SBUGroupChannelModerationsScreen`
    - `SBUGroupChannelOperatorScreen`
    - `SBUGroupChannelMutedMembersScreen`
    - `SBUGroupChannelBannedUsersScreen`
- `SBUGroupChannelSettingsScreen`

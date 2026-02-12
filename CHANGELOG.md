## v1.4.1 (Feb 12, 2026)

### Improvements
- Fixed bugs regarding message huge gap

## v1.4.0 (Jan 16, 2026)

### Features
- Added `useChannelListTypingIndicator`, `useChannelTypingIndicator` and `channelTypingIndicatorType` parameters in `SendbirdUIKit.init()`

## v1.3.0 (Jan 2, 2026)

### Features
- Added `chooseFiles` parameter in `SendbirdUIKit.init()`
- Added `onListItemWithIndexClicked` parameter in `SBUGroupChannelScreen` constructor

## v1.2.1 (Nov 25, 2025)

### Improvements
- Fixed a bug related to initial theme setting

## v1.2.0 (Oct 29, 2025)

### Features
- Added a `navigatorKey` parameter in `SendbirdUIKit.init()` to show the delayed connecting dialog

## v1.1.0 (Jul 30, 2025)

### Features
- Added a `useMarkAsUnread` parameter in `SendbirdUIKit.init()` (The default value is false)

## v1.0.3 (May 7, 2025)

### Improvements
- Added handling of network error related exceptions in `MessageCollection`

## v1.0.2 (Mar 13, 2025)

### Improvements
- Fixed `provider()` in `SendbirdUIKit` to be available everywhere

## v1.0.1 (Jan 2, 2025)
- Updated `README.md`

## v1.0.0 (Dec 6, 2024)
- GA

## v1.0.0-beta.6 (Nov 29, 2024)

### Features
- Added a `chooseMedia` parameter in `SendbirdUIKit.init()`

### Improvements
- Fixed to support tree-shake-icons option when building applications
- Fixed some UI bugs

## v1.0.0-beta.5 (Nov 15, 2024)

### Features
- Added `useReaction`, `useOGTag` and `replyType` parameters in `init()` in `SendbirdUIKit`
- Added `onListItemClicked` parameter in `SBUGroupChannelScreen`
- Added video thumbnail for Android and iOS

## v1.0.0-beta.4 (Jul 11, 2024)

### Improvements
- Updated `README.md` and the documentation link

## v1.0.0-beta.3 (Jul 4, 2024)

### Improvements
- Updated dependency range for `intl` package from `^0.18.1` to `>=0.18.1 <1.0.0`
- Renamed `customMessageSender` to `customMessageInput`

## v1.0.0-beta.2 (Jun 14, 2024)

### Improvements
- Updated `README.md`

## v1.0.0-beta.1 (Jun 14, 2024)

### Features
- Added UIKit Screens for `GroupChannel` List
  - `SBUGroupChannelListScreen`
  - `SBUGroupChannelCreateScreen`
  - `SBUGroupChannelSettingsScreen`
- Added UIKit Screens for `GroupChannel`
  - `SBUGroupChannelScreen`
  - `SBUGroupChannelInformationScreen`
  - `SBUGroupChannelMembersScreen`
  - `SBUGroupChannelInviteScreen`
  - `SBUGroupChannelModerationsScreen`
  - `SBUGroupChannelOperatorsScreen`
  - `SBUGroupChannelMutedMembersScreen`
  - `SBUGroupChannelBannedUsersScreen`
- Added UIKit Resources
  - `SBUThemeProvider`
  - `SBUStringProvider`
  - `SBUColors`
  - `SBUIcons`

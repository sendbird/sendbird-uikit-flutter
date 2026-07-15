// Copyright (c) 2026 Sendbird, Inc. All rights reserved.

import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';

/// A handler that lets you customize message params right before they are sent
/// or updated.
///
/// This is the Flutter UIKit counterpart of Android UIKit's `CustomParamsHandler`
/// and iOS UIKit's `SBUGlobalCustomParams`.
///
/// Register an instance with [SendbirdUIKit.setCustomParamsHandler]. Each
/// callback is invoked once, right before the corresponding Sendbird Chat SDK
/// send or update call, and receives the params object so you can mutate it in
/// place. For example, to trim leading and trailing whitespace from an outgoing
/// user message:
///
/// ```dart
/// class MyCustomParamsHandler extends SBUCustomParamsHandler {
///   @override
///   void onBeforeSendUserMessage(UserMessageCreateParams params) {
///     params.message = params.message.trim();
///   }
/// }
///
/// SendbirdUIKit.setCustomParamsHandler(MyCustomParamsHandler());
/// ```
///
/// All methods have empty default implementations, so you only need to override
/// the ones you want to customize.
abstract class SBUCustomParamsHandler {
  /// Called before sending a user message.
  ///
  /// Mutate [params] to customize the message before it is sent.
  void onBeforeSendUserMessage(UserMessageCreateParams params) {}

  /// Called before updating (editing) a user message.
  ///
  /// Mutate [params] to customize the message before it is updated.
  void onBeforeUpdateUserMessage(UserMessageUpdateParams params) {}

  /// Called before sending a file message.
  ///
  /// Mutate [params] to customize the file message before it is sent.
  void onBeforeSendFileMessage(FileMessageCreateParams params) {}

  /// Called before sending a multiple files message.
  ///
  /// Mutate [params] to customize the multiple files message before it is sent.
  void onBeforeSendMultipleFilesMessage(
      MultipleFilesMessageCreateParams params) {}
}

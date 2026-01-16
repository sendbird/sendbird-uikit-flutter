// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/dialog/sbu_delayed_connecting_dialog.dart';
import 'package:sendbird_uikit/src/internal/provider/sbu_group_channel_collection_provider.dart';
import 'package:sendbird_uikit/src/internal/provider/sbu_message_collection_provider.dart';
import 'package:sendbird_uikit/src/internal/resource/sbu_text_styles.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_configuration_manager.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_file_send_queue_manager.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_mark_as_unread_manager.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_ogtag_manager.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_preferences.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_reaction_manager.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_reply_manager.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_typing_indicator_manager.dart';

/// SendbirdUIKit
class SendbirdUIKit {
  /// UIKit version
  static const version = '1.4.0';

  SendbirdUIKit._();

  static final SendbirdUIKit _uikit = SendbirdUIKit._();

  factory SendbirdUIKit() => _uikit;

  bool _isInitialized = false;

  // DelayedConnectingDialog
  GlobalKey<NavigatorState>? _navigatorKey;
  BuildContext? _currentDialogContext;
  bool? _addCloseButtonInDelayedConnectingDialog;

  Future<FileInfo?> Function()? _takePhoto;

  Future<FileInfo?> Function()? get takePhoto => _takePhoto;

  Future<FileInfo?> Function()? _takeVideo;

  Future<FileInfo?> Function()? get takeVideo => _takeVideo;

  Future<FileInfo?> Function()? _choosePhoto;

  Future<FileInfo?> Function()? get choosePhoto => _choosePhoto;

  Future<FileInfo?> Function()? _chooseMedia;

  Future<FileInfo?> Function()? get chooseMedia => _chooseMedia;

  Future<FileInfo?> Function()? _chooseDocument;

  Future<FileInfo?> Function()? get chooseDocument => _chooseDocument;

  Future<List<FileInfo>> Function()? _chooseFiles;

  Future<List<FileInfo>> Function()? get chooseFiles => _chooseFiles;

  Future<void> Function(
    String fileUrl,
    String? fileName,
    void Function() downloadCompleted,
  )? _downloadFile;

  Future<void> Function(
    String fileUrl,
    String? fileName,
    void Function() downloadCompleted,
  )? get downloadFile => _downloadFile;

  /// Applies the providers for [SendbirdUIKit].
  static Widget provider({
    required Widget child,
    bool enableTapToUnfocus = true,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: SBUThemeProvider(),
        ),
        ChangeNotifierProvider.value(
          value: SBUStringProvider(),
        ),
        ChangeNotifierProvider.value(
          value: SBUGroupChannelCollectionProvider(),
        ),
        ChangeNotifierProvider.value(
          value: SBUMessageCollectionProvider(),
        ),
      ],
      builder: FToastBuilder(),
      child: enableTapToUnfocus
          ? GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: child,
            )
          : child,
    );
  }

  /// Initializes [SendbirdUIKit] with given [appId].
  static Future<bool> init({
    required String appId,
    SendbirdChatOptions? options,
    SBUTheme? theme,
    GlobalKey<NavigatorState>?
        navigatorKey, // To show the delayed connecting dialog
    bool addCloseButtonInDelayedConnectingDialog = false,
    Future<FileInfo?> Function()? takePhoto,
    Future<FileInfo?> Function()? takeVideo,
    Future<FileInfo?> Function()? choosePhoto,
    Future<FileInfo?> Function()? chooseMedia,
    Future<FileInfo?> Function()? chooseDocument,
    Future<List<FileInfo>> Function()? chooseFiles,
    Future<void> Function(
      String fileUrl,
      String? fileName,
      void Function() downloadCompleted,
    )? downloadFile,
    bool useReaction = true, // This feature is not supported on the web.
    bool useOGTag = true,
    SBUReplyType replyType = SBUReplyType.quoteReply,
    bool? useMarkAsUnread,

    /// Whether to display typing indicators in the channel list (e.g., on each channel row).
    bool? useChannelListTypingIndicator,

    /// Whether to display typing indicators in the channel view for the active conversation.
    bool? useChannelTypingIndicator,

    /// The display style for typing indicators in the channel view (for example, text vs bubble).
    /// The default value is [SBUTypingIndicatorType.text].
    SBUTypingIndicatorType? channelTypingIndicatorType,
  }) async {
    SendbirdChat.addExtension('sb_uikit', version);

    await SendbirdChat.init(
      appId: appId,
      options: options,
    );

    SendbirdChat.addConnectionHandler(
        'sendbird-uikit-flutter', _MyConnectionHandler());

    await SBUPreferences().initialize();
    if (theme != null) {
      SBUThemeProvider().setTheme(theme);
    }

    _uikit._navigatorKey = navigatorKey;
    _uikit._addCloseButtonInDelayedConnectingDialog =
        addCloseButtonInDelayedConnectingDialog;

    _uikit._takePhoto = takePhoto;
    _uikit._takeVideo = takeVideo;
    _uikit._choosePhoto = choosePhoto;
    _uikit._chooseMedia = chooseMedia;
    _uikit._chooseDocument = chooseDocument;
    _uikit._chooseFiles = chooseFiles;
    _uikit._downloadFile = downloadFile;

    SBUReactionManager().useReaction = useReaction;
    SBUOGTagManager().useOGTag = useOGTag;
    SBUReplyManager().replyType = replyType;
    SBUMarkAsUnreadManager().useMarkAsUnread = useMarkAsUnread;
    SBUTypingIndicatorManager().useChannelListTypingIndicator =
        useChannelListTypingIndicator;
    SBUTypingIndicatorManager().useChannelTypingIndicator =
        useChannelTypingIndicator;
    SBUTypingIndicatorManager().channelTypingIndicatorType =
        channelTypingIndicatorType;

    _uikit._isInitialized = true;
    return true;
  }

  /// Checks if [SendbirdUIKit] is initialized.
  static bool isInitialized() {
    return _uikit._isInitialized;
  }

  /// Connects to [SendbirdUIKit] with given `userId`.
  static Future<bool> connect(
    String userId, {
    String? nickname,
    String? accessToken,
    String? apiHost,
    String? wsHost,
  }) async {
    bool result = true;
    try {
      await SendbirdChat.connect(
        userId,
        nickname: nickname,
        accessToken: accessToken,
        apiHost: apiHost,
        wsHost: wsHost,
      );

      SBUConfigurationManager().checkConfiguration(); // No await
      SBUReactionManager().initEmojiList(); // No await
    } catch (_) {
      result = false;
    }
    return result;
  }

  /// Disconnects from [SendbirdUIKit].
  static Future<bool> disconnect() async {
    bool result = true;
    try {
      await SendbirdChat.disconnect();
      await SBUPreferences().clear();
      SBUFileSendQueueManager().clearAllQueues();
    } catch (_) {
      result = false;
    }
    return result;
  }

  /// Gets [GroupChannelCollection] with [channelCollectionNo].
  /// Refers to [SBUGroupChannelListScreen.onGroupChannelCollectionReady].
  static GroupChannelCollection? getGroupChannelCollection(
    int channelCollectionNo,
  ) {
    return SBUGroupChannelCollectionProvider()
        .getCollection(channelCollectionNo);
  }

  /// Gets [MessageCollection] with [messageCollectionNo].
  /// Refers to [SBUGroupChannelScreen.onMessageCollectionReady].
  static MessageCollection? getMessageCollection(
    int messageCollectionNo,
  ) {
    return SBUMessageCollectionProvider().getCollection(messageCollectionNo);
  }

  /// Sets fontFamily.
  static void setFontFamily(String fontFamily) {
    SBUTextStyles.fontFamily = fontFamily;
  }

  // Shows the delayed connecting dialog with retryAfter time.
  static void _showDelayedConnectingDialog(int retryAfter) {
    final context = _uikit._navigatorKey?.currentContext;
    if (context != null) {
      if (_uikit._currentDialogContext != null) {
        Navigator.of(_uikit._currentDialogContext!, rootNavigator: true).pop();
        _uikit._currentDialogContext = null;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          _uikit._currentDialogContext = dialogContext;
          return SBUDelayedConnectingDialog(
            retryAfter: retryAfter,
            showCloseButton:
                _uikit._addCloseButtonInDelayedConnectingDialog ?? false,
          );
        },
      ).then((_) {
        _uikit._currentDialogContext = null;
      });
    }
  }

  // Dismisses the delayed connecting dialog if it is currently shown.
  static void _dismissDelayedConnectingDialog() {
    if (_uikit._currentDialogContext != null) {
      Navigator.of(_uikit._currentDialogContext!, rootNavigator: true).pop();
      _uikit._currentDialogContext = null;
    }
  }
}

class _MyConnectionHandler extends ConnectionHandler {
  @override
  void onConnected(String userId) {}

  @override
  void onDisconnected(String userId) {}

  @override
  void onReconnectFailed() {}

  @override
  void onReconnectStarted() {}

  @override
  void onReconnectSucceeded() {
    SendbirdUIKit._dismissDelayedConnectingDialog();
  }

  @override
  void onConnectionDelayed(int retryAfter) {
    if (retryAfter > 0) {
      SendbirdUIKit._showDelayedConnectingDialog(retryAfter);
    }
  }
}

// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_mark_as_unread_manager.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_reply_manager.dart';

class SBUMessageCollectionProvider with ChangeNotifier {
  static int currentCollectionNo = 1;

  final Map<int, MessageCollection> _collectionMap = {};
  final Map<int, bool?> _scrollToEndMap = {};
  final Map<int, BaseMessage?> _editingMessageMap = {};
  final Map<int, BaseMessage?> _replyingToMessageMap = {};
  final Map<int, bool?> _deletedChannelMap = {};

  final Map<String, bool> _isBottomOfScreenMap = {};
  final Map<String, bool> _didMarkAsUnreadMap = {};
  final Map<String, bool> _checkUnreadBadgeMap = {};
  final Map<String, bool> _hasSeenNewMessageLineMap = {};
  final Map<String, int> _myLastReadMap = {};
  final Map<String, bool> _freezeMyLastReadMap = {};
  final Map<String, bool> _enabledNewLineMap = {};
  final Map<String, int> _newMessageCountMap = {};

  // Multiple files message upload tracking
  final Map<String, Set<int>> _uploadedFileIndicesMap = {};

  SBUMessageCollectionProvider._();

  static final SBUMessageCollectionProvider _provider =
      SBUMessageCollectionProvider._();

  factory SBUMessageCollectionProvider() => _provider;

  int add({
    required GroupChannel channel,
    MessageListParams? params,
  }) {
    final collectionNo = currentCollectionNo++;

    ReplyType? replyType;
    if (params != null && params.replyType != null) {
      replyType = params.replyType;
    } else if (SBUReplyManager().isQuoteReplyAvailable(channel)) {
      replyType = ReplyType.onlyReplyToChannel;
    }

    final collection = MessageCollection(
      channel: channel,
      params: (params ?? MessageListParams())
        ..reverse = true // Supported reverse value is only true.
        ..replyType = replyType,
      handler: _MyMessageCollectionHandler(this, channel.channelUrl),
    );
    _collectionMap[collectionNo] = collection;
    return collectionNo;
  }

  void remove(int collectionNo) {
    final collection = _collectionMap[collectionNo];
    if (collection != null) {
      collection.dispose();
      _collectionMap.remove(collectionNo);

      _clearForMarkAsUnread(); // Check
      _newMessageCountMap.clear(); // Check
    }
  }

  MessageCollection? getCollection(int collectionNo) {
    return _collectionMap[collectionNo];
  }

  void _refresh([String? channelUrl, CollectionEventSource? eventSource]) {
    _checkScrollToEnd(channelUrl, eventSource);
    notifyListeners();
  }

  void _restart(String channelUrl) {
    for (final collectionNo in _getCollectionNoList(channelUrl)) {
      final collection = _collectionMap[collectionNo];
      if (collection != null) {
        remove(collectionNo);
        add(channel: collection.channel, params: collection.params);
      }
    }
  }

  List<int> _getCollectionNoList(String channelUrl) {
    final List<int> result = [];
    for (final collectionNo in _collectionMap.keys) {
      final collection = _collectionMap[collectionNo];
      if (channelUrl == collection?.channel.channelUrl) {
        result.add(collectionNo);
      }
    }
    return result;
  }

  // _scrollToEndMap
  void _checkScrollToEnd(
    String? channelUrl,
    CollectionEventSource? eventSource,
  ) {
    if (channelUrl != null && eventSource != null) {
      if (SBUMarkAsUnreadManager().isOn()) {
        if (eventSource == CollectionEventSource.localMessagePendingCreated ||
            eventSource == CollectionEventSource.localMessageResendStarted) {
          for (final collectionNo in _getCollectionNoList(channelUrl)) {
            _scrollToEndMap[collectionNo] = true;
          }
        }
      } else {
        if (eventSource == CollectionEventSource.localMessagePendingCreated ||
            eventSource == CollectionEventSource.localMessageResendStarted ||
            eventSource == CollectionEventSource.eventMessageReceived) {
          for (final collectionNo in _getCollectionNoList(channelUrl)) {
            _scrollToEndMap[collectionNo] = true;
          }
        }
      }
    }
  }

  bool isScrollToEnd(int collectionNo) {
    final result = _scrollToEndMap[collectionNo];
    return (result != null && result);
  }

  void resetScrollToEnd(int collectionNo) {
    _scrollToEndMap.remove(collectionNo);
  }

  // Delete message
  bool canDeleteMessage(int collectionNo, BaseMessage message) {
    final editingMessage = getEditingMessage(collectionNo);
    final replyingToMessage = getReplyingToMessage(collectionNo);

    if (editingMessage?.messageId == message.messageId ||
        replyingToMessage?.messageId == message.messageId) {
      return false;
    }
    return true;
  }

  // _editingMessageMap
  void setEditingMessage(int collectionNo, BaseMessage message) {
    _editingMessageMap.remove(collectionNo);
    _replyingToMessageMap.remove(collectionNo);

    _editingMessageMap[collectionNo] = message;
    _refresh();
  }

  BaseMessage? getEditingMessage(int collectionNo) {
    return _editingMessageMap[collectionNo];
  }

  // _replyingToMessageMap
  void setReplyingToMessage(int collectionNo, BaseMessage message) {
    _editingMessageMap.remove(collectionNo);
    _replyingToMessageMap.remove(collectionNo);

    _replyingToMessageMap[collectionNo] = message;
    _refresh();
  }

  BaseMessage? getReplyingToMessage(int collectionNo) {
    return _replyingToMessageMap[collectionNo];
  }

  // resetMessageInputMode
  void resetMessageInputMode(int collectionNo) {
    _editingMessageMap.remove(collectionNo);
    _replyingToMessageMap.remove(collectionNo);
    _refresh();
  }

  // _deletedChannelMap
  void _setDeletedChannel(String channelUrl) {
    for (final collectionNo in _getCollectionNoList(channelUrl)) {
      _deletedChannelMap[collectionNo] = true;
    }
    _refresh();
  }

  bool isDeletedChannel(int collectionNo) {
    final result = _deletedChannelMap[collectionNo];
    return (result != null && result);
  }

  void resetDeletedChannel(int collectionNo) {
    _deletedChannelMap.remove(collectionNo);
  }

  Future<bool> _hasFailedMessages(String channelUrl) async {
    final collectionNoList = _getCollectionNoList(channelUrl);
    if (collectionNoList.isNotEmpty) {
      final failedMessages =
          await _collectionMap[collectionNoList.first]?.getFailedMessages();
      if (failedMessages != null && failedMessages.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  // clearForMarkAsUnread()
  void _clearForMarkAsUnread() {
    if (SBUMarkAsUnreadManager().isOn()) {
      _isBottomOfScreenMap.clear();
      _didMarkAsUnreadMap.clear();
      _checkUnreadBadgeMap.clear();
      _hasSeenNewMessageLineMap.clear();
      _myLastReadMap.clear();
      _freezeMyLastReadMap.clear();
      _enabledNewLineMap.clear();
    }
  }

  // _isBottomOfScreenMap
  void setBottomOfScreen(String channelUrl, bool value) {
    _isBottomOfScreenMap[channelUrl] = value;
  }

  bool isBottomOfScreen(String channelUrl) {
    return _isBottomOfScreenMap[channelUrl] ?? true; // Check
  }

  // _didMarkAsUnreadMap
  void _setDidMarkAsUnread(String channelUrl) {
    if (SBUMarkAsUnreadManager().isOn()) {
      _didMarkAsUnreadMap[channelUrl] = true;
    }
  }

  bool didMarkAsUnread(String channelUrl) {
    if (SBUMarkAsUnreadManager().isOn()) {
      return _didMarkAsUnreadMap[channelUrl] ?? false;
    }
    return false;
  }

  // _checkUnreadBadgeMap
  void setCheckUnreadBadge(String channelUrl) {
    if (SBUMarkAsUnreadManager().isOn()) {
      _checkUnreadBadgeMap[channelUrl] = true;
    }
  }

  bool getCheckUnreadBadge(String channelUrl) {
    if (SBUMarkAsUnreadManager().isOn()) {
      return _checkUnreadBadgeMap[channelUrl] ?? false;
    }
    return false;
  }

  // _hasSeenNewMessageLineMap
  void setHasSeenNewMessageLine(String channelUrl, bool value) {
    if (SBUMarkAsUnreadManager().isOn()) {
      _hasSeenNewMessageLineMap[channelUrl] = value;
    }
  }

  bool hasSeenNewMessageLine(String channelUrl) {
    if (SBUMarkAsUnreadManager().isOn()) {
      return _hasSeenNewMessageLineMap[channelUrl] ?? false;
    }
    return false;
  }

  // _myLastReadMap
  void setMyLastRead(String channelUrl, int myLastRead) {
    if (SBUMarkAsUnreadManager().isOn()) {
      if (_isFreezeMyLastRead(channelUrl)) {
        return;
      }
      _myLastReadMap[channelUrl] = myLastRead;
    }
  }

  int? getMyLastRead(String channelUrl) {
    if (SBUMarkAsUnreadManager().isOn()) {
      return _myLastReadMap[channelUrl];
    }
    return null;
  }

  void setFreezeMyLastRead(String channelUrl, bool value) {
    if (SBUMarkAsUnreadManager().isOn()) {
      _freezeMyLastReadMap[channelUrl] = value;
    }
  }

  bool _isFreezeMyLastRead(String channelUrl) {
    if (SBUMarkAsUnreadManager().isOn()) {
      return _freezeMyLastReadMap[channelUrl] ?? false;
    }
    return false;
  }

  // _enabledNewLineMap
  void enableNewLine(String channelUrl) {
    if (SBUMarkAsUnreadManager().isOn()) {
      _enabledNewLineMap[channelUrl] = true;
    }
  }

  bool isEnabledNewLine(String channelUrl) {
    if (SBUMarkAsUnreadManager().isOn()) {
      return _enabledNewLineMap[channelUrl] ?? false; // Check
    }
    return true;
  }

  // _newMessageCountMap
  void _increaseNewMessageCount(String channelUrl) {
    if (_newMessageCountMap[channelUrl] == null) {
      _newMessageCountMap[channelUrl] = 1;
    } else {
      _newMessageCountMap[channelUrl] = _newMessageCountMap[channelUrl]! + 1;
    }
  }

  void _decreaseNewMessageCount(String channelUrl) {
    if (_newMessageCountMap[channelUrl] != null) {
      final count = _newMessageCountMap[channelUrl]!;
      if (count >= 1) {
        _newMessageCountMap[channelUrl] = count - 1;
      }
    }
  }

  void _resetNewMessageCount(String channelUrl) {
    _newMessageCountMap.remove(channelUrl);
  }

  int getNewMessageCount(String channelUrl) {
    return _newMessageCountMap[channelUrl] ?? 0;
  }

  void _messagesAdded(MessageContext context, GroupChannel channel,
      List<BaseMessage> messages) {
    if (SBUMarkAsUnreadManager().isOn()) {
      if (context.collectionEventSource ==
              CollectionEventSource.localMessagePendingCreated ||
          context.collectionEventSource ==
              CollectionEventSource.localMessageResendStarted) {
        // Nothing to do (Check)
      }

      if (context.collectionEventSource ==
          CollectionEventSource.eventMessageReceived) {
        bool isMyMessageFromMultiDevice = false;
        if (messages.isNotEmpty) {
          if (messages[0].sender?.userId ==
              (SendbirdChat.currentUser?.userId ?? "")) {
            isMyMessageFromMultiDevice = true;
          }
        }

        if (isMyMessageFromMultiDevice) {
          // Nothing to do (Check)
        } else {
          if (isBottomOfScreen(channel.channelUrl)) {
            if (messages.isNotEmpty) {
              checkToMarkAsRead(channel, newMessage: messages[0]);
            }
          } else {
            if (messages[0].isSilent == false) {
              _increaseNewMessageCount(channel.channelUrl);
            }
          }
        }
      }
    } else {
      final collectionNoList = _getCollectionNoList(channel.channelUrl);
      if (collectionNoList.isNotEmpty) {
        runZonedGuarded(() {
          _collectionMap[collectionNoList.first]?.markAsRead(context);
        }, (error, stack) {
          // Check
        });
      }
    }
  }

  void _messagesUpdated(MessageContext context, GroupChannel channel,
      List<BaseMessage> messages) {
    if (context.collectionEventSource ==
        CollectionEventSource.eventMessageSent) {
      for (final message in messages) {
        if (message is MultipleFilesMessage &&
            message.sendingStatus == SendingStatus.succeeded) {
          for (final collectionNo in _getCollectionNoList(channel.channelUrl)) {
            clearUploadedFileIndices(collectionNo, message.requestId);
          }
        }
      }
    }

    if (SBUMarkAsUnreadManager().isOn()) {
      if (context.collectionEventSource ==
          CollectionEventSource.eventMessageSent) {
        if (messages.isNotEmpty) {
          checkToMarkAsRead(channel, newMessage: messages[0]); // Check
        }
      } else if (context.collectionEventSource ==
              CollectionEventSource.localMessageFailed ||
          context.collectionEventSource ==
              CollectionEventSource.localMessageCanceled) {
        // Nothing to do (Check)
      }
    }
  }

  void _messagesDeleted(MessageContext context, GroupChannel channel,
      List<BaseMessage> messages) {
    if (messages.isNotEmpty) {
      final deletedMessageCreatedAt = messages[0].createdAt;

      final collectionNoList = _getCollectionNoList(channel.channelUrl);
      for (final collectionNo in collectionNoList) {
        final collection = getCollection(collectionNo);
        if (collection != null) {
          final newMessageCount = getNewMessageCount(channel.channelUrl);
          if (newMessageCount > 0 &&
              newMessageCount - 1 < collection.messageList.length) {
            final firstNewMessage = collection.messageList[newMessageCount - 1];

            // Check
            if (deletedMessageCreatedAt >= firstNewMessage.createdAt) {
              _decreaseNewMessageCount(channel.channelUrl);
            }
          }
          break;
        }
      }
    }
  }

  void _channelUpdated(GroupChannelContext context, GroupChannel channel) {
    if (SBUMarkAsUnreadManager().isOn()) {
      final isUserMarkedRead = context.collectionEventSource ==
          CollectionEventSource.eventUserMarkedRead;
      final isUserMarkedUnread = context.collectionEventSource ==
          CollectionEventSource.eventUserMarkedUnread;
      if (isUserMarkedRead || isUserMarkedUnread) {
        if (isUserMarkedUnread) {
          enableNewLine(channel.channelUrl); // Check
        }

        final userIds = context.eventDetail as List<String>;
        bool myEvent = (userIds.isNotEmpty &&
            userIds[0] == (SendbirdChat.currentUser?.userId ?? ""));

        if (myEvent) {
          if (isUserMarkedRead) {
            if (channel.myLastRead == (channel.lastMessage?.createdAt ?? 0)) {
              _resetNewMessageCount(channel.channelUrl);
              setMyLastRead(channel.channelUrl, channel.myLastRead);
            }
          } else if (isUserMarkedUnread) {
            if (channel.myLastRead < (channel.lastMessage?.createdAt ?? 0)) {
              _setDidMarkAsUnread(channel.channelUrl);
              setCheckUnreadBadge(channel.channelUrl);
              setFreezeMyLastRead(channel.channelUrl, false);
              setMyLastRead(channel.channelUrl, channel.myLastRead);
              setFreezeMyLastRead(channel.channelUrl, true);
            }
          }
        }
      }
    }
  }

  void checkToMarkAsRead(
    GroupChannel channel, {
    BaseMessage? newMessage,
  }) {
    if (SBUMarkAsUnreadManager().isOn()) {
      if (newMessage != null) {
        setMyLastRead(channel.channelUrl, SendbirdChat.maxInt); // Check
      }

      if (newMessage?.isSilent ?? false) {
        return; // Check
      }

      if (_canMarkAsRead(channel, newMessage: newMessage)) {
        runZonedGuarded(() async {
          channel.markAsRead(); // No await
        }, (error, stack) {
          // Check
        });
      } else if (newMessage == null) {
        _resetNewMessageCount(channel.channelUrl); // Check
      }
    }
  }

  bool _canMarkAsRead(
    GroupChannel channel, {
    BaseMessage? newMessage,
  }) {
    final collectionNoList = _getCollectionNoList(channel.channelUrl);
    for (final collectionNo in collectionNoList) {
      final collection = _collectionMap[collectionNo];
      if (collection != null) {
        final newMessageCount = getNewMessageCount(channel.channelUrl);
        final hasSeenNewLine = hasSeenNewMessageLine(channel.channelUrl);

        if (newMessageCount > 0 &&
            newMessageCount < collection.messageList.length) {
          if (channel.myLastRead ==
              collection.messageList[newMessageCount].createdAt) {
            return true;
          } else if (channel.myLastRead <
                  collection.messageList[newMessageCount].createdAt &&
              hasSeenNewLine == false &&
              newMessage == null) {
            return false; // Sent by me
          }
        } else if (newMessageCount == 0 && collection.messageList.length >= 2) {
          final prevMessage = collection.messageList[1];
          if (prevMessage.isSilent == false) {
            if (channel.myLastRead == prevMessage.createdAt) {
              return true;
            } else if (channel.myLastRead < prevMessage.createdAt &&
                hasSeenNewLine == false) {
              return false;
            }
          }
        }
        break;
      }
    }
    return true;
  }
}

class _MyMessageCollectionHandler extends MessageCollectionHandler {
  final SBUMessageCollectionProvider _provider;
  final String _channelUrl;

  _MyMessageCollectionHandler(this._provider, this._channelUrl);

  @override
  void onMessagesAdded(MessageContext context, GroupChannel channel,
      List<BaseMessage> messages) async {
    _provider._messagesAdded(context, channel, messages);

    //+ Anti-flicker
    if (context.collectionEventSource ==
            CollectionEventSource.messageCacheInitialize &&
        context.sendingStatus == SendingStatus.succeeded) {
      if (await _provider._hasFailedMessages(channel.channelUrl)) {
        return;
      }
    }
    //- Anti-flicker

    _provider._refresh(channel.channelUrl, context.collectionEventSource);
  }

  @override
  void onMessagesUpdated(MessageContext context, GroupChannel channel,
      List<BaseMessage> messages) {
    _provider._messagesUpdated(context, channel, messages);
    _provider._refresh(channel.channelUrl, context.collectionEventSource);
  }

  @override
  void onMessagesDeleted(MessageContext context, GroupChannel channel,
      List<BaseMessage> messages) {
    _provider._messagesDeleted(context, channel, messages);
    _provider._refresh(channel.channelUrl, context.collectionEventSource);
  }

  @override
  void onChannelUpdated(GroupChannelContext context, GroupChannel channel) {
    _provider._channelUpdated(context, channel);
    _provider._refresh(channel.channelUrl, context.collectionEventSource);
  }

  @override
  void onChannelDeleted(GroupChannelContext context, String deletedChannelUrl) {
    _provider._setDeletedChannel(deletedChannelUrl);
  }

  @override
  void onHugeGapDetected() {
    _provider._restart(_channelUrl);
  }
}

extension MultipleFilesUploadTracking on SBUMessageCollectionProvider {
  void notifyFileUploadCompleted(
      int collectionNo, String requestId, int index) {
    final key = '${collectionNo}_$requestId';
    _uploadedFileIndicesMap[key] ??= {};
    _uploadedFileIndicesMap[key]!.add(index);
    _refresh();
  }

  Set<int> getUploadedFileIndices(int collectionNo, String? requestId) {
    if (requestId == null) return {};
    final key = '${collectionNo}_$requestId';
    return _uploadedFileIndicesMap[key] ?? {};
  }

  void clearUploadedFileIndices(int collectionNo, String? requestId) {
    if (requestId == null) return;
    final key = '${collectionNo}_$requestId';
    _uploadedFileIndicesMap.remove(key);
  }
}

extension TypingIndicatorBubbleTracking on SBUMessageCollectionProvider {
  void notifyTypingIndicatorBubble(GroupChannel channel) {
    _refresh(channel.channelUrl);
  }
}

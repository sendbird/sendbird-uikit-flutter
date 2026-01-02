// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_bottom_sheet_menu_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_bottom_sheet_user_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_dialog_menu_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_file_icon_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_icon_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_reaction_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_component.dart';
import 'package:sendbird_uikit/src/internal/provider/sbu_message_collection_provider.dart';
import 'package:sendbird_uikit/src/internal/resource/sbu_text_styles.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_mark_as_unread_manager.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_ogtag_manager.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_reaction_manager.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_reply_manager.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_thumbnail_manager.dart';

class SBUMessageListItemComponent extends SBUStatefulComponent {
  final int messageCollectionNo;
  final List<BaseMessage> messageList;
  final int messageIndex;
  final void Function(GroupChannel)? on1On1ChannelCreated;
  final void Function(GroupChannel, BaseMessage)? onListItemClicked;
  final void Function(GroupChannel, BaseMessage, int index)?
      onListItemWithIndexClicked;
  final void Function(BaseMessage)? onParentMessageClicked;

  const SBUMessageListItemComponent({
    required this.messageCollectionNo,
    required this.messageList,
    required this.messageIndex,
    this.on1On1ChannelCreated,
    this.onListItemClicked,
    this.onListItemWithIndexClicked,
    this.onParentMessageClicked,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => SBUMessageListItemComponentState();
}

class SBUMessageListItemComponentState
    extends State<SBUMessageListItemComponent> {
  final double imageWidth = 240;
  final double imageHeight = 160;

  late bool isReactionAvailable;
  late bool isOGTagEnabled;

  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.watch<SBUThemeProvider>().isLight();
    final strings = context.watch<SBUStringProvider>().strings;

    final collectionProvider = SBUMessageCollectionProvider();
    final collection =
        collectionProvider.getCollection(widget.messageCollectionNo)!; // Check

    final messageList = widget.messageList;
    final messageIndex = widget.messageIndex;
    final message = messageList[messageIndex];

    final isSameDayAtPreviousMessage =
        _isSameDayAtPreviousMessage(collection, messageList, messageIndex);

    final hasNewMessageLine = SBUMarkAsUnreadManager().hasNewMessageLine(
      collection: collection,
      messageList: messageList,
      messageIndex: messageIndex,
    );

    isReactionAvailable =
        SBUReactionManager().isReactionAvailable(collection.channel, message);

    final isMyMessage = _isMyMessage(message);

    Widget? messageWidget;
    if (message.messageType == MessageType.admin) {
      messageWidget = _adminMessageWidget(
        collection,
        messageList,
        messageIndex,
        message as AdminMessage,
        isLightTheme,
        strings,
      );
    } else if (message.messageType == MessageType.user) {
      if (isMyMessage) {
        messageWidget = _myUserMessageWidget(
          collection,
          messageList,
          messageIndex,
          message as UserMessage,
          isLightTheme,
          strings,
        );
      } else {
        messageWidget = _otherUserMessageWidget(
          collection,
          messageList,
          messageIndex,
          message as UserMessage,
          isLightTheme,
          strings,
        );
      }
    } else if (message.messageType == MessageType.file) {
      if (isMyMessage) {
        messageWidget = _myFileMessageWidget(
          collection,
          messageList,
          messageIndex,
          message,
          isLightTheme,
          strings,
        );
      } else {
        messageWidget = _otherFileMessageWidget(
          collection,
          messageList,
          messageIndex,
          message,
          isLightTheme,
          strings,
        );
      }
    }

    Widget messageWidgetWithDay = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isSameDayAtPreviousMessage == false)
          Container(
            width: double.maxFinite,
            alignment: AlignmentDirectional.center,
            padding: EdgeInsets.only(
                top: messageIndex == messageList.length - 1 ? 16 : 8,
                bottom: 8),
            child: Container(
              padding:
                  const EdgeInsets.only(left: 10, top: 4, right: 10, bottom: 4),
              decoration: BoxDecoration(
                color: isLightTheme
                    ? SBUColors.overlayLight
                    : SBUColors.overlayDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SBUTextComponent(
                text: DateFormat('EEE, MMM dd').format(
                    DateTime.fromMillisecondsSinceEpoch(message.createdAt)),
                textType: SBUTextType.caption1,
                textColorType: SBUTextColorType.messageDate,
              ),
            ),
          ),
        if (hasNewMessageLine) _newMessageLineWidget(isLightTheme, strings),
        if (messageWidget != null) messageWidget,
      ],
    );

    return messageWidget != null ? messageWidgetWithDay : Container();
  }

  Widget _newMessageLineWidget(bool isLightTheme, SBUStrings strings) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      // height: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 1,
              color:
                  isLightTheme ? SBUColors.primaryMain : SBUColors.primaryLight,
            ),
          ),
          const SizedBox(width: 4),
          SBUTextComponent(
            text: strings.newMessages,
            textType: SBUTextType.caption3,
            textColorType: SBUTextColorType.primary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 1,
              color:
                  isLightTheme ? SBUColors.primaryMain : SBUColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _adminMessageWidget(
    MessageCollection collection,
    List<BaseMessage> messageList,
    int messageIndex,
    AdminMessage message,
    bool isLightTheme,
    SBUStrings strings,
  ) {
    return Container(
      width: double.maxFinite,
      alignment: AlignmentDirectional.center,
      padding: EdgeInsets.only(
          left: 30, top: 8, right: 30, bottom: (messageIndex == 0) ? 16 : 8),
      child: SBUTextComponent(
        text: message.message,
        textType: SBUTextType.caption2,
        textColorType: SBUTextColorType.text02,
        textOverflowType: null,
        maxLines: null,
      ),
    );
  }

  Widget? _otherUserMessageWidget(
    MessageCollection collection,
    List<BaseMessage> messageList,
    int messageIndex,
    UserMessage message,
    bool isLightTheme,
    SBUStrings strings,
  ) {
    final isSameMinuteAtPreviousMessage =
        _isSameMinuteAtPreviousMessage(messageList, messageIndex);
    final isSameMinuteAtNextMessage =
        _isSameMinuteAtNextMessage(messageList, messageIndex);
    final timeString = _messageCreatedAtString(message);

    return _messageItemPadding(
      message: message,
      messageIndex: messageIndex,
      isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
      isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
      child: _replyToChannel(
        collection: collection,
        message: message,
        isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
        isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
        timeString: timeString,
        isLightTheme: isLightTheme,
        strings: strings,
        isMyMessage: false,
        child: _otherUserMessageItemWidget(
          collection: collection,
          message: message,
          isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
          isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
          timeString: timeString,
          isLightTheme: isLightTheme,
          strings: strings,
        ),
      ),
    );
  }

  Widget? _myUserMessageWidget(
    MessageCollection collection,
    List<BaseMessage> messageList,
    int messageIndex,
    UserMessage message,
    bool isLightTheme,
    SBUStrings strings,
  ) {
    final isSameMinuteAtPreviousMessage =
        _isSameMinuteAtPreviousMessage(messageList, messageIndex);
    final isSameMinuteAtNextMessage =
        _isSameMinuteAtNextMessage(messageList, messageIndex);
    final timeString = _messageCreatedAtString(message);

    return _messageItemPadding(
      message: message,
      messageIndex: messageIndex,
      isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
      isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
      child: _replyToChannel(
        collection: collection,
        message: message,
        isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
        isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
        timeString: timeString,
        isLightTheme: isLightTheme,
        strings: strings,
        isMyMessage: true,
        child: _myUserMessageItemWidget(
          collection: collection,
          message: message,
          isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
          isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
          timeString: timeString,
          isLightTheme: isLightTheme,
          strings: strings,
        ),
      ),
    );
  }

  Widget? _otherFileMessageWidget(
    MessageCollection collection,
    List<BaseMessage> messageList,
    int messageIndex,
    BaseMessage message,
    bool isLightTheme,
    SBUStrings strings,
  ) {
    final isSameMinuteAtPreviousMessage =
        _isSameMinuteAtPreviousMessage(messageList, messageIndex);
    final isSameMinuteAtNextMessage =
        _isSameMinuteAtNextMessage(messageList, messageIndex);
    final timeString = _messageCreatedAtString(message);

    return _messageItemPadding(
      message: message,
      messageIndex: messageIndex,
      isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
      isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
      child: _replyToChannel(
        collection: collection,
        message: message,
        isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
        isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
        timeString: timeString,
        isLightTheme: isLightTheme,
        strings: strings,
        isMyMessage: false,
        child: message is MultipleFilesMessage
            ? _otherMultipleFilesMessageItemWidget(
                collection: collection,
                message: message,
                isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
                isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
                timeString: timeString,
                isLightTheme: isLightTheme,
                strings: strings,
              )
            : _otherFileMessageItemWidget(
                collection: collection,
                message: message as FileMessage,
                isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
                isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
                timeString: timeString,
                isLightTheme: isLightTheme,
                strings: strings,
              ),
      ),
    );
  }

  Widget? _myFileMessageWidget(
    MessageCollection collection,
    List<BaseMessage> messageList,
    int messageIndex,
    BaseMessage message,
    bool isLightTheme,
    SBUStrings strings,
  ) {
    final isSameMinuteAtPreviousMessage =
        _isSameMinuteAtPreviousMessage(messageList, messageIndex);
    final isSameMinuteAtNextMessage =
        _isSameMinuteAtNextMessage(messageList, messageIndex);
    final timeString = _messageCreatedAtString(message);

    return _messageItemPadding(
      message: message,
      messageIndex: messageIndex,
      isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
      isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
      child: _replyToChannel(
        collection: collection,
        message: message,
        isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
        isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
        timeString: timeString,
        isLightTheme: isLightTheme,
        strings: strings,
        isMyMessage: true,
        child: message is MultipleFilesMessage
            ? _myMultipleFilesMessageItemWidget(
                collection: collection,
                message: message,
                isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
                isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
                timeString: timeString,
                isLightTheme: isLightTheme,
                strings: strings,
              )
            : _myFileMessageItemWidget(
                collection: collection,
                message: message as FileMessage,
                isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
                isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
                timeString: timeString,
                isLightTheme: isLightTheme,
                strings: strings,
              ),
      ),
    );
  }

  bool _isMyMessage(BaseMessage message) {
    final senderId = message.sender?.userId;
    final isMyMessage =
        (senderId != null && senderId == SendbirdChat.currentUser?.userId) ||
            (senderId == null) ||
            (message.sendingStatus == SendingStatus.failed);
    return isMyMessage;
  }

  bool _isSameDayAtPreviousMessage(
    MessageCollection collection,
    List<BaseMessage> messageList,
    int messageIndex,
  ) {
    final message = messageList[messageIndex];

    if (messageIndex == messageList.length - 1) {
      if (collection.isLoading) {
        return true; // Do not draw date.
      }

      // reverse
      if (collection.hasPrevious) {
        return true; // Do not draw date.
      }
    }

    // reverse
    if (messageIndex + 1 < messageList.length) {
      final prevMessage = messageList[messageIndex + 1];
      return _isSameDay(message.createdAt, prevMessage.createdAt);
    }
    return false;
  }

  bool _isSameDay(int ts1, int ts2) {
    final dt1 = DateTime.fromMillisecondsSinceEpoch(ts1);
    final dt2 = DateTime.fromMillisecondsSinceEpoch(ts2);

    if (dt1.year == dt2.year && dt1.month == dt2.month && dt1.day == dt2.day) {
      return true;
    }
    return false;
  }

  bool _isSameMinuteAtPreviousMessage(
    List<BaseMessage> messageList,
    int messageIndex,
  ) {
    final message = messageList[messageIndex];

    // reverse
    if (messageIndex + 1 < messageList.length) {
      final prevMessage = messageList[messageIndex + 1];
      return _isSameMinute(message.createdAt, prevMessage.createdAt) &&
          _isSameSender(message, prevMessage);
    }
    return false;
  }

  bool _isSameMinuteAtNextMessage(
    List<BaseMessage> messageList,
    int messageIndex,
  ) {
    final message = messageList[messageIndex];

    // reverse
    if (messageIndex - 1 >= 0) {
      final nextMessage = messageList[messageIndex - 1];
      return _isSameMinute(message.createdAt, nextMessage.createdAt) &&
          _isSameSender(message, nextMessage);
    }
    return false;
  }

  bool _isSameMinute(int ts1, int ts2) {
    final dt1 = DateTime.fromMillisecondsSinceEpoch(ts1);
    final dt2 = DateTime.fromMillisecondsSinceEpoch(ts2);

    if (dt1.year == dt2.year &&
        dt1.month == dt2.month &&
        dt1.day == dt2.day &&
        dt1.hour == dt2.hour &&
        dt1.minute == dt2.minute) {
      return true;
    }
    return false;
  }

  bool _isSameSender(BaseMessage m1, BaseMessage m2) {
    return m1.sender?.userId == m2.sender?.userId;
  }

  Widget? _getThumbnailWidget({
    required bool isSucceededMessage,
    required String? requestId,
    required int messageId,
    required int? multipleFileIndex,
    required List<Thumbnail>? thumbnails,
    required String? mimeType,
    required String secureUrl,
    required String? filePath,
    required bool isLightTheme,
    required bool isParentMessage,
  }) {
    final fileType = widget.getFileType(mimeType);

    if (fileType == SBUFileType.image || fileType == SBUFileType.video) {
      Widget? thumbnailWidget = SBUThumbnailManager().getThumbnailWidget(
        isSucceededMessage: isSucceededMessage,
        requestId: requestId,
        messageId: messageId,
        multipleFileIndex: multipleFileIndex,
        thumbnails: thumbnails,
        mimeType: mimeType,
        secureUrl: secureUrl,
        filePath: filePath,
        fileType: fileType,
        isLightTheme: isLightTheme,
        addGifIcon: true,
        isParentMessage: isParentMessage,
      );

      if (thumbnailWidget != null) {
        if (fileType == SBUFileType.image) {
          return thumbnailWidget;
        } else if (fileType == SBUFileType.video) {
          final size =
              isParentMessage || multipleFileIndex != null ? 31.2 : 48.0;
          final iconSize =
              isParentMessage || multipleFileIndex != null ? 18.2 : 28.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: imageWidth, // Check
                height: imageHeight,
                child: thumbnailWidget,
              ),
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: SBUColors.darkThemeTextHighEmphasis,
                  borderRadius: BorderRadius.circular(size),
                ),
              ),
              SBUIconComponent(
                iconSize: iconSize,
                iconData: SBUIcons.play,
                iconColor: SBUColors.lightThemeTextMidEmphasis,
              ),
            ],
          );
        }
      }
    }
    return null;
  }

  String _messageCreatedAtString(BaseMessage message) {
    return DateFormat('h:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(message.createdAt));
  }

  Widget _fileWidget({
    required String? fileName,
    required bool isLightTheme,
    required bool isMyMessage,
    required int? multipleFileIndex,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SBUFileIconComponent(
            size: 28,
            backgroundColor:
                isLightTheme ? SBUColors.background50 : SBUColors.background600,
            iconSize: 24,
            iconData: SBUIcons.fileDocument,
            iconColor:
                isLightTheme ? SBUColors.primaryMain : SBUColors.primaryLight,
          ),
        ),
        Flexible(
          child: SBUTextComponent(
            text: fileName ?? '',
            textType: SBUTextType.body3,
            textColorType: isMyMessage
                ? SBUTextColorType.message
                : SBUTextColorType.text01,
            // SBUTextOverflowType.ellipsisMiddle
            textOverflowType: null,
            maxLines: null, // 1
          ),
        ),
      ],
    );
  }

  Widget _otherUserMessageItemWidget({
    required MessageCollection collection,
    required UserMessage message,
    required bool isSameMinuteAtPreviousMessage,
    required bool isSameMinuteAtNextMessage,
    required String timeString,
    required bool isLightTheme,
    required SBUStrings strings,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 2),
          child: (isSameMinuteAtNextMessage == false)
              ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      if (message.sender != null) {
                        widget.unfocus();
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          builder: (context) {
                            return SBUBottomSheetUserComponent(
                              user: message.sender!,
                              on1On1ChannelCreated: widget.on1On1ChannelCreated,
                            );
                          },
                        );
                      }
                    },
                    child: widget.getAvatarComponent(
                      isLightTheme: isLightTheme,
                      size: 26,
                      user: message.sender,
                    ),
                  ),
                )
              : const SizedBox(width: 26),
        ),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSameMinuteAtPreviousMessage == false)
                if (message.isReplyToChannel == false &&
                    message.parentMessageId == null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: SBUTextComponent(
                      text: widget.getNickname(message.sender, strings),
                      textType: SBUTextType.caption1,
                      textColorType: SBUTextColorType.text02,
                    ),
                  ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    if (widget.onListItemClicked != null) {
                      widget.onListItemClicked!(collection.channel, message);
                    }
                  },
                  onLongPress: () async {
                    widget.unfocus();
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      builder: (context) {
                        return SBUBottomSheetMenuComponent(
                          channel: collection.channel,
                          message: message,
                          iconNames: [
                            SBUIcons.copy,
                            if (SBUMarkAsUnreadManager().isOn())
                              SBUIcons.markAsUnread,
                            if (SBUReplyManager()
                                .isQuoteReplyAvailable(collection.channel))
                              SBUIcons.reply,
                          ],
                          buttonNames: [
                            strings.copy,
                            if (SBUMarkAsUnreadManager().isOn())
                              strings.markAsUnread,
                            if (SBUReplyManager()
                                .isQuoteReplyAvailable(collection.channel))
                              strings.reply,
                          ],
                          onButtonClicked: (buttonName) async {
                            if (buttonName == strings.copy) {
                              await widget.copyTextToClipboard(
                                  message.message, strings);
                            } else if (buttonName == strings.markAsUnread) {
                              await _markAsUnread(collection.channel, message);
                            } else if (buttonName == strings.reply) {
                              SBUMessageCollectionProvider()
                                  .setReplyingToMessage(
                                widget.messageCollectionNo,
                                message,
                              );
                            }
                          },
                          disabledNames:
                              message.isReplyToChannel ? [strings.reply] : null,
                        );
                      },
                    );
                  },
                  child: SBUOGTagManager().getOGTagMessageItemWidget(
                        message: message,
                        collection: collection,
                        isLightTheme: isLightTheme,
                        strings: strings,
                        isMyMessage: false,
                      ) ??
                      Container(
                        padding: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: isLightTheme
                              ? SBUColors.background100
                              : SBUColors.background400,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 12, right: 12, bottom: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: SBUTextComponent(
                                      text: message.message,
                                      textType: SBUTextType.body3,
                                      textColorType: SBUTextColorType.text01,
                                      textOverflowType: null,
                                      maxLines: null,
                                    ),
                                  ),
                                  if (message.updatedAt >= message.createdAt)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: SBUTextComponent(
                                        text: strings.edited,
                                        textType: SBUTextType.body3,
                                        textColorType: SBUTextColorType.text02,
                                        textOverflowType: null,
                                        maxLines: null,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SBUReactionComponent(
                              channel: collection.channel,
                              message: message,
                            ),
                          ],
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 16,
          alignment: AlignmentDirectional.center,
          padding: const EdgeInsets.only(left: 4),
          child: SBUTextComponent(
            text: timeString,
            textType: SBUTextType.caption4,
            textColorType: SBUTextColorType.text03,
            transparent: isSameMinuteAtNextMessage,
          ),
        ),
      ],
    );
  }

  Widget _myUserMessageItemWidget({
    required MessageCollection collection,
    required UserMessage message,
    required bool isSameMinuteAtPreviousMessage,
    required bool isSameMinuteAtNextMessage,
    required String timeString,
    required bool isLightTheme,
    required SBUStrings strings,
  }) {
    final readStatusIcon =
        widget.getReadStatusIcon(collection.channel, message, isLightTheme);
    final isDisabled = widget.isDisabled(collection.channel);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (message.sendingStatus == SendingStatus.succeeded &&
            isSameMinuteAtNextMessage)
          Container(
            height: 16,
            alignment: AlignmentDirectional.center,
            padding: const EdgeInsets.only(right: 4),
            child: SBUTextComponent(
              text: timeString,
              textType: SBUTextType.caption4,
              textColorType: SBUTextColorType.text03,
              transparent: isSameMinuteAtNextMessage,
            ),
          ),
        if (readStatusIcon != null)
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            child: readStatusIcon,
          ),
        if (message.sendingStatus == SendingStatus.pending)
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  color: isLightTheme
                      ? SBUColors.primaryMain
                      : SBUColors.primaryLight,
                  strokeWidth: 1.4),
            ),
          ),
        if (message.sendingStatus == SendingStatus.failed)
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            child: SBUIconComponent(
              iconSize: 16,
              iconData: SBUIcons.error,
              iconColor:
                  isLightTheme ? SBUColors.errorMain : SBUColors.errorLight,
            ),
          ),
        if (message.sendingStatus == SendingStatus.succeeded &&
            isSameMinuteAtNextMessage == false)
          Container(
            height: 16,
            alignment: AlignmentDirectional.center,
            padding: const EdgeInsets.only(right: 4),
            child: SBUTextComponent(
              text: timeString,
              textType: SBUTextType.caption4,
              textColorType: SBUTextColorType.text03,
            ),
          ),
        Flexible(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                if (widget.onListItemClicked != null) {
                  widget.onListItemClicked!(collection.channel, message);
                }
              },
              onLongPress: () async {
                if (message.sendingStatus == SendingStatus.succeeded) {
                  widget.unfocus();
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    builder: (context) {
                      return SBUBottomSheetMenuComponent(
                        channel: collection.channel,
                        message: message,
                        iconNames: [
                          SBUIcons.copy,
                          if (!isDisabled) SBUIcons.edit,
                          if (SBUMarkAsUnreadManager().isOn())
                            SBUIcons.markAsUnread,
                          if (!isDisabled)
                            if (SBUMessageCollectionProvider().canDeleteMessage(
                                widget.messageCollectionNo, message))
                              SBUIcons.delete,
                          if (SBUReplyManager()
                              .isQuoteReplyAvailable(collection.channel))
                            SBUIcons.reply,
                        ],
                        buttonNames: [
                          strings.copy,
                          if (!isDisabled) strings.edit,
                          if (SBUMarkAsUnreadManager().isOn())
                            strings.markAsUnread,
                          if (!isDisabled)
                            if (SBUMessageCollectionProvider().canDeleteMessage(
                                widget.messageCollectionNo, message))
                              strings.delete,
                          if (SBUReplyManager()
                              .isQuoteReplyAvailable(collection.channel))
                            strings.reply,
                        ],
                        onButtonClicked: (buttonName) async {
                          if (buttonName == strings.copy) {
                            await widget.copyTextToClipboard(
                                message.message, strings);
                          } else if (buttonName == strings.edit) {
                            SBUMessageCollectionProvider().setEditingMessage(
                                widget.messageCollectionNo, message);
                          } else if (buttonName == strings.markAsUnread) {
                            await _markAsUnread(collection.channel, message);
                          } else if (buttonName == strings.delete) {
                            await showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) => SBUDialogMenuComponent(
                                title: strings.deleteMessage,
                                buttonNames: [
                                  strings.cancel,
                                  strings.delete,
                                ],
                                onButtonClicked: (buttonName) async {
                                  if (buttonName == strings.cancel) {
                                    // Cancel
                                  } else if (buttonName == strings.delete) {
                                    runZonedGuarded(() async {
                                      await collection.channel
                                          .deleteMessage(message.messageId);
                                    }, (error, stack) {
                                      // TODO: Check error
                                    });
                                  }
                                },
                                isYesOrNo: true,
                              ),
                            );
                          } else if (buttonName == strings.reply) {
                            SBUMessageCollectionProvider().setReplyingToMessage(
                              widget.messageCollectionNo,
                              message,
                            );
                          }
                        },
                        disabledNames: [
                          if (message.isReplyToChannel) strings.reply,
                          if (message.threadInfo != null &&
                              message.threadInfo!.replyCount > 0)
                            strings.delete,
                        ],
                      );
                    },
                  );
                } else if (message.sendingStatus == SendingStatus.failed) {
                  widget.unfocus();
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    builder: (context) {
                      return SBUBottomSheetMenuComponent(
                        buttonNames: [
                          if (!isDisabled) strings.retry,
                          strings.remove,
                        ],
                        onButtonClicked: (buttonName) async {
                          if (buttonName == strings.retry) {
                            try {
                              collection.channel.resendUserMessage(message);
                            } catch (e) {
                              // TODO: Check error
                            }
                          } else if (buttonName == strings.remove) {
                            await collection
                                .removeFailedMessages(messages: [message]);
                          }
                        },
                        errorColorIndex: 1,
                      );
                    },
                  );
                }
              },
              child: Column(
                children: [
                  SBUOGTagManager().getOGTagMessageItemWidget(
                        message: message,
                        collection: collection,
                        isLightTheme: isLightTheme,
                        strings: strings,
                        isMyMessage: true,
                      ) ??
                      Container(
                        padding: const EdgeInsets.only(top: 7),
                        decoration: BoxDecoration(
                          color: isLightTheme
                              ? SBUColors.primaryMain
                              : SBUColors.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 12, right: 12, bottom: 7),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: SBUTextComponent(
                                      text: message.message,
                                      textType: SBUTextType.body3,
                                      textColorType: SBUTextColorType.message,
                                      textOverflowType: null,
                                      maxLines: null,
                                    ),
                                  ),
                                  if (message.updatedAt >= message.createdAt)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: SBUTextComponent(
                                        text: strings.edited,
                                        textType: SBUTextType.body3,
                                        textColorType:
                                            SBUTextColorType.messageEdited,
                                        textOverflowType: null,
                                        maxLines: null,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SBUReactionComponent(
                              channel: collection.channel,
                              message: message,
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _otherFileMessageItemWidget({
    required MessageCollection collection,
    required FileMessage message,
    required bool isSameMinuteAtPreviousMessage,
    required bool isSameMinuteAtNextMessage,
    required String timeString,
    required bool isLightTheme,
    required SBUStrings strings,
  }) {
    final thumbnailWidget = _getThumbnailWidget(
      isSucceededMessage: message.sendingStatus == SendingStatus.succeeded,
      requestId: message.requestId,
      messageId: message.messageId,
      multipleFileIndex: null,
      thumbnails: message.thumbnails,
      mimeType: message.type,
      secureUrl: message.secureUrl,
      filePath: message.file?.path,
      isLightTheme: isLightTheme,
      isParentMessage: false,
    );

    final fileWidget = _fileWidget(
      fileName: message.name,
      isLightTheme: isLightTheme,
      isMyMessage: false,
      multipleFileIndex: null,
    );

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 2),
          child: (isSameMinuteAtNextMessage == false)
              ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      if (message.sender != null) {
                        widget.unfocus();
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          builder: (context) {
                            return SBUBottomSheetUserComponent(
                              user: message.sender!,
                              on1On1ChannelCreated: widget.on1On1ChannelCreated,
                            );
                          },
                        );
                      }
                    },
                    child: widget.getAvatarComponent(
                      isLightTheme: isLightTheme,
                      size: 26,
                      user: message.sender,
                    ),
                  ),
                )
              : const SizedBox(width: 26),
        ),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSameMinuteAtPreviousMessage == false)
                if (message.isReplyToChannel == false &&
                    message.parentMessageId == null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: SBUTextComponent(
                      text: widget.getNickname(message.sender, strings),
                      textType: SBUTextType.caption1,
                      textColorType: SBUTextColorType.text02,
                    ),
                  ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    if (widget.onListItemClicked != null) {
                      widget.onListItemClicked!(collection.channel, message);
                    }
                  },
                  onLongPress: () async {
                    if (!SBUReactionManager()
                            .isReactionAvailable(collection.channel, message) &&
                        SendbirdUIKit().downloadFile == null &&
                        !SBUReplyManager()
                            .isQuoteReplyAvailable(collection.channel) &&
                        !SBUMarkAsUnreadManager().isOn()) {
                      return;
                    }

                    widget.unfocus();
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      builder: (context) {
                        return SBUBottomSheetMenuComponent(
                          channel: collection.channel,
                          message: message,
                          iconNames: [
                            if (SendbirdUIKit().downloadFile != null)
                              SBUIcons.download,
                            if (SBUMarkAsUnreadManager().isOn())
                              SBUIcons.markAsUnread,
                            if (SBUReplyManager()
                                .isQuoteReplyAvailable(collection.channel))
                              SBUIcons.reply,
                          ],
                          buttonNames: [
                            if (SendbirdUIKit().downloadFile != null)
                              strings.save,
                            if (SBUMarkAsUnreadManager().isOn())
                              strings.markAsUnread,
                            if (SBUReplyManager()
                                .isQuoteReplyAvailable(collection.channel))
                              strings.reply,
                          ],
                          onButtonClicked: (buttonName) async {
                            if (buttonName == strings.save) {
                              SendbirdUIKit().downloadFile!(
                                message.secureUrl,
                                message.name,
                                () => widget.showToast(
                                  isLightTheme: isLightTheme,
                                  text: strings.fileSaved,
                                ),
                              );
                            } else if (buttonName == strings.markAsUnread) {
                              await _markAsUnread(collection.channel, message);
                            } else if (buttonName == strings.reply) {
                              SBUMessageCollectionProvider()
                                  .setReplyingToMessage(
                                widget.messageCollectionNo,
                                message,
                              );
                            }
                          },
                          disabledNames:
                              message.isReplyToChannel ? [strings.reply] : null,
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: thumbnailWidget != null
                        ? EdgeInsets.zero
                        : const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: thumbnailWidget != null
                          ? isLightTheme
                              ? SBUColors.background100
                              : SBUColors.background400
                          : isLightTheme
                              ? SBUColors.background100
                              : SBUColors.background400,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: thumbnailWidget != null
                        ? Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  width: imageWidth, // Check
                                  height: imageHeight,
                                  child: thumbnailWidget,
                                ),
                              ),
                              SBUReactionComponent(
                                channel: collection.channel,
                                message: message,
                                width: imageWidth, // Check
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 12, right: 12, bottom: 8),
                                child: fileWidget,
                              ),
                              SBUReactionComponent(
                                channel: collection.channel,
                                message: message,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 16,
          alignment: AlignmentDirectional.center,
          padding: const EdgeInsets.only(left: 4),
          child: SBUTextComponent(
            text: timeString,
            textType: SBUTextType.caption4,
            textColorType: SBUTextColorType.text03,
            transparent: isSameMinuteAtNextMessage,
          ),
        ),
      ],
    );
  }

  Widget _otherMultipleFilesMessageItemWidget({
    required MessageCollection collection,
    required MultipleFilesMessage message,
    required bool isSameMinuteAtPreviousMessage,
    required bool isSameMinuteAtNextMessage,
    required String timeString,
    required bool isLightTheme,
    required SBUStrings strings,
  }) {
    List<Widget?> thumbnailWidgets = [];
    List<Widget?> fileWidgets = [];

    for (int i = 0; i < message.files.length; i++) {
      thumbnailWidgets.add(_getThumbnailWidget(
        isSucceededMessage: message.sendingStatus == SendingStatus.succeeded,
        requestId: message.requestId,
        messageId: message.messageId,
        multipleFileIndex: i,
        thumbnails: message.files[i].thumbnails,
        mimeType: message.files[i].type,
        secureUrl: message.files[i].secureUrl,
        filePath: message.files[i].file?.path,
        isLightTheme: isLightTheme,
        isParentMessage: false,
      ));

      fileWidgets.add(_fileWidget(
        fileName: message.files[i].name,
        isLightTheme: isLightTheme,
        isMyMessage: true,
        multipleFileIndex: i,
      ));
    }

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 2),
          child: (isSameMinuteAtNextMessage == false)
              ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      if (message.sender != null) {
                        widget.unfocus();
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          builder: (context) {
                            return SBUBottomSheetUserComponent(
                              user: message.sender!,
                              on1On1ChannelCreated: widget.on1On1ChannelCreated,
                            );
                          },
                        );
                      }
                    },
                    child: widget.getAvatarComponent(
                      isLightTheme: isLightTheme,
                      size: 26,
                      user: message.sender,
                    ),
                  ),
                )
              : const SizedBox(width: 26),
        ),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSameMinuteAtPreviousMessage == false)
                if (message.isReplyToChannel == false &&
                    message.parentMessageId == null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: SBUTextComponent(
                      text: widget.getNickname(message.sender, strings),
                      textType: SBUTextType.caption1,
                      textColorType: SBUTextColorType.text02,
                    ),
                  ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onLongPress: () async {
                    if (!SBUReactionManager()
                            .isReactionAvailable(collection.channel, message) &&
                        SendbirdUIKit().downloadFile == null &&
                        !SBUReplyManager()
                            .isQuoteReplyAvailable(collection.channel) &&
                        !SBUMarkAsUnreadManager().isOn()) {
                      return;
                    }

                    widget.unfocus();
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      builder: (context) {
                        return SBUBottomSheetMenuComponent(
                          channel: collection.channel,
                          message: message,
                          iconNames: [
                            if (SBUMarkAsUnreadManager().isOn())
                              SBUIcons.markAsUnread,
                            if (SBUReplyManager()
                                .isQuoteReplyAvailable(collection.channel))
                              SBUIcons.reply,
                          ],
                          buttonNames: [
                            if (SBUMarkAsUnreadManager().isOn())
                              strings.markAsUnread,
                            if (SBUReplyManager()
                                .isQuoteReplyAvailable(collection.channel))
                              strings.reply,
                          ],
                          onButtonClicked: (buttonName) async {
                            if (buttonName == strings.markAsUnread) {
                              await _markAsUnread(collection.channel, message);
                            } else if (buttonName == strings.reply) {
                              SBUMessageCollectionProvider()
                                  .setReplyingToMessage(
                                widget.messageCollectionNo,
                                message,
                              );
                            }
                          },
                          disabledNames:
                              message.isReplyToChannel ? [strings.reply] : null,
                        );
                      },
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isLightTheme
                          ? SBUColors.background100
                          : SBUColors.background400,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: imageWidth, // Check
                            padding: const EdgeInsets.all(4),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                                childAspectRatio: 1,
                              ),
                              itemCount: thumbnailWidgets.length,
                              itemBuilder: (context, index) {
                                final len = thumbnailWidgets.length;

                                double topLeft = (index == 0 ? 12 : 6);
                                double topRight = (index == 1 ? 12 : 6);

                                double bottomLeft = 6;
                                if (len <= 2) {
                                  if (index == 0) {
                                    bottomLeft = 12;
                                  }
                                } else if (len % 2 == 0) {
                                  if (index == len - 2) {
                                    bottomLeft = 12;
                                  }
                                } else if (len % 2 == 1) {
                                  if (index == len - 1) {
                                    bottomLeft = 12;
                                  }
                                }

                                double bottomRight = 6;
                                if (len <= 2) {
                                  if (index == 1) {
                                    bottomRight = 12;
                                  }
                                } else if (len % 2 == 0) {
                                  if (index == len - 1) {
                                    bottomRight = 12;
                                  }
                                }

                                return ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(topLeft),
                                    topRight: Radius.circular(topRight),
                                    bottomLeft: Radius.circular(bottomLeft),
                                    bottomRight: Radius.circular(bottomRight),
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      InkWell(
                                        onTap: () async {
                                          if (widget
                                                  .onListItemWithIndexClicked !=
                                              null) {
                                            widget.onListItemWithIndexClicked!(
                                                collection.channel,
                                                message,
                                                index);
                                          }
                                        },
                                        child: thumbnailWidgets[index] ??
                                            Container(
                                              color: isLightTheme
                                                  ? SBUColors.primaryMain
                                                  : SBUColors.primaryLight,
                                              padding: const EdgeInsets.only(
                                                  left: 12,
                                                  right: 12,
                                                  top: 7,
                                                  bottom: 7),
                                              child: fileWidgets[index] ??
                                                  Container(
                                                    color: isLightTheme
                                                        ? SBUColors.background50
                                                        : SBUColors
                                                            .background600,
                                                  ),
                                            ),
                                      ),
                                      if (message.sendingStatus ==
                                          SendingStatus.pending) ...[
                                        Builder(builder: (context) {
                                          final uploadedIndices =
                                              SBUMessageCollectionProvider()
                                                  .getUploadedFileIndices(
                                                      widget
                                                          .messageCollectionNo,
                                                      message.requestId);

                                          if (!uploadedIndices
                                              .contains(index)) {
                                            return Container(
                                              color: Colors.black
                                                  .withAlpha(82), // Check
                                            );
                                          } else {
                                            return const SizedBox.shrink();
                                          }
                                        }),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        SBUReactionComponent(
                          channel: collection.channel,
                          message: message,
                          width: imageWidth, // Check
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 16,
          alignment: AlignmentDirectional.center,
          padding: const EdgeInsets.only(left: 4),
          child: SBUTextComponent(
            text: timeString,
            textType: SBUTextType.caption4,
            textColorType: SBUTextColorType.text03,
            transparent: isSameMinuteAtNextMessage,
          ),
        ),
      ],
    );
  }

  Widget _myFileMessageItemWidget({
    required MessageCollection collection,
    required FileMessage message,
    required bool isSameMinuteAtPreviousMessage,
    required bool isSameMinuteAtNextMessage,
    required String timeString,
    required bool isLightTheme,
    required SBUStrings strings,
  }) {
    final readStatusIcon =
        widget.getReadStatusIcon(collection.channel, message, isLightTheme);
    final isDisabled = widget.isDisabled(collection.channel);

    final thumbnailWidget = _getThumbnailWidget(
      isSucceededMessage: message.sendingStatus == SendingStatus.succeeded,
      requestId: message.requestId,
      messageId: message.messageId,
      multipleFileIndex: null,
      thumbnails: message.thumbnails,
      mimeType: message.type,
      secureUrl: message.secureUrl,
      filePath: message.file?.path,
      isLightTheme: isLightTheme,
      isParentMessage: false,
    );

    final fileWidget = _fileWidget(
      fileName: message.name,
      isLightTheme: isLightTheme,
      isMyMessage: true,
      multipleFileIndex: null,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (message.sendingStatus == SendingStatus.succeeded &&
            isSameMinuteAtNextMessage)
          Container(
            height: 16,
            alignment: AlignmentDirectional.center,
            padding: const EdgeInsets.only(right: 4),
            child: SBUTextComponent(
              text: timeString,
              textType: SBUTextType.caption4,
              textColorType: SBUTextColorType.text03,
              transparent: isSameMinuteAtNextMessage,
            ),
          ),
        if (readStatusIcon != null)
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            child: readStatusIcon,
          ),
        if (message.sendingStatus == SendingStatus.pending)
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  color: isLightTheme
                      ? SBUColors.primaryMain
                      : SBUColors.primaryLight,
                  strokeWidth: 1.4),
            ),
          ),
        if (message.sendingStatus == SendingStatus.failed)
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            child: SBUIconComponent(
              iconSize: 16,
              iconData: SBUIcons.error,
              iconColor:
                  isLightTheme ? SBUColors.errorMain : SBUColors.errorLight,
            ),
          ),
        if (message.sendingStatus == SendingStatus.succeeded &&
            isSameMinuteAtNextMessage == false)
          Container(
            height: 16,
            alignment: AlignmentDirectional.center,
            padding: const EdgeInsets.only(right: 4),
            child: SBUTextComponent(
              text: timeString,
              textType: SBUTextType.caption4,
              textColorType: SBUTextColorType.text03,
            ),
          ),
        Flexible(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                if (widget.onListItemClicked != null) {
                  widget.onListItemClicked!(collection.channel, message);
                }
              },
              onLongPress: () async {
                if (message.sendingStatus == SendingStatus.succeeded) {
                  if (!SBUReactionManager()
                          .isReactionAvailable(collection.channel, message) &&
                      SendbirdUIKit().downloadFile == null &&
                      isDisabled &&
                      !SBUReplyManager()
                          .isQuoteReplyAvailable(collection.channel) &&
                      !SBUMarkAsUnreadManager().isOn()) {
                    return;
                  }

                  widget.unfocus();
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    builder: (context) {
                      return SBUBottomSheetMenuComponent(
                        channel: collection.channel,
                        message: message,
                        iconNames: [
                          if (SendbirdUIKit().downloadFile != null)
                            SBUIcons.download,
                          if (SBUMarkAsUnreadManager().isOn())
                            SBUIcons.markAsUnread,
                          if (!isDisabled)
                            if (SBUMessageCollectionProvider().canDeleteMessage(
                                widget.messageCollectionNo, message))
                              SBUIcons.delete,
                          if (SBUReplyManager()
                              .isQuoteReplyAvailable(collection.channel))
                            SBUIcons.reply,
                        ],
                        buttonNames: [
                          if (SendbirdUIKit().downloadFile != null)
                            strings.save,
                          if (SBUMarkAsUnreadManager().isOn())
                            strings.markAsUnread,
                          if (!isDisabled)
                            if (SBUMessageCollectionProvider().canDeleteMessage(
                                widget.messageCollectionNo, message))
                              strings.delete,
                          if (SBUReplyManager()
                              .isQuoteReplyAvailable(collection.channel))
                            strings.reply,
                        ],
                        onButtonClicked: (buttonName) async {
                          if (buttonName == strings.save) {
                            SendbirdUIKit().downloadFile!(
                              message.secureUrl,
                              message.name,
                              () => widget.showToast(
                                isLightTheme: isLightTheme,
                                text: strings.fileSaved,
                              ),
                            );
                          } else if (buttonName == strings.markAsUnread) {
                            await _markAsUnread(collection.channel, message);
                          } else if (buttonName == strings.delete) {
                            await showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) => SBUDialogMenuComponent(
                                title: strings.deleteMessage,
                                buttonNames: [
                                  strings.cancel,
                                  strings.delete,
                                ],
                                onButtonClicked: (buttonName) async {
                                  if (buttonName == strings.cancel) {
                                    // Cancel
                                  } else if (buttonName == strings.delete) {
                                    if (message.sendingStatus ==
                                        SendingStatus.succeeded) {
                                      runZonedGuarded(() async {
                                        await collection.channel
                                            .deleteMessage(message.messageId);
                                      }, (error, stack) {
                                        // TODO: Check error
                                      });
                                    } else if (message.sendingStatus ==
                                        SendingStatus.failed) {
                                      await collection.removeFailedMessages(
                                          messages: [message]);
                                    }
                                  }
                                },
                                isYesOrNo: true,
                              ),
                            );
                          } else if (buttonName == strings.reply) {
                            SBUMessageCollectionProvider().setReplyingToMessage(
                              widget.messageCollectionNo,
                              message,
                            );
                          }
                        },
                        disabledNames: [
                          if (message.isReplyToChannel) strings.reply,
                          if (message.threadInfo != null &&
                              message.threadInfo!.replyCount > 0)
                            strings.delete,
                        ],
                      );
                    },
                  );
                } else if (message.sendingStatus == SendingStatus.failed) {
                  widget.unfocus();
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    builder: (context) {
                      return SBUBottomSheetMenuComponent(
                        buttonNames: [
                          if (!isDisabled) strings.retry,
                          strings.remove,
                        ],
                        onButtonClicked: (buttonName) async {
                          if (buttonName == strings.retry) {
                            try {
                              collection.channel.resendFileMessage(message);
                            } catch (e) {
                              if (e is FileSizeLimitExceededException) {
                                // TODO: Check error
                              } else {
                                // TODO: Check error
                              }
                            }
                          } else if (buttonName == strings.remove) {
                            await collection
                                .removeFailedMessages(messages: [message]);
                          }
                        },
                        errorColorIndex: 1,
                      );
                    },
                  );
                }
              },
              child: Container(
                padding: thumbnailWidget != null
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(top: 7),
                decoration: BoxDecoration(
                  color: thumbnailWidget != null
                      ? isLightTheme
                          ? SBUColors.background100
                          : SBUColors.background400
                      : isLightTheme
                          ? SBUColors.primaryMain
                          : SBUColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: thumbnailWidget != null
                    ? Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: imageWidth, // Check
                              height: imageHeight,
                              child: thumbnailWidget,
                            ),
                          ),
                          SBUReactionComponent(
                            channel: collection.channel,
                            message: message,
                            width: imageWidth, // Check
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 12, right: 12, bottom: 7),
                            child: fileWidget,
                          ),
                          SBUReactionComponent(
                            channel: collection.channel,
                            message: message,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _myMultipleFilesMessageItemWidget({
    required MessageCollection collection,
    required MultipleFilesMessage message,
    required bool isSameMinuteAtPreviousMessage,
    required bool isSameMinuteAtNextMessage,
    required String timeString,
    required bool isLightTheme,
    required SBUStrings strings,
  }) {
    final readStatusIcon =
        widget.getReadStatusIcon(collection.channel, message, isLightTheme);
    final isDisabled = widget.isDisabled(collection.channel);

    List<Widget?> thumbnailWidgets = [];
    List<Widget?> fileWidgets = [];

    int fileCount = message.files.length;
    if (message.sendingStatus == SendingStatus.succeeded) {
      for (int i = 0; i < fileCount; i++) {
        thumbnailWidgets.add(_getThumbnailWidget(
          isSucceededMessage: message.sendingStatus == SendingStatus.succeeded,
          requestId: message.requestId,
          messageId: message.messageId,
          multipleFileIndex: i,
          thumbnails: message.files[i].thumbnails,
          mimeType: message.files[i].type,
          secureUrl: message.files[i].secureUrl,
          filePath: message.files[i].file?.path,
          isLightTheme: isLightTheme,
          isParentMessage: false,
        ));

        fileWidgets.add(_fileWidget(
          fileName: message.files[i].name,
          isLightTheme: isLightTheme,
          isMyMessage: true,
          multipleFileIndex: i,
        ));
      }
    } else {
      fileCount =
          message.messageCreateParams?.uploadableFileInfoList.length ?? 0;

      for (int i = 0; i < fileCount; i++) {
        final uploadableFileInfo =
            message.messageCreateParams?.uploadableFileInfoList[i];

        thumbnailWidgets.add(_getThumbnailWidget(
          isSucceededMessage: message.sendingStatus == SendingStatus.succeeded,
          requestId: message.requestId,
          messageId: message.messageId,
          multipleFileIndex: i,
          thumbnails: null,
          mimeType: uploadableFileInfo?.fileInfo.mimeType,
          secureUrl: '',
          filePath: uploadableFileInfo?.fileInfo.file?.path,
          isLightTheme: isLightTheme,
          isParentMessage: false,
        ));

        fileWidgets.add(_fileWidget(
          fileName: uploadableFileInfo?.fileInfo.fileName,
          isLightTheme: isLightTheme,
          isMyMessage: true,
          multipleFileIndex: i,
        ));
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (message.sendingStatus == SendingStatus.succeeded &&
            isSameMinuteAtNextMessage)
          Container(
            height: 16,
            alignment: AlignmentDirectional.center,
            padding: const EdgeInsets.only(right: 4),
            child: SBUTextComponent(
              text: timeString,
              textType: SBUTextType.caption4,
              textColorType: SBUTextColorType.text03,
              transparent: isSameMinuteAtNextMessage,
            ),
          ),
        if (readStatusIcon != null)
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            child: readStatusIcon,
          ),
        if (message.sendingStatus == SendingStatus.pending)
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  color: isLightTheme
                      ? SBUColors.primaryMain
                      : SBUColors.primaryLight,
                  strokeWidth: 1.4),
            ),
          ),
        if (message.sendingStatus == SendingStatus.failed)
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            child: SBUIconComponent(
              iconSize: 16,
              iconData: SBUIcons.error,
              iconColor:
                  isLightTheme ? SBUColors.errorMain : SBUColors.errorLight,
            ),
          ),
        if (message.sendingStatus == SendingStatus.succeeded &&
            isSameMinuteAtNextMessage == false)
          Container(
            height: 16,
            alignment: AlignmentDirectional.center,
            padding: const EdgeInsets.only(right: 4),
            child: SBUTextComponent(
              text: timeString,
              textType: SBUTextType.caption4,
              textColorType: SBUTextColorType.text03,
            ),
          ),
        Flexible(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onLongPress: () async {
                if (message.sendingStatus == SendingStatus.succeeded) {
                  if (!SBUReactionManager()
                          .isReactionAvailable(collection.channel, message) &&
                      SendbirdUIKit().downloadFile == null &&
                      isDisabled &&
                      !SBUReplyManager()
                          .isQuoteReplyAvailable(collection.channel) &&
                      !SBUMarkAsUnreadManager().isOn()) {
                    return;
                  }

                  widget.unfocus();
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    builder: (context) {
                      return SBUBottomSheetMenuComponent(
                        channel: collection.channel,
                        message: message,
                        iconNames: [
                          if (SBUMarkAsUnreadManager().isOn())
                            SBUIcons.markAsUnread,
                          if (!isDisabled)
                            if (SBUMessageCollectionProvider().canDeleteMessage(
                                widget.messageCollectionNo, message))
                              SBUIcons.delete,
                          if (SBUReplyManager()
                              .isQuoteReplyAvailable(collection.channel))
                            SBUIcons.reply,
                        ],
                        buttonNames: [
                          if (SBUMarkAsUnreadManager().isOn())
                            strings.markAsUnread,
                          if (!isDisabled)
                            if (SBUMessageCollectionProvider().canDeleteMessage(
                                widget.messageCollectionNo, message))
                              strings.delete,
                          if (SBUReplyManager()
                              .isQuoteReplyAvailable(collection.channel))
                            strings.reply,
                        ],
                        onButtonClicked: (buttonName) async {
                          if (buttonName == strings.markAsUnread) {
                            await _markAsUnread(collection.channel, message);
                          } else if (buttonName == strings.delete) {
                            await showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) => SBUDialogMenuComponent(
                                title: strings.doYouWantToDeleteAllPhotos(
                                    fileCount.toString()),
                                buttonNames: [
                                  strings.cancel,
                                  strings.delete,
                                ],
                                onButtonClicked: (buttonName) async {
                                  if (buttonName == strings.cancel) {
                                    // Cancel
                                  } else if (buttonName == strings.delete) {
                                    if (message.sendingStatus ==
                                        SendingStatus.succeeded) {
                                      runZonedGuarded(() async {
                                        await collection.channel
                                            .deleteMessage(message.messageId);
                                      }, (error, stack) {
                                        // TODO: Check error
                                      });
                                    } else if (message.sendingStatus ==
                                        SendingStatus.failed) {
                                      await collection.removeFailedMessages(
                                          messages: [message]);
                                    }
                                  }
                                },
                                isYesOrNo: true,
                                maxLines: 2,
                              ),
                            );
                          } else if (buttonName == strings.reply) {
                            SBUMessageCollectionProvider().setReplyingToMessage(
                              widget.messageCollectionNo,
                              message,
                            );
                          }
                        },
                        disabledNames: [
                          if (message.isReplyToChannel) strings.reply,
                          if (message.threadInfo != null &&
                              message.threadInfo!.replyCount > 0)
                            strings.delete,
                        ],
                      );
                    },
                  );
                } else if (message.sendingStatus == SendingStatus.failed) {
                  widget.unfocus();
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    builder: (context) {
                      return SBUBottomSheetMenuComponent(
                        buttonNames: [
                          if (!isDisabled) strings.retry,
                          strings.remove,
                        ],
                        onButtonClicked: (buttonName) async {
                          if (buttonName == strings.retry) {
                            try {
                              collection.channel.resendMultipleFilesMessage(
                                message,
                                fileUploadHandler: (requestId, index,
                                    uploadableFileInfo, error) {
                                  if (error == null) {
                                    SBUMessageCollectionProvider()
                                        .notifyFileUploadCompleted(
                                      widget.messageCollectionNo,
                                      requestId,
                                      index,
                                    );
                                  }
                                },
                              );
                            } catch (e) {
                              // Check
                            }
                          } else if (buttonName == strings.remove) {
                            await collection
                                .removeFailedMessages(messages: [message]);
                          }
                        },
                        errorColorIndex: 1,
                      );
                    },
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isLightTheme
                      ? SBUColors.background100
                      : SBUColors.background400,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: imageWidth, // Check
                        padding: const EdgeInsets.all(4),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                            childAspectRatio: 1,
                          ),
                          itemCount: thumbnailWidgets.length >= 3 &&
                                  thumbnailWidgets.length % 2 == 1
                              ? thumbnailWidgets.length + 1
                              : thumbnailWidgets.length,
                          itemBuilder: (context, index) {
                            final len = thumbnailWidgets.length;
                            Widget? thumbnailWidget;
                            Widget? fileWidget;
                            bool isEmptyWidget = false;

                            if (len >= 3 && len % 2 == 1) {
                              if (index == len - 1) {
                                isEmptyWidget = true;
                                thumbnailWidget = Container();
                                fileWidget = Container();
                              } else if (index == len) {
                                thumbnailWidget = thumbnailWidgets[index - 1];
                                fileWidget = fileWidgets[index - 1];
                              } else {
                                thumbnailWidget = thumbnailWidgets[index];
                                fileWidget = fileWidgets[index];
                              }
                            } else {
                              thumbnailWidget = thumbnailWidgets[index];
                              fileWidget = fileWidgets[index];
                            }

                            double topLeft = (index == 0 ? 12 : 6);
                            double topRight = (index == 1 ? 12 : 6);

                            double bottomLeft = 6;
                            if (len <= 2) {
                              if (index == 0) {
                                bottomLeft = 12;
                              }
                            } else if (len % 2 == 0) {
                              if (index == len - 2) {
                                bottomLeft = 12;
                              }
                            }

                            double bottomRight = 6;
                            if (len <= 2) {
                              if (index == 1) {
                                bottomRight = 12;
                              }
                            } else if (len % 2 == 0) {
                              if (index == len - 1) {
                                bottomRight = 12;
                              }
                            } else if (len % 2 == 1) {
                              if (index == len) {
                                bottomRight = 12;
                              }
                            }

                            return ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(topLeft),
                                topRight: Radius.circular(topRight),
                                bottomLeft: Radius.circular(bottomLeft),
                                bottomRight: Radius.circular(bottomRight),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      if (widget.onListItemWithIndexClicked !=
                                          null) {
                                        if (len >= 3 &&
                                            len % 2 == 1 &&
                                            index == len - 1) {
                                          return;
                                        }

                                        int actualFileIndex = index;
                                        if (len >= 3 &&
                                            len % 2 == 1 &&
                                            index == len) {
                                          actualFileIndex = index - 1;
                                        }

                                        widget.onListItemWithIndexClicked!(
                                          collection.channel,
                                          message,
                                          actualFileIndex,
                                        );
                                      }
                                    },
                                    child: thumbnailWidget ??
                                        Container(
                                          color: isLightTheme
                                              ? SBUColors.primaryMain
                                              : SBUColors.primaryLight,
                                          padding: const EdgeInsets.only(
                                              left: 12,
                                              right: 12,
                                              top: 7,
                                              bottom: 7),
                                          child: fileWidget ??
                                              Container(
                                                color: isLightTheme
                                                    ? SBUColors.background50
                                                    : SBUColors.background600,
                                              ),
                                        ),
                                  ),
                                  if (!isEmptyWidget &&
                                      message.sendingStatus ==
                                          SendingStatus.pending) ...[
                                    Builder(builder: (context) {
                                      final uploadedIndices =
                                          SBUMessageCollectionProvider()
                                              .getUploadedFileIndices(
                                                  widget.messageCollectionNo,
                                                  message.requestId);

                                      int actualFileIndex = index;
                                      if (len >= 3 &&
                                          len % 2 == 1 &&
                                          index == len) {
                                        actualFileIndex = index - 1;
                                      }

                                      if (!uploadedIndices
                                          .contains(actualFileIndex)) {
                                        return Container(
                                          color: Colors.black
                                              .withAlpha(82), // Check
                                        );
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    }),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SBUReactionComponent(
                      channel: collection.channel,
                      message: message,
                      width: imageWidth, // Check
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _messageItemPadding({
    required BaseMessage message,
    required int messageIndex,
    required bool isSameMinuteAtPreviousMessage,
    required bool isSameMinuteAtNextMessage,
    required Widget child,
  }) {
    Widget result = child;

    result = Padding(
      padding: EdgeInsets.only(
        left: 12,
        top: widget.isReplyMessageToChannel(message)
            ? 8 // Check
            : isSameMinuteAtPreviousMessage
                ? 1
                : 8,
        right: 12,
        bottom: widget.isReplyMessageToChannel(message)
            ? (messageIndex == 0)
                ? 16 - 6 // Check
                : 8 - 6 // Check
            : isSameMinuteAtNextMessage
                ? 1
                : (messageIndex == 0)
                    ? 16
                    : 8,
      ),
      child: child,
    );

    return result;
  }

  Widget _parentMessageItemWidget({
    required MessageCollection collection,
    required BaseMessage message,
    required bool isSameMinuteAtPreviousMessage,
    required bool isSameMinuteAtNextMessage,
    required String timeString,
    required bool isLightTheme,
    required SBUStrings strings,
    required bool isMyMessage,
  }) {
    if (message is UserMessage) {
      final parentUserMessageWidget = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _moveToParentMessage(message);
          },
          child: Container(
            padding:
                const EdgeInsets.only(left: 12, top: 6, right: 12, bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isLightTheme
                  ? SBUColors.background100
                  : SBUColors.background400,
            ),
            child: SBUTextComponent(
              text: message.message,
              textType: SBUTextType.body3,
              textColorType: SBUTextColorType.text03,
              textOverflowType: null,
              maxLines: null,
            ),
          ),
        ),
      );

      if (isMyMessage) {
        return parentUserMessageWidget;
      } else {
        return Padding(
          padding: const EdgeInsets.only(left: 38),
          child: parentUserMessageWidget,
        );
      }
    } else if (message is FileMessage) {
      final thumbnailWidget = _getThumbnailWidget(
        isSucceededMessage: message.sendingStatus == SendingStatus.succeeded,
        requestId: message.requestId,
        messageId: message.messageId,
        multipleFileIndex: null,
        thumbnails: message.thumbnails,
        mimeType: message.type,
        secureUrl: message.secureUrl,
        filePath: message.file?.path,
        isLightTheme: isLightTheme,
        isParentMessage: true,
      );

      final parentFileMessageWidget = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _moveToParentMessage(message);
          },
          child: (thumbnailWidget != null)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 156,
                        height: 104,
                        child: thumbnailWidget,
                      ),
                      Container(
                        width: 156,
                        height: 104,
                        color: const Color(0x00FFFFFF).withOpacity(0.4),
                      ),
                    ],
                  ),
                )
              : Container(
                  height: 38,
                  padding: const EdgeInsets.only(
                      left: 12, top: 6, right: 12, bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isLightTheme
                        ? SBUColors.background100
                        : SBUColors.background400,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: SBUIconComponent(
                          iconSize: 16,
                          iconData: SBUIcons.fileDocument,
                          iconColor: isLightTheme
                              ? SBUColors.lightThemeTextLowEmphasis
                              : SBUColors.darkThemeTextLowEmphasis,
                        ),
                      ),
                      Flexible(
                        child: SBUTextComponent(
                          text: message.name ?? '',
                          textType: SBUTextType.body3,
                          textColorType: SBUTextColorType.text03,
                          // SBUTextOverflowType.ellipsisMiddle
                          textOverflowType: null,
                          maxLines: null, // 1
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );

      if (isMyMessage) {
        return parentFileMessageWidget;
      } else {
        return Padding(
          padding: const EdgeInsets.only(left: 38),
          child: parentFileMessageWidget,
        );
      }
    } else if (message is MultipleFilesMessage) {
      const index = 0;
      final thumbnailWidget = _getThumbnailWidget(
        isSucceededMessage: message.sendingStatus == SendingStatus.succeeded,
        requestId: message.requestId,
        messageId: message.messageId,
        multipleFileIndex: null,
        thumbnails: message.files[index].thumbnails,
        mimeType: message.files[index].type,
        secureUrl: message.files[index].secureUrl,
        filePath: message.files[index].file?.path,
        isLightTheme: isLightTheme,
        isParentMessage: true,
      );

      final parentFileMessageWidget = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _moveToParentMessage(message);
          },
          child: (thumbnailWidget != null)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 156,
                        height: 104,
                        child: thumbnailWidget,
                      ),
                      Container(
                        width: 156,
                        height: 104,
                        color: const Color(0x00FFFFFF).withOpacity(0.4),
                      ),
                    ],
                  ),
                )
              : Container(
                  height: 38,
                  padding: const EdgeInsets.only(
                      left: 12, top: 6, right: 12, bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isLightTheme
                        ? SBUColors.background100
                        : SBUColors.background400,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: SBUIconComponent(
                          iconSize: 16,
                          iconData: SBUIcons.fileDocument,
                          iconColor: isLightTheme
                              ? SBUColors.lightThemeTextLowEmphasis
                              : SBUColors.darkThemeTextLowEmphasis,
                        ),
                      ),
                      Flexible(
                        child: SBUTextComponent(
                          text: message.files[index].name ?? '',
                          textType: SBUTextType.body3,
                          textColorType: SBUTextColorType.text03,
                          // SBUTextOverflowType.ellipsisMiddle
                          textOverflowType: null,
                          maxLines: null, // 1
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );

      if (isMyMessage) {
        return parentFileMessageWidget;
      } else {
        return Padding(
          padding: const EdgeInsets.only(left: 38),
          child: parentFileMessageWidget,
        );
      }
    }

    return Container();
  }

  void _moveToParentMessage(BaseMessage message) {
    if (widget.onParentMessageClicked != null) {
      widget.onParentMessageClicked!(message);
    }
  }

  Widget _replyToChannel({
    required MessageCollection collection,
    required BaseMessage message,
    required bool isSameMinuteAtPreviousMessage,
    required bool isSameMinuteAtNextMessage,
    required String timeString,
    required bool isLightTheme,
    required SBUStrings strings,
    required bool isMyMessage,
    required Widget child,
  }) {
    Widget result = child;

    if (widget.isReplyMessageToChannel(message)) {
      BaseMessage parentMessage = message.parentMessage!;
      if (message.parentMessageId != null) {
        final updatableMessage = collection.messageList
            .firstWhereOrNull((m) => m.messageId == message.parentMessageId);
        if (updatableMessage != null) {
          parentMessage = updatableMessage;
        }
      }

      Widget parentMessageItemWidget = _parentMessageItemWidget(
        collection: collection,
        message: parentMessage,
        isSameMinuteAtPreviousMessage: isSameMinuteAtPreviousMessage,
        isSameMinuteAtNextMessage: isSameMinuteAtNextMessage,
        timeString: timeString,
        isLightTheme: isLightTheme,
        strings: strings,
        isMyMessage: isMyMessage,
      );

      String userA = widget.getNicknameOrYou(message.sender, strings);
      String userB =
          widget.getNicknameOrYou(message.parentMessage?.sender, strings);
      String repliedToString = strings.repliedTo(userA, userB);

      result = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              SizedBox(width: isMyMessage ? 0 : 50),
              SBUIconComponent(
                iconSize: 12,
                iconData: SBUIcons.replyFilled,
                iconColor: isLightTheme
                    ? SBUColors.lightThemeTextLowEmphasis
                    : SBUColors.darkThemeTextLowEmphasis,
              ),
              const SizedBox(width: 4),
              SBUTextComponent(
                text: repliedToString,
                textType: SBUTextType.caption1,
                textColorType: SBUTextColorType.text03,
              ),
              SizedBox(width: isMyMessage ? 12 : 0),
            ],
          ),
          const SizedBox(height: 4),
          parentMessageItemWidget,
          Transform(
            transform: Matrix4.identity()..translate(0.0, -6),
            child: child,
          ),
        ],
      );
    }

    return result;
  }

  Future<void> _markAsUnread(GroupChannel channel, BaseMessage message) async {
    await SBUMarkAsUnreadManager().markAsUnread(channel, message);
  }
}

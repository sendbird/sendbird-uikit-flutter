// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_avatar_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_icon_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_component.dart';
import 'package:sendbird_uikit/src/internal/resource/sbu_text_styles.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_file_send_queue_manager.dart';

abstract class SBUStatefulComponent extends StatefulWidget
    with SBUBaseComponent {
  const SBUStatefulComponent({super.key});
}

abstract class SBUStatelessComponent extends StatelessWidget
    with SBUBaseComponent {
  const SBUStatelessComponent({super.key});
}

enum SBUFileType {
  image,
  video,
  other,
}

mixin SBUBaseComponent {
  // Name
  String getGroupChannelName(GroupChannel channel, SBUStrings strings) {
    String name = channel.name;
    if (name.isEmpty) {
      final sortedMembers = sortMembersByNickname(channel.members);

      for (int i = 0; i < sortedMembers.length; i++) {
        final member = sortedMembers[i];
        if (member.userId == SendbirdChat.currentUser?.userId) {
          continue;
        }

        final nickname = getNickname(member, strings);
        name += nickname;
        if (i < sortedMembers.length - 1) {
          name += ', ';
        }
      }
    }

    if (name.isEmpty) {
      name = strings.noMembers;
    }
    return name;
  }

  String getNickname(User? user, SBUStrings strings) {
    String nickname = '';
    if (user != null) {
      if (user.nickname.isNotEmpty) {
        nickname = user.nickname;
      } else {
        nickname = user.userId; // strings.noName
      }
    }
    return nickname;
  }

  String getNicknameOrYou(User? user, SBUStrings strings) {
    String result = '';
    if (user != null) {
      if (user.userId.isNotEmpty &&
          user.userId == SendbirdChat.currentUser?.userId) {
        return strings.you;
      }

      if (user.nickname.isNotEmpty) {
        result = user.nickname;
      }
    }
    return result;
  }

  List<User> sortUsersByNickname(List<User> users) {
    final sortedMembers = List.of(users);
    sortedMembers.sort((a, b) {
      if (SendbirdChat.currentUser != null) {
        final currentUserId = SendbirdChat.currentUser!.userId;
        if (a.userId == currentUserId) {
          return -1;
        } else if (b.userId == currentUserId) {
          return 1;
        }
      }

      if (a.nickname.isEmpty) {
        return 1;
      } else if (b.nickname.isEmpty) {
        return -1;
      }
      return a.nickname.compareTo(b.nickname);
    });
    return sortedMembers;
  }

  List<Member> sortMembersByNickname(List<Member> members) {
    return sortUsersByNickname(members).map((user) => user as Member).toList();
  }

  // Avatar
  SBUAvatarComponent getAvatarComponent({
    required bool isLightTheme,
    required double size,
    User? user,
  }) {
    final imageUrl = user?.profileUrl ?? '';

    SBUIconComponent? icon = imageUrl.isEmpty
        ? SBUIconComponent(
            iconSize: size * 0.57138888888,
            iconData: SBUIcons.user,
            iconColor: isLightTheme
                ? SBUColors.darkThemeTextHighEmphasis
                : SBUColors.lightThemeTextHighEmphasis,
          )
        : null;
    Color? backgroundColor = imageUrl.isEmpty ? SBUColors.background300 : null;

    return SBUAvatarComponent(
      width: size,
      height: size,
      icon: icon,
      backgroundColor: backgroundColor,
      imageUrls: imageUrl.isNotEmpty ? [imageUrl] : [],
      isMutedMember: (user is Member && user.isMuted),
    );
  }

  SBUAvatarComponent getGroupChannelAvatarComponent({
    required bool isLightTheme,
    required double size,
    required GroupChannel channel,
  }) {
    final List<String> imageUrls = [];
    final sortedMembers = sortMembersByNickname(channel.members);
    final isDefaultCoverUrl = channel.coverUrl
        .startsWith('https://static.sendbird.com/sample/cover/cover_');

    if (channel.coverUrl.isNotEmpty && isDefaultCoverUrl == false) {
      imageUrls.add(channel.coverUrl);
    } else {
      for (int i = 0; i < sortedMembers.length; i++) {
        final member = sortedMembers[i];
        if (member.userId != SendbirdChat.currentUser?.userId) {
          imageUrls.add(member.profileUrl);
          if (imageUrls.length == 4) {
            break;
          }
        }
      }
    }

    SBUIconComponent? icon = imageUrls.isEmpty
        ? SBUIconComponent(
            iconSize: size * 0.57142857142,
            iconData: SBUIcons.user,
            iconColor: isLightTheme
                ? SBUColors.darkThemeTextHighEmphasis
                : SBUColors.lightThemeTextHighEmphasis,
          )
        : null;
    Color? backgroundColor = imageUrls.isEmpty ? SBUColors.background300 : null;

    if (channel.isBroadcast) {
      imageUrls.clear();
      icon = SBUIconComponent(
        iconSize: size * 0.57142857142,
        iconData: SBUIcons.broadcast,
        iconColor: isLightTheme
            ? SBUColors.darkThemeTextHighEmphasis
            : SBUColors.lightThemeTextHighEmphasis,
      );
      backgroundColor =
          isLightTheme ? SBUColors.secondaryMain : SBUColors.secondaryLight;
    }

    return SBUAvatarComponent(
      width: size,
      height: size,
      icon: icon,
      backgroundColor: backgroundColor,
      imageUrls: imageUrls,
    );
  }

  String? getTypingStatus(GroupChannel channel, SBUStrings strings) {
    final typingUsers = channel.getTypingUsers();
    final count = typingUsers.length;

    if (count == 1) {
      return strings.isTyping(getNickname(typingUsers[0], strings));
    } else if (count == 2) {
      return strings.areTyping(
        getNickname(typingUsers[0], strings),
        getNickname(typingUsers[1], strings),
      );
    } else if (count >= 3) {
      return strings.severalPeopleAreTyping;
    }
    return null;
  }

  SBUIconComponent? getReadStatusIcon(
    GroupChannel channel,
    BaseMessage? message,
    bool isLightTheme,
  ) {
    if (channel.isSuper == false && channel.isBroadcast == false) {
      if (message != null && message.sendingStatus == SendingStatus.succeeded) {
        final senderId = message.sender?.userId;
        if (senderId != null && senderId == SendbirdChat.currentUser?.userId) {
          final unreadMembers = channel.getUnreadMembers(message);
          final isAllMembersRead = unreadMembers.isEmpty;

          final undeliveredMembers = channel.getUndeliveredMembers(message);
          final isAllMembersDelivered = undeliveredMembers?.isEmpty ?? false;

          return SBUIconComponent(
            iconSize: 16,
            iconData: (isAllMembersRead || isAllMembersDelivered)
                ? SBUIcons.doneAll
                : SBUIcons.done,
            iconColor: isAllMembersRead
                ? (isLightTheme
                    ? SBUColors.secondaryMain
                    : SBUColors.secondaryLight)
                : (isLightTheme
                    ? SBUColors.lightThemeTextLowEmphasis
                    : SBUColors.darkThemeTextLowEmphasis),
          );
        }
      }
    }
    return null;
  }

  SBUFileType getFileType(String? mimeType) {
    if (mimeType != null) {
      if (mimeType.startsWith('image')) {
        return SBUFileType.image;
      } else if (mimeType.startsWith('video')) {
        return SBUFileType.video;
      }
    }
    return SBUFileType.other;
  }

  String? getChannelCacheKey(BaseChannel? channel) {
    if (channel != null) {
      return channel.channelUrl; // Check
    }
    return null;
  }

  String? getMessageCacheKey(BaseMessage? message) {
    if (message != null) {
      return '${message.requestId}_${message.messageId}'; // Check
    }
    return null;
  }

  void unfocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Widget getDefaultContainer(
    bool isLightTheme, {
    Widget? child,
  }) {
    return Container(
      color: isLightTheme ? SBUColors.background50 : SBUColors.background600,
      child: child,
    );
  }

  Member? getMyMember(GroupChannel? channel) {
    if (channel == null) {
      return null;
    }

    final member = channel.members.firstWhereOrNull(
        (member) => member.userId == SendbirdChat.currentUser?.userId);
    return member;
  }

  bool amIMuted(GroupChannel? channel) {
    final myMember = getMyMember(channel);
    final amIMuted = myMember?.isMuted ?? false;
    return amIMuted;
  }

  bool amIOperator(GroupChannel? channel) {
    final myMember = getMyMember(channel);
    final amIOperator = myMember?.role == Role.operator;
    return amIOperator;
  }

  bool amIFrozen(GroupChannel? channel) {
    final amIFrozen = (channel?.isFrozen ?? false) && !amIOperator(channel);
    return amIFrozen;
  }

  bool isDisabled(GroupChannel? channel) {
    final myMember = getMyMember(channel);
    final amIMuted = myMember?.isMuted ?? false;
    final amIOperator = myMember?.role == Role.operator;
    final isDisabled =
        ((channel?.isFrozen ?? false) && !amIOperator) || amIMuted;
    return isDisabled;
  }

  // File
  bool canGetFile() {
    return SendbirdUIKit().takePhoto != null ||
        SendbirdUIKit().takeVideo != null ||
        SendbirdUIKit().choosePhoto != null ||
        SendbirdUIKit().chooseDocument != null;
  }

  bool canGetPhotoFile() {
    return SendbirdUIKit().takePhoto != null ||
        SendbirdUIKit().choosePhoto != null;
  }

  bool canTakePhoto() {
    return SendbirdUIKit().takePhoto != null;
  }

  bool canTakeVideo() {
    return SendbirdUIKit().takeVideo != null;
  }

  bool canChoosePhoto() {
    return SendbirdUIKit().choosePhoto != null;
  }

  bool canChooseMedia() {
    return SendbirdUIKit().chooseMedia != null;
  }

  bool canChooseDocument() {
    return SendbirdUIKit().chooseDocument != null;
  }

  bool canChooseFiles() {
    return SendbirdUIKit().chooseFiles != null;
  }

  // Clipboard
  Future<void> copyTextToClipboard(String text, SBUStrings strings) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  // Toast
  void showToast({
    required bool isLightTheme,
    required String text,
    bool isError = false,
  }) {
    try {
      FToast().showToast(
        gravity: ToastGravity.BOTTOM,
        toastDuration: const Duration(seconds: 4), // Check
        child: Container(
          padding:
              const EdgeInsets.only(left: 12, top: 12, right: 16, bottom: 12),
          decoration: BoxDecoration(
            color: isLightTheme
                ? SBUColors.background600
                : SBUColors.background300,
            borderRadius: const BorderRadius.all(Radius.circular(24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SBUIconComponent(
                iconSize: 24,
                iconData: isError ? SBUIcons.error : SBUIcons.done,
                iconColor: isLightTheme
                    ? (isError
                        ? SBUColors.errorLight
                        : SBUColors.secondaryLight)
                    : (isError ? SBUColors.errorMain : SBUColors.secondaryMain),
              ),
              const SizedBox(width: 8),
              SBUTextComponent(
                text: text,
                textType: SBUTextType.body3,
                textColorType: SBUTextColorType.toast,
              ),
            ],
          ),
        ),
      );
    } catch (_) {}
  }

  Size getThumbnailSize() {
    return const Size(600, 600); // Check
  }

  bool isReplyMessageToChannel(BaseMessage message) {
    return (message.isReplyToChannel && message.parentMessage != null);
  }

  // Test
  bool isThemeTestOn() {
    return false;
  }

  // sendFileMessage
  void sendFileMessage({
    required GroupChannel channel,
    required FileInfo fileInfo,
    BaseMessage? replyingToMessage,
    List<Size>? thumbnailSizes,
  }) {
    FileMessageCreateParams params;
    if (kIsWeb) {
      if (fileInfo.fileBytes != null) {
        params = FileMessageCreateParams.withFileBytes(
          fileInfo.fileBytes!,
          fileName: fileInfo.fileName,
          replyToChannel: (replyingToMessage != null),
          parentMessageId: replyingToMessage?.messageId,
        )..thumbnailSizes = thumbnailSizes ?? [];
      } else {
        return;
      }
    } else {
      if (fileInfo.file != null) {
        params = FileMessageCreateParams.withFile(
          fileInfo.file!,
          fileName: fileInfo.fileName,
          replyToChannel: (replyingToMessage != null),
          parentMessageId: replyingToMessage?.messageId,
        )..thumbnailSizes = thumbnailSizes ?? [];
      } else {
        return;
      }
    }

    // Use queue manager for sequential file sending
    SBUFileSendQueueManager().addFileTask(
      channel: channel,
      params: params,
    );
  }

  // sendMultipleFilesMessage
  void sendMultipleFilesMessage({
    required GroupChannel channel,
    required MultipleFilesMessageCreateParams params,
    MultipleFilesMessageHandler? handler,
    FileUploadHandler? fileUploadHandler,
    BaseMessage? replyingToMessage,
  }) {
    List<UploadableFileInfo> imageList = [];
    List<UploadableFileInfo> otherList = [];
    for (final uploadableFileInfo in params.uploadableFileInfoList) {
      if (uploadableFileInfo != null) {
        final fileType = getFileType(uploadableFileInfo.fileInfo.mimeType);
        if (fileType == SBUFileType.image) {
          imageList.add(uploadableFileInfo);
        } else {
          otherList.add(uploadableFileInfo);
        }
      }
    }

    if (imageList.isNotEmpty) {
      if (imageList.length == 1) {
        // Send single image as file message through queue
        sendFileMessage(
          channel: channel,
          fileInfo: imageList[0].fileInfo,
          replyingToMessage: replyingToMessage,
          thumbnailSizes: imageList[0].thumbnailSizes,
        );
      } else {
        // Send multiple images through queue
        // Take only the first 10 images from the imageList
        final limitedImageList = imageList.take(10).toList();
        params.uploadableFileInfoList = limitedImageList;

        if (replyingToMessage != null) {
          params.replyToChannel = true;
          params.parentMessageId = replyingToMessage.messageId;
        }

        SBUFileSendQueueManager().addMultipleFilesTask(
          channel: channel,
          params: params,
          handler: handler,
          fileUploadHandler: fileUploadHandler,
        );
      }
    }

    // Process only up to 5 files from otherList
    final count = (imageList.isNotEmpty ? 4 : 5);
    final limitedOtherList = otherList.take(count);

    for (final uploadableFileInfo in limitedOtherList) {
      // Send each non-image file through queue
      sendFileMessage(
        channel: channel,
        fileInfo: uploadableFileInfo.fileInfo,
        replyingToMessage: replyingToMessage,
        thumbnailSizes: uploadableFileInfo.thumbnailSizes,
      );
    }
  }
}

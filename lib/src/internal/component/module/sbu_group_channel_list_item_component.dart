// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_badge_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_dialog_menu_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_file_icon_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_icon_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_component.dart';
import 'package:sendbird_uikit/src/internal/component/module/sbu_channel_list_item_component.dart';
import 'package:sendbird_uikit/src/internal/resource/sbu_text_styles.dart';

class SBUGroupChannelListItemComponent extends SBUStatefulComponent {
  final double width;
  final double height;
  final GroupChannel channel;
  final void Function(GroupChannel)? onListItemClicked;

  const SBUGroupChannelListItemComponent({
    required this.width,
    required this.height,
    required this.channel,
    this.onListItemClicked,
    super.key,
  });

  @override
  State<StatefulWidget> createState() =>
      SBUGroupChannelListItemComponentState();
}

class SBUGroupChannelListItemComponentState
    extends State<SBUGroupChannelListItemComponent> {
  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.watch<SBUThemeProvider>().isLight();
    final strings = context.watch<SBUStringProvider>().strings;

    final width = widget.width;
    final height = widget.height;
    final channel = widget.channel;
    final onListItemClicked = widget.onListItemClicked;

    final avatar = widget.getGroupChannelAvatarComponent(
      isLightTheme: isLightTheme,
      size: 56,
      channel: channel,
    );

    final channelName = SBUTextComponent(
      text: widget.getGroupChannelName(channel, strings),
      textType: SBUTextType.subtitle1,
      textColorType: SBUTextColorType.text01,
    );

    //+ date
    String dateString = '';
    if (channel.lastMessage != null) {
      dateString = _getDateString(channel.lastMessage!.createdAt, strings);
    } else if (channel.createdAt != null) {
      dateString = _getDateString(channel.createdAt! * 1000, strings);
    }

    final date = SBUTextComponent(
      text: dateString,
      textType: SBUTextType.caption2,
      textColorType: SBUTextColorType.text02,
    );
    //- date

    //+ lastMessage
    String text = channel.lastMessage?.message ?? '';
    if (channel.lastMessage is FileMessage) {
      text = (channel.lastMessage as FileMessage).name ?? '';
    } else if (channel.lastMessage is MultipleFilesMessage) {
      final mfm = (channel.lastMessage as MultipleFilesMessage);
      if (mfm.files.isNotEmpty) {
        text = mfm.files.first.name ?? '';
      } else {
        text = '';
      }
    }

    final lastMessage = SBUTextComponent(
      text: widget.getTypingStatus(channel, strings) ?? text,
      textType: SBUTextType.body3,
      textColorType: SBUTextColorType.text03,
      textOverflowType: (channel.lastMessage is FileMessage ||
              channel.lastMessage is MultipleFilesMessage)
          ? SBUTextOverflowType.ellipsisMiddle
          : SBUTextOverflowType.ellipsisEnd,
    );
    //- lastMessage

    final preTitleBroadcastIcon = channel.isBroadcast
        ? SBUIconComponent(
            iconSize: 16,
            iconData: SBUIcons.broadcast,
            iconColor: isLightTheme
                ? SBUColors.secondaryMain
                : SBUColors.secondaryLight,
          )
        : null;

    final userCount = channel.members.length > 2
        ? SBUTextComponent(
            text: channel.members.length.toString(),
            textType: SBUTextType.caption1,
            textColorType: SBUTextColorType.text02,
          )
        : null;

    final postTitleFreezeIcon = channel.isFrozen
        ? SBUIconComponent(
            iconSize: 16,
            iconData: SBUIcons.freeze,
            iconColor:
                isLightTheme ? SBUColors.primaryMain : SBUColors.primaryLight,
          )
        : null;

    final postTitleNotificationsOffFilledIcon =
        (channel.myPushTriggerOption == GroupChannelPushTriggerOption.off)
            ? SBUIconComponent(
                iconSize: 16,
                iconData: SBUIcons.notificationsOffFilled,
                iconColor: isLightTheme
                    ? SBUColors.lightThemeTextLowEmphasis
                    : SBUColors.darkThemeTextLowEmphasis,
              )
            : null;

    // Check
    final preDateReadStatusIcon =
        widget.getReadStatusIcon(channel, channel.lastMessage, isLightTheme);

    SBUFileIconComponent? fileIcon;
    if (channel.lastMessage is FileMessage ||
        channel.lastMessage is MultipleFilesMessage) {
      fileIcon = SBUFileIconComponent(
        size: 26,
        backgroundColor:
            isLightTheme ? SBUColors.background100 : SBUColors.background500,
        iconSize: 18,
        iconData: SBUIcons.fileDocument,
        iconColor: isLightTheme
            ? SBUColors.lightThemeTextMidEmphasis
            : SBUColors.darkThemeTextMidEmphasis,
      );
    }

    final badge = channel.unreadMessageCount > 0
        ? SBUBadgeComponent(
            count: channel.unreadMessageCount,
            isLarge: true,
          )
        : null;

    final item = SBUChannelListItemComponent(
      width: width,
      height: height,
      backgroundColor:
          isLightTheme ? SBUColors.background50 : SBUColors.background600,
      channel: channel,
      avatar: avatar,
      title: channelName,
      date: date,
      lastMessage: lastMessage,
      preTitleIcon: preTitleBroadcastIcon,
      userCount: userCount,
      postTitleIcon: postTitleFreezeIcon,
      postTitleIcon2: postTitleNotificationsOffFilledIcon,
      preDateIcon: preDateReadStatusIcon,
      fileIcon: fileIcon,
      badge: badge,
      onListItemClicked: onListItemClicked != null
          ? (channel) => onListItemClicked(channel as GroupChannel)
          : null,
      onListItemLongPressed: (channel) async {
        final groupChannel = channel as GroupChannel;
        final isPushOff = (groupChannel.myPushTriggerOption ==
            GroupChannelPushTriggerOption.off);
        final isPushStatusString = isPushOff
            ? strings.turnPushNotificationOn
            : strings.turnPushNotificationOff;
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => SBUDialogMenuComponent(
            title: widget.getGroupChannelName(channel, strings),
            buttonNames: [
              if (!kIsWeb) isPushStatusString,
              strings.leaveChannel,
            ],
            onButtonClicked: (buttonName) async {
              if (buttonName == isPushStatusString) {
                runZonedGuarded(() async {
                  if (isPushOff) {
                    await groupChannel.setMyPushTriggerOption(
                        GroupChannelPushTriggerOption.all);
                  } else {
                    await groupChannel.setMyPushTriggerOption(
                        GroupChannelPushTriggerOption.off);
                  }
                }, (error, stack) {
                  // TODO: Check error
                });
              } else if (buttonName == strings.leaveChannel) {
                runZonedGuarded(() async {
                  await groupChannel.leave();
                }, (error, stack) {
                  // TODO: Check error
                });
              }
            },
          ),
        );
      },
    );

    return item;
  }

  String _getDateString(int timestamp, SBUStrings strings) {
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    // Today
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return DateFormat('h:mm a').format(dateTime);
    }

    // Yesterday
    final aDayAgo = now.subtract(const Duration(days: 1));
    if (dateTime.year == aDayAgo.year &&
        dateTime.month == aDayAgo.month &&
        dateTime.day == aDayAgo.day) {
      return strings.yesterday;
    }

    // This year
    if (dateTime.year == now.year) {
      return DateFormat('MMM dd').format(dateTime);
    }

    return DateFormat('yyyy/MM/dd').format(dateTime);
  }
}

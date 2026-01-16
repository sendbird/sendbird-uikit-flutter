// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_avatar_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_icon_button_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_icon_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_button_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_component.dart';
import 'package:sendbird_uikit/src/internal/resource/sbu_text_styles.dart';

class SBUHeaderComponent extends SBUStatefulComponent {
  final double width;
  final double height;
  final Color backgroundColor;
  final SBUTextComponent title;
  final bool hasBackKey;
  final SBUAvatarComponent? avatar;
  final SBUTextButtonComponent? textButton;
  final SBUIconButtonComponent? iconButton;
  final GroupChannel? channelForTypingStatus;

  const SBUHeaderComponent({
    required this.width,
    required this.height,
    required this.backgroundColor,
    required this.title,
    this.hasBackKey = false,
    this.avatar,
    this.textButton,
    this.iconButton,
    this.channelForTypingStatus,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => SBUHeaderComponentState();
}

class SBUHeaderComponentState extends State<SBUHeaderComponent> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<SBUThemeProvider>();
    final isLightTheme = themeProvider.isLight();
    final strings = context.watch<SBUStringProvider>().strings;

    final width = widget.width;
    final height = widget.height;
    final backgroundColor = widget.backgroundColor;
    final title = widget.title;
    final hasBackKey = widget.hasBackKey;
    final avatar = widget.avatar;
    final textButton = widget.textButton;
    final iconButton = widget.iconButton;

    final typingStatus = widget.channelForTypingStatus != null
        ? widget.getChannelTypingStatusText(
            widget.channelForTypingStatus!, strings)
        : null;

    final header = GestureDetector(
      onTap: () {
        if (widget.isThemeTestOn()) {
          themeProvider.toggleTheme();
        }
      },
      child: Column(
        children: [
          Container(
            width: width,
            height: height,
            color: backgroundColor,
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (hasBackKey)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: SBUIconButtonComponent(
                          iconButtonSize: 32,
                          icon: SBUIconComponent(
                            iconSize: 24,
                            iconData: SBUIcons.arrowLeft,
                            iconColor: isLightTheme
                                ? SBUColors.primaryMain
                                : SBUColors.primaryLight,
                          ),
                          onButtonClicked: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    if (avatar != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8),
                        child: avatar,
                      ),
                    Expanded(
                      child: Padding(
                        padding:
                            EdgeInsets.only(left: (avatar != null ? 0 : 24)),
                        child: (typingStatus != null && typingStatus.isNotEmpty)
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  title,
                                  const SizedBox(height: 2), // Check
                                  SBUTextComponent(
                                    text: typingStatus,
                                    textType: SBUTextType.body3,
                                    textColorType: SBUTextColorType.text03,
                                  ),
                                ],
                              )
                            : title,
                      ),
                    ),
                    if (textButton != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: textButton,
                      ),
                    if (iconButton != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: iconButton,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isLightTheme) {
      return Stack(
        children: [
          header,
          Container(
            width: width,
            height: height,
            alignment: Alignment.bottomCenter,
            child: Divider(
                height: 1,
                thickness: 1,
                color: SBUColors.lightThemeTextDisabled),
          ),
        ],
      );
    }
    return header;
  }
}

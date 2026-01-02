// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_button_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_component.dart';
import 'package:sendbird_uikit/src/internal/resource/sbu_text_styles.dart';

class SBUBottomSheetUserComponent extends SBUStatefulComponent {
  final User user;
  final void Function(GroupChannel)? on1On1ChannelCreated;

  const SBUBottomSheetUserComponent({
    required this.user,
    this.on1On1ChannelCreated,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => SBUBottomSheetUserComponentState();
}

class SBUBottomSheetUserComponentState
    extends State<SBUBottomSheetUserComponent> {
  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.watch<SBUThemeProvider>().isLight();
    final strings = context.watch<SBUStringProvider>().strings;

    final user = widget.user;
    final on1On1ChannelCreated = widget.on1On1ChannelCreated;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color:
              isLightTheme ? SBUColors.background50 : SBUColors.background500,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: widget.getAvatarComponent(
                isLightTheme: isLightTheme,
                size: 80,
                user: user,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SBUTextComponent(
                text: widget.getNickname(user, strings),
                textType: SBUTextType.heading1,
                textColorType: SBUTextColorType.text01,
              ),
            ),
            if (on1On1ChannelCreated != null)
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 24, right: 24),
                child: Material(
                  color: Colors.transparent,
                  child: SBUTextButtonComponent(
                    width: double.maxFinite,
                    height: 48,
                    text: SBUTextComponent(
                      text: strings.message,
                      textType: SBUTextType.button,
                      textColorType: SBUTextColorType.text01,
                    ),
                    onButtonClicked: () async {
                      GroupChannel.createChannel(
                        GroupChannelCreateParams()
                          ..userIds = [user.userId]
                          ..operatorUserIds = [SendbirdChat.currentUser!.userId]
                          ..name = ''
                          ..isDistinct = false,
                      ).then((channel) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        }

                        on1On1ChannelCreated(channel);
                      });
                    },
                    padding: const EdgeInsets.all(8),
                    hasBorder: true,
                    borderColor: isLightTheme
                        ? SBUColors.lightThemeTextHighEmphasis
                        : SBUColors.darkThemeTextHighEmphasis,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 24, right: 16),
              child: Container(
                height: 1,
                color: SBUColors.lightThemeTextDisabled,
              ),
            ),
            SizedBox(
              width: double.maxFinite,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 24, right: 16),
                child: SBUTextComponent(
                  text: strings.userId,
                  textType: SBUTextType.body2,
                  textColorType: SBUTextColorType.text02,
                ),
              ),
            ),
            SizedBox(
              width: double.maxFinite,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16, top: 4, right: 16, bottom: 24),
                child: SBUTextComponent(
                  text: user.userId,
                  textType: SBUTextType.body3,
                  textColorType: SBUTextColorType.text01,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

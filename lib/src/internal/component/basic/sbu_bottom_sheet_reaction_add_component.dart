// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_image_component.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_reaction_manager.dart';

class SBUBottomSheetReactionAddComponent extends SBUStatefulComponent {
  final BaseChannel? channel;
  final BaseMessage? message;

  const SBUBottomSheetReactionAddComponent({
    required this.channel,
    required this.message,
    super.key,
  });

  @override
  State<StatefulWidget> createState() =>
      SBUBottomSheetReactionAddComponentState();
}

class SBUBottomSheetReactionAddComponentState
    extends State<SBUBottomSheetReactionAddComponent> {
  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.watch<SBUThemeProvider>().isLight();

    final channel = widget.channel;
    final message = widget.message;

    if (!SBUReactionManager().isReactionAvailable(channel, message)) {
      return Container();
    }

    const int maxCount = 6;
    final emojiList = SBUReactionManager().getEmojiList();
    int columnCount = emojiList.length ~/ maxCount;
    if (emojiList.length % maxCount != 0) columnCount++;

    if (emojiList.isEmpty) {
      return Container();
    }

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
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Container(
              margin:
                  const EdgeInsets.only(left: 12, top: 8, right: 12, bottom: 8),
              height: columnCount * 60,
              child: Column(
                children: [
                  ...List<Row>.generate(columnCount, (index) {
                    return Row(
                      children: [
                        ...emojiList
                            .sublist(
                                index * maxCount,
                                index * maxCount +
                                    (index < columnCount - 1
                                        ? maxCount
                                        : emojiList.length % maxCount == 0
                                            ? maxCount
                                            : emojiList.length % maxCount))
                            .map(
                          (emoji) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                  left: 6, top: 8, right: 6, bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    Navigator.pop(context);
                                    SBUReactionManager().toggleReaction(
                                        channel, message, emoji.key);
                                  },
                                  child: Container(
                                    decoration: message!.reactions!
                                            .any((reaction) {
                                      final userId =
                                          SendbirdChat.currentUser?.userId;
                                      if (reaction.key == emoji.key &&
                                          userId != null &&
                                          reaction.userIds.contains(userId)) {
                                        return true;
                                      }
                                      return false;
                                    })
                                        ? BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            color: isLightTheme
                                                ? SBUColors.primaryExtraLight
                                                : SBUColors.primaryDark)
                                        : null,
                                    padding: const EdgeInsets.all(3),
                                    width: 44,
                                    height: 44,
                                    child: SBUImageComponent(
                                      imageUrl: emoji.url,
                                      cacheKey: emoji.key,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ).toList(),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

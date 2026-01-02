// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_image_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_reaction_member_list_item_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_scroll_bar_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_component.dart';
import 'package:sendbird_uikit/src/internal/resource/sbu_text_styles.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_reaction_manager.dart';

class SBUBottomSheetReactionDetailsComponent extends SBUStatefulComponent {
  final BaseChannel? channel;
  final BaseMessage? message;
  final Reaction selectedReaction;

  const SBUBottomSheetReactionDetailsComponent({
    required this.channel,
    required this.message,
    required this.selectedReaction,
    super.key,
  });

  @override
  State<StatefulWidget> createState() =>
      SBUBottomSheetReactionDetailsComponentState();
}

class SBUBottomSheetReactionDetailsComponentState
    extends State<SBUBottomSheetReactionDetailsComponent>
    with SingleTickerProviderStateMixin {
  final scrollController = ScrollController();
  bool isExtendedList = false;

  late int tabCount;
  late TabController tabController;

  @override
  void initState() {
    super.initState();

    scrollController.addListener(() {
      if (scrollController.offset > scrollController.position.minScrollExtent &&
          !scrollController.position.outOfRange) {
        if (mounted) {
          setState(() {
            isExtendedList = true;
          });
        }
      }
    });

    tabCount = widget.message?.reactions?.length ?? 0;

    int selectedReactionIndex = 0;
    final reactions = widget.message?.reactions;
    if (reactions != null) {
      for (int i = 0; i < reactions.length; i++) {
        if (widget.selectedReaction.key == reactions[i].key) {
          selectedReactionIndex = i;
          break;
        }
      }
    }

    tabController = TabController(
      initialIndex: selectedReactionIndex,
      length: tabCount,
      vsync: this,
      animationDuration: Duration.zero, // Check
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.watch<SBUThemeProvider>().isLight();

    final channel = widget.channel;
    final message = widget.message;
    final selectedReaction = widget.selectedReaction;

    if (!SBUReactionManager().isReactionAvailable(channel, message)) {
      return Container();
    }

    final reactions = widget.message!.reactions!;

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
        child: Container(
          height: (isExtendedList
              ? MediaQuery.of(context).size.height - 48
              : 276), // Check
          padding: const EdgeInsets.only(top: 16),
          child: DefaultTabController(
            length: tabCount,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    Container(
                      height: 1,
                      color: isLightTheme
                          ? SBUColors.lightThemeTextDisabled
                          : SBUColors.darkThemeTextDisabled,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TabBar(
                        controller: tabController,
                        isScrollable: true,
                        padding: EdgeInsets.zero,
                        labelPadding: EdgeInsets.zero,
                        indicatorWeight: 3,
                        indicatorColor: isLightTheme
                            ? SBUColors.primaryMain
                            : SBUColors.primaryLight,
                        indicatorPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        indicatorSize: TabBarIndicatorSize.label,
                        tabAlignment: TabAlignment.start,
                        tabs: List<Widget>.generate(
                          tabCount,
                          (index) {
                            final reaction = reactions[index];

                            final emojiUrl = SBUReactionManager()
                                .getEmoji(reaction.key)
                                ?.url;
                            if (emojiUrl == null) {
                              return Container(); // Check
                            }

                            return Tab(
                              height: 41,
                              child: Container(
                                margin: const EdgeInsets.only(
                                    left: 8, right: 8, bottom: 13),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: SBUImageComponent(
                                        imageUrl: emojiUrl,
                                        cacheKey: reaction.key,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    SBUTextComponent(
                                      text:
                                          '${reaction.userIds.length > 99 ? '99+' : reaction.userIds.length}',
                                      textType: SBUTextType.button,
                                      textColorType:
                                          (selectedReaction.key == reaction.key)
                                              ? SBUTextColorType.primary
                                              : SBUTextColorType.text03,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ).toList(),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: List<Widget>.generate(
                      tabCount,
                      (index) {
                        final reaction = reactions[index];
                        return SBUScrollBarComponent(
                          controller: scrollController,
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: reaction.userIds.length,
                            itemBuilder: (context, i) {
                              if (channel is GroupChannel) {
                                final member = channel.members.firstWhereOrNull(
                                  (member) =>
                                      (member.userId == reaction.userIds[i]),
                                );
                                if (member != null) {
                                  return SBUReactionMemberListItemComponent(
                                    width: double.maxFinite,
                                    height: 48,
                                    backgroundColor: isLightTheme
                                        ? SBUColors.background50
                                        : SBUColors.background500,
                                    user: member,
                                  );
                                }
                              }
                              return null;
                            },
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

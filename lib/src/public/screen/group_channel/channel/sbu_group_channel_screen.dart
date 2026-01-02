// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_icon_button_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_icon_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_placeholder_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_scroll_bar_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_component.dart';
import 'package:sendbird_uikit/src/internal/component/module/sbu_header_component.dart';
import 'package:sendbird_uikit/src/internal/component/module/sbu_message_input_component.dart';
import 'package:sendbird_uikit/src/internal/component/module/sbu_message_list_item_component.dart';
import 'package:sendbird_uikit/src/internal/provider/sbu_message_collection_provider.dart';
import 'package:sendbird_uikit/src/internal/resource/sbu_text_styles.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_file_send_queue_manager.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_mark_as_unread_manager.dart';

/// SBUGroupChannelScreen
class SBUGroupChannelScreen extends SBUStatefulComponent {
  static const double defaultScrollExtentToTriggerPreloading = 4000; // Check
  static const double defaultCacheExtent = 4000; // Check

  final String channelUrl;
  final MessageListParams? params;
  final void Function(int messageCollectionNo)? onMessageCollectionReady;
  final void Function(ScrollController)? onScrollControllerReady;
  final void Function(GroupChannel)? onChannelDeleted;
  final void Function(int messageCollectionNo)? onInfoButtonClicked;
  final void Function(GroupChannel)? on1On1ChannelCreated;
  final void Function(GroupChannel, BaseMessage)? onListItemClicked;
  final void Function(GroupChannel, BaseMessage, int index)?
      onListItemWithIndexClicked; // For MultipleFilesMessage
  final double scrollExtentToTriggerPreloading;
  final double cacheExtent;

  final Widget Function(
    BuildContext context,
    SBUTheme theme,
    SBUStrings strings,
    MessageCollection collection,
  )? customHeader;

  final Widget Function(
    BuildContext context,
    SBUTheme theme,
    SBUStrings strings,
    MessageCollection collection,
    int index,
    BaseMessage message,
  )? customListItem;

  final Widget Function(
    BuildContext context,
    SBUTheme theme,
    SBUStrings strings,
    MessageCollection collection,
  )? customMessageInput;

  final Widget Function(
    BuildContext context,
    SBUTheme theme,
    SBUStrings strings,
    MessageCollection collection,
  )? customLoadingBody;

  final Widget Function(
    BuildContext context,
    SBUTheme theme,
    SBUStrings strings,
    MessageCollection collection,
  )? customEmptyBody;

  final Widget Function(
    BuildContext context,
    SBUTheme theme,
    SBUStrings strings,
  )? customErrorScreen;

  final Widget Function(
    BuildContext context,
    SBUTheme theme,
    SBUStrings strings,
    MessageCollection collection,
  )? customFrozenChannel;

  const SBUGroupChannelScreen({
    required this.channelUrl,
    this.params,
    this.onMessageCollectionReady,
    this.onScrollControllerReady,
    this.onChannelDeleted,
    this.onInfoButtonClicked,
    this.on1On1ChannelCreated,
    this.onListItemClicked,
    this.onListItemWithIndexClicked,
    this.scrollExtentToTriggerPreloading =
        defaultScrollExtentToTriggerPreloading,
    this.cacheExtent = defaultCacheExtent,
    this.customHeader,
    this.customListItem,
    this.customMessageInput,
    this.customLoadingBody,
    this.customEmptyBody,
    this.customErrorScreen,
    this.customFrozenChannel,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => SBUGroupChannelScreenState();
}

class SBUGroupChannelScreenState extends State<SBUGroupChannelScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final scrollController = AutoScrollController();

  late final AnimationController _animationController;
  final int _animationDuration = 150;
  final int _animationShakingCount = 3;
  final int _animationGap = 4;

  int? collectionNo;
  bool isLoading = true;
  bool isError = false;

  int? clickedParentMessageIndex;
  bool isClickedParentMessageAnimating = false;

  final StreamController<MessageCollection> _streamController =
      StreamController<MessageCollection>();
  final List<ItemContext> _itemContexts = <ItemContext>[];

  bool _showUnreadBadge = false;
  bool _showMoveToBottomButton = false;
  bool _canShowUnreadBadge = true;

  // bool? _isNewLineVisible;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    FToast().init(context); // Check
    _init();

    _streamController.stream.listen(_checkNewLine);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _animationDuration),
    );
  }

  void _init() async {
    try {
      isError = false;

      await _initialize();
    } catch (_) {
      if (mounted) {
        setState(() {
          isError = true;
        });
      }
    }
  }

  bool _isNewLineExistsInChannel(MessageCollection collection) {
    return collection.channel.myLastRead <
        (collection.channel.lastMessage?.createdAt ?? 0);
  }

  Future<void> _initialize() async {
    final collectionProvider = SBUMessageCollectionProvider();
    final channel = await GroupChannel.getChannelFromCache(widget.channelUrl) ??
        await GroupChannel.getChannel(widget.channelUrl);

    collectionProvider.setMyLastRead(
        channel.channelUrl, channel.myLastRead); // Check

    collectionNo = collectionProvider.add(
      channel: channel,
      params: widget.params,
    );

    if (collectionNo != null && widget.onMessageCollectionReady != null) {
      widget.onMessageCollectionReady!(collectionNo!);
    }

    if (mounted) {
      setState(() {});
    }

    final collection = collectionNo != null
        ? collectionProvider.getCollection(collectionNo!)
        : null;

    if (collection != null) {
      if (_isNewLineExistsInChannel(collection)) {
        SBUMessageCollectionProvider()
            .enableNewLine(collection.channel.channelUrl); // Check
      }

      await collection.initialize();

      if (mounted) {
        final checkOnPostFrame = isLoading;

        setState(() {
          isLoading = false;
        });

        runZonedGuarded(() async {
          // Check if no scrollbar
          if (checkOnPostFrame) {
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
              if (collection.messageList.isNotEmpty) {
                if (scrollController.position.maxScrollExtent == 0) {
                  await _loadPrevious(collection);
                }

                if (!_streamController.isClosed) {
                  _streamController.add(collection);
                }

                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  if (widget.onScrollControllerReady != null) {
                    widget.onScrollControllerReady!(scrollController);
                  }
                });
              }
            });
          }
        }, (error, stack) {
          // TODO: Check error
        });
      }
    }
  }

  Future<void> _loadPrevious(MessageCollection collection) async {
    if (!collection.isLoading && collection.hasPrevious) {
      try {
        await collection.loadPrevious();
      } catch (_) {
        return;
      }

      if (mounted) {
        if (collection.messageList.isNotEmpty) {
          if (scrollController.position.maxScrollExtent == 0) {
            await _loadPrevious(collection);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    if (collectionNo != null) {
      final collection =
          SBUMessageCollectionProvider().getCollection(collectionNo!);
      if (collection != null) {
        SBUFileSendQueueManager().clearQueue(collection.channel.channelUrl);
      }

      SBUMessageCollectionProvider().remove(collectionNo!);
    }

    scrollController.dispose();
    _animationController.dispose();

    _streamController.close();
    _itemContexts.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final themeProvider = context.watch<SBUThemeProvider>();
    final theme = themeProvider.theme;
    final isLightTheme = themeProvider.isLight();
    final strings = context.watch<SBUStringProvider>().strings;

    final collectionProvider = context.watch<SBUMessageCollectionProvider>();

    if (isError) {
      if (widget.customErrorScreen != null) {
        return widget.getDefaultContainer(
          isLightTheme,
          child: widget.customErrorScreen!(
            context,
            theme,
            strings,
          ),
        );
      }
      return widget.getDefaultContainer(
        isLightTheme,
        child: SBUPlaceholderComponent(
          isLightTheme: isLightTheme,
          iconData: SBUIcons.error,
          text: strings.somethingWentWrong,
          retryText: strings.retry,
          onRetryButtonClicked: () {
            _init();
          },
        ),
      );
    }

    if (collectionNo == null) {
      return widget.getDefaultContainer(isLightTheme);
    }

    final collection = collectionProvider.getCollection(collectionNo!);
    final isScrollToEnd = collectionProvider.isScrollToEnd(collectionNo!);
    final isDeletedChannel = collectionProvider.isDeletedChannel(collectionNo!);

    if (isScrollToEnd) {
      collectionProvider.resetScrollToEnd(collectionNo!);

      if (collection != null) {
        _scrollToBottom(collection);
      }
    }

    if (isDeletedChannel) {
      collectionProvider.resetDeletedChannel(collectionNo!);
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (collection != null) {
          if (widget.onChannelDeleted != null) {
            widget.onChannelDeleted!(collection.channel);
          }
        }
      });
    }

    if (collection != null) {
      if (collectionProvider
          .getCheckUnreadBadge(collection.channel.channelUrl)) {
        collectionProvider.setCheckUnreadBadge(collection.channel.channelUrl);
        if (!_streamController.isClosed) {
          _streamController.add(collection);
        }
      }
    }

    final header = collection != null
        ? SBUHeaderComponent(
            width: double.maxFinite,
            height: 56,
            backgroundColor:
                isLightTheme ? SBUColors.background50 : SBUColors.background500,
            title: SBUTextComponent(
              text: widget.getGroupChannelName(collection.channel, strings),
              textType: SBUTextType.heading2,
              textColorType: SBUTextColorType.text01,
            ),
            hasBackKey: Navigator.of(context).canPop(),
            avatar: widget.getGroupChannelAvatarComponent(
              isLightTheme: isLightTheme,
              size: 34,
              channel: collection.channel,
            ),
            iconButton: widget.onInfoButtonClicked != null
                ? SBUIconButtonComponent(
                    iconButtonSize: 32,
                    icon: SBUIconComponent(
                      iconSize: 24,
                      iconData: SBUIcons.info,
                      iconColor: isLightTheme
                          ? SBUColors.primaryMain
                          : SBUColors.primaryLight,
                    ),
                    onButtonClicked: () {
                      widget.unfocus();
                      if (widget.onInfoButtonClicked != null) {
                        widget.onInfoButtonClicked!(collectionNo!);
                      }
                    },
                  )
                : null,
            channelForTypingStatus: collection.channel,
          )
        : null;

    final list = collection != null && collection.messageList.isNotEmpty
        ? NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent -
                      widget.scrollExtentToTriggerPreloading) {
                _loadPrevious(collection);
              }

              final isBottomOfScreen = (scrollController.offset == 0);
              _checkScroll(collection, isBottomOfScreen);
              return false;
            },
            child: SBUScrollBarComponent(
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                reverse: true,
                shrinkWrap: false,
                itemCount: collection.messageList.length,
                cacheExtent: widget.cacheExtent,
                itemBuilder: (context, index) {
                  Widget listItem = AutoScrollTag(
                    key: ValueKey(index),
                    controller: scrollController,
                    index: index,
                    child: SBUMessageListItemComponent(
                      messageCollectionNo: collectionNo!,
                      messageList: collection.messageList,
                      messageIndex: index,
                      on1On1ChannelCreated: widget.on1On1ChannelCreated,
                      onListItemClicked: widget.onListItemClicked,
                      onListItemWithIndexClicked:
                          widget.onListItemWithIndexClicked,
                      onParentMessageClicked: (parentMessage) async {
                        if (isClickedParentMessageAnimating) {
                          return;
                        }

                        int? foundIndex;
                        for (int index = 0;
                            index < collection.messageList.length;
                            index++) {
                          if (collection.messageList[index].messageId ==
                              parentMessage.messageId) {
                            foundIndex = index;
                            break;
                          }
                        }

                        if (foundIndex != null) {
                          await _scrollToIndex(collection, foundIndex);

                          if (mounted) {
                            setState(() {
                              clickedParentMessageIndex = foundIndex;
                              isClickedParentMessageAnimating = true;
                            });
                          }

                          for (int i = _animationShakingCount; i > 0; i--) {
                            await _animationController.forward();
                            await _animationController.reverse();
                          }

                          clickedParentMessageIndex = null;
                          isClickedParentMessageAnimating = false;
                        }
                      },
                      key: Key(widget.getMessageCacheKey(
                              collection.messageList[index]) ??
                          ''),
                    ),
                  );

                  Widget? animationListItem;
                  if (index == clickedParentMessageIndex) {
                    animationListItem = AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                              0, _animationGap * (_animationController.value)),
                          child: listItem,
                        );
                      },
                    );
                  }

                  final itemWidget = widget.customListItem != null
                      ? widget.customListItem!(
                          context,
                          theme,
                          strings,
                          collection,
                          index,
                          collection.messageList[index],
                        )
                      : (animationListItem ?? listItem);

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      _itemContexts.insert(
                        index,
                        ItemContext(index: index, context: context),
                      );
                      return itemWidget;
                    },
                  );
                },
              ),
            ),
          )
        : null;

    final body = collection == null
        ? widget.getDefaultContainer(isLightTheme)
        : isLoading && collection.messageList.isEmpty
            ? (widget.customLoadingBody != null
                ? widget.customLoadingBody!(
                    context,
                    theme,
                    strings,
                    collection,
                  )
                : widget.getDefaultContainer(
                    isLightTheme,
                    child: Center(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          color: isLightTheme
                              ? SBUColors.primaryMain
                              : SBUColors.primaryLight,
                          strokeWidth: 5.5,
                        ),
                      ),
                    ),
                  ))
            : (collection.messageList.isEmpty
                ? (widget.customEmptyBody != null
                    ? widget.getDefaultContainer(
                        isLightTheme,
                        child: widget.customEmptyBody!(
                          context,
                          theme,
                          strings,
                          collection,
                        ),
                      )
                    : widget.getDefaultContainer(
                        isLightTheme,
                        child: SBUPlaceholderComponent(
                          isLightTheme: isLightTheme,
                          iconData: SBUIcons.message,
                          text: strings.noMessages,
                        ),
                      ))
                : list ?? widget.getDefaultContainer(isLightTheme));

    final messageInput = collection != null
        ? SBUMessageInputComponent(
            messageCollectionNo: collectionNo!,
            backgroundColor:
                isLightTheme ? SBUColors.background50 : SBUColors.background600,
          )
        : null;

    final isFrozenChannel = collection?.channel.isFrozen ?? false;
    final unreadMessageCount = collection?.channel.unreadMessageCount ?? 0;
    final newMessageCount = (collection?.channel.channelUrl != null)
        ? collectionProvider.getNewMessageCount(collection!.channel.channelUrl)
        : 0;

    double bottomButtonsMargin = 68;
    if (collectionProvider.getReplyingToMessage(collectionNo!) != null) {
      bottomButtonsMargin += 46;
    } else if (collectionProvider.getEditingMessage(collectionNo!) != null) {
      bottomButtonsMargin += 40;
    }

    return Stack(children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          collection == null
              ? widget.getDefaultContainer(isLightTheme)
              : widget.customHeader != null
                  ? widget.customHeader!(
                      context,
                      theme,
                      strings,
                      collection,
                    )
                  : header ??
                      Container(
                        color: isLightTheme
                            ? SBUColors.background50
                            : SBUColors.background500,
                      ),
          Expanded(
            child: Container(
              color: isLightTheme
                  ? SBUColors.background50
                  : SBUColors.background600,
              alignment: Alignment.bottomCenter,
              child: body,
            ),
          ),
          collection == null
              ? widget.getDefaultContainer(isLightTheme)
              : widget.customMessageInput != null
                  ? widget.customMessageInput!(
                      context,
                      theme,
                      strings,
                      collection,
                    )
                  : messageInput ?? widget.getDefaultContainer(isLightTheme),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isFrozenChannel)
            collection == null
                ? widget.getDefaultContainer(isLightTheme)
                : widget.customFrozenChannel != null
                    ? widget.customFrozenChannel!(
                        context,
                        theme,
                        strings,
                        collection,
                      )
                    : Container(
                        width: double.maxFinite,
                        height: 24,
                        margin:
                            const EdgeInsets.only(left: 8, top: 64, right: 8),
                        decoration: BoxDecoration(
                          color: SBUColors.informationLight,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4)),
                        ),
                        child: Center(
                          child: SBUTextComponent(
                            text: strings.channelIsFrozen,
                            textType: SBUTextType.caption2,
                            textColorType: SBUTextColorType.information,
                          ),
                        ),
                      ),
          if (_showUnreadBadge && unreadMessageCount > 0)
            Column(
              children: [
                const SizedBox(width: double.maxFinite),
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Container(
                      height: 38,
                      margin: EdgeInsets.only(
                          left: 8, top: isFrozenChannel ? 8 : 64, right: 8),
                      child: Container(
                        padding: const EdgeInsets.only(left: 16, right: 12),
                        decoration: BoxDecoration(
                          color: isLightTheme
                              ? SBUColors.background50
                              : SBUColors.background400,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(20)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 3,
                              offset: const Offset(0, 0),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 5,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: SBUTextComponent(
                                text: strings.unreadMessageCount(
                                    unreadMessageCount.toString()),
                                textType: SBUTextType.body2,
                                textColorType: SBUTextColorType.text02,
                              ),
                            ),
                            SBUIconButtonComponent(
                              iconButtonSize: 14,
                              icon: SBUIconComponent(
                                iconSize: 14,
                                iconData: SBUIcons.close,
                                iconColor: isLightTheme
                                    ? SBUColors.primaryMain
                                    : SBUColors.primaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (collection != null) {
                          _checkToMarkAsReadOrUnread(collection, force: true);
                        }
                      },
                      child: Container(
                        width: 34,
                        height: 38,
                        alignment: Alignment.centerRight,
                        margin: EdgeInsets.only(
                            left: 8, top: isFrozenChannel ? 8 : 64, right: 8),
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
      if (newMessageCount > 0)
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(child: SizedBox(width: double.maxFinite)),
            Container(
              height: 38,
              margin: EdgeInsets.only(
                  left: 58, bottom: bottomButtonsMargin, right: 58),
              child: GestureDetector(
                onTap: () async {
                  if (collection != null) {
                    await _scrollToBottom(collection);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  decoration: BoxDecoration(
                    color: isLightTheme
                        ? SBUColors.background50
                        : SBUColors.background400,
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 3,
                        offset: const Offset(0, 0),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: SBUTextComponent(
                          text: strings
                              .newMessageCount(newMessageCount.toString()),
                          textType: SBUTextType.body2,
                          textColorType: SBUTextColorType.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      if (_showMoveToBottomButton)
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(child: SizedBox(width: double.maxFinite)),
            Container(
              width: 38,
              height: 38,
              margin: EdgeInsets.only(
                  left: 8, bottom: bottomButtonsMargin, right: 12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLightTheme
                      ? SBUColors.background50
                      : SBUColors.background400,
                  borderRadius: const BorderRadius.all(Radius.circular(19)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 3,
                      offset: const Offset(0, 0),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: SBUIconButtonComponent(
                  iconButtonSize: 22,
                  icon: SBUIconComponent(
                    iconSize: 22,
                    iconData: SBUIcons.chevronDown,
                    iconColor: isLightTheme
                        ? SBUColors.primaryMain
                        : SBUColors.primaryLight,
                  ),
                  onButtonClicked: () async {
                    if (collection != null) {
                      await _scrollToBottom(collection);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
    ]);
  }

  Future<void> _scrollToBottom(MessageCollection collection) async {
    await _scrollToIndex(collection, 0);
  }

  Future<void> _scrollToIndex(MessageCollection collection, int index) async {
    await scrollController.scrollToIndex(index);

    bool isBottomOfScreen = true;
    try {
      isBottomOfScreen = (scrollController.offset == 0); // Check
    } catch (_) {
      isBottomOfScreen = true;
    }

    _checkScroll(collection, isBottomOfScreen);
  }

  void _checkScroll(MessageCollection collection, bool isBottomOfScreen) {
    SBUMessageCollectionProvider().setBottomOfScreen(
      collection.channel.channelUrl,
      isBottomOfScreen,
    );

    // final isNewLineVisible = _isNewLineInViewPort(collection);
    // if (_isNewLineVisible == null || _isNewLineVisible != isNewLineVisible) {
    // _isNewLineVisible = isNewLineVisible;

    if (!_streamController.isClosed) {
      _streamController.add(collection);
    }
    // }

    if (_showMoveToBottomButton) {
      if (isBottomOfScreen) {
        SBUMessageCollectionProvider()
            .checkToMarkAsRead(collection.channel); // Check

        if (mounted) {
          setState(() {
            _showMoveToBottomButton = false;
          });
        }
      }
    } else {
      if (!isBottomOfScreen) {
        if (mounted) {
          setState(() {
            _showMoveToBottomButton = true;
          });
        }
      }
    }
  }

  bool _isNewLineInViewPort(MessageCollection collection) {
    for (int i = 0; i < _itemContexts.length; i++) {
      final item = _itemContexts[i];

      final hasNewLine = SBUMarkAsUnreadManager().hasNewMessageLine(
        collection: collection,
        messageList: collection.messageList,
        messageIndex: item.index,
      );
      final isVisible = item.isVisible(
        collection: collection,
        hasNewLine: hasNewLine,
      );

      if (hasNewLine && isVisible) {
        return true;
      }
    }
    return false;
  }

  void _checkNewLine(MessageCollection collection) {
    if (!SBUMarkAsUnreadManager().isOn()) {
      return;
    }

    final isNewLineVisible = _isNewLineInViewPort(collection);
    if (isNewLineVisible) {
      _checkToMarkAsReadOrUnread(collection);
    }

    final showUnreadBadge = (_isNewLineExistsInChannel(collection) &&
        isNewLineVisible == false &&
        collection.channel.unreadMessageCount > 0 &&
        (_canShowUnreadBadge ||
            SBUMessageCollectionProvider()
                .didMarkAsUnread(collection.channel.channelUrl)));

    if (showUnreadBadge) {
      SBUMessageCollectionProvider()
          .setFreezeMyLastRead(collection.channel.channelUrl, true);
    } else {
      _canShowUnreadBadge = false; // Check
    }

    if (showUnreadBadge != _showUnreadBadge) {
      if (mounted) {
        setState(() {
          _showUnreadBadge = showUnreadBadge;
        });
      }
    }
  }

  void _checkToMarkAsReadOrUnread(
    MessageCollection collection, {
    bool force = false,
  }) {
    if (!force) {
      final didMarkAsUnread = SBUMessageCollectionProvider()
          .didMarkAsUnread(collection.channel.channelUrl);
      final hasSeenNewMessageLine = SBUMessageCollectionProvider()
          .hasSeenNewMessageLine(collection.channel.channelUrl);
      if (didMarkAsUnread || hasSeenNewMessageLine) {
        return;
      }
    }

    final isBottom = SBUMessageCollectionProvider()
        .isBottomOfScreen(collection.channel.channelUrl);
    if (!force && !isBottom) {
      final newMessageCount = SBUMessageCollectionProvider()
          .getNewMessageCount(collection.channel.channelUrl);

      if (newMessageCount > 0 &&
          newMessageCount <= collection.messageList.length) {
        final message = collection.messageList[newMessageCount - 1];
        SBUMarkAsUnreadManager().markAsUnread(collection.channel, message);
        return;
      }
    }

    SBUMessageCollectionProvider()
        .setHasSeenNewMessageLine(collection.channel.channelUrl, true); // Check
    SBUMessageCollectionProvider()
        .setFreezeMyLastRead(collection.channel.channelUrl, true);

    runZonedGuarded(() {
      collection.channel.markAsRead(); // No await
    }, (error, stack) {
      // Check
    });
  }
}

class ItemContext {
  ItemContext({
    required this.index,
    required this.context,
  });

  final int index;
  final BuildContext context;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ItemContext && other.index == index;
  }

  @override
  int get hashCode => Object.hashAll([index]);

  bool isVisible({
    required MessageCollection collection,
    required bool hasNewLine,
  }) {
    if (!context.mounted) {
      return false;
    }

    final RenderObject? object = context.findRenderObject();
    if (object == null || !object.attached) {
      return false;
    }

    final RenderAbstractViewport viewport = RenderAbstractViewport.of(object);
    final double vpHeight = viewport.paintBounds.height;
    final ScrollableState scrollableState = Scrollable.of(context);
    final ScrollPosition scrollPosition = scrollableState.position;
    final RevealedOffset vpOffset = viewport.getOffsetToReveal(object, 0.0);

    final Size size = object.semanticBounds.size;

    final double deltaTop = vpOffset.offset - scrollPosition.pixels;
    final double deltaBottom = hasNewLine
        ? deltaTop + size.height - 20
        : deltaTop + size.height; // Check

    final isVisible = (deltaBottom > (hasNewLine ? -10 : 0.0) &&
        deltaBottom <= vpHeight); // Check
    return isVisible;
  }
}

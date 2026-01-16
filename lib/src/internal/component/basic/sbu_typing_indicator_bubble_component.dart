// Copyright (c) 2026 Sendbird, Inc. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_component.dart';
import 'package:sendbird_uikit/src/internal/resource/sbu_text_styles.dart';

class SBUTypingIndicatorBubbleComponent extends SBUStatefulComponent {
  final List<User> typingUsers;

  const SBUTypingIndicatorBubbleComponent({
    required this.typingUsers,
    super.key,
  });

  @override
  State<StatefulWidget> createState() =>
      SBUTypingIndicatorBubbleComponentState();
}

class SBUTypingIndicatorBubbleComponentState
    extends State<SBUTypingIndicatorBubbleComponent>
    with TickerProviderStateMixin, SBUBaseComponent {
  late AnimationController _animationController;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _opacityAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();

    // Scale animations based on the guide (1.4s total duration)
    // Each dot: 0.2s scale up (100% -> 150%), 0.2s hold, 0.2s scale down (150% -> 100%)
    // First dot starts at 0.4s, Second at 0.6s, Third at 0.8s
    _scaleAnimations = [
      // First dot: starts at 0.4s (0.285 of 1.4s)
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.5)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 33.3, // 0.2s of 0.6s total animation
        ),
        TweenSequenceItem(
          tween: ConstantTween<double>(1.5),
          weight: 33.3, // 0.2s hold at 150%
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.5, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 33.4, // 0.2s scale down
        ),
      ]).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.285, 0.714), // 0.4s to 1.0s (0.6s duration)
        ),
      ),
      // Second dot: starts at 0.6s (0.428 of 1.4s)
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.5)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 33.3,
        ),
        TweenSequenceItem(
          tween: ConstantTween<double>(1.5),
          weight: 33.3,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.5, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 33.4,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.428, 0.857), // 0.6s to 1.2s
        ),
      ),
      // Third dot: starts at 0.8s (0.571 of 1.4s)
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.5)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 33.3,
        ),
        TweenSequenceItem(
          tween: ConstantTween<double>(1.5),
          weight: 33.3,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.5, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 33.4,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.571, 1.0), // 0.8s to 1.4s
        ),
      ),
    ];

    // Opacity animations - same timing as scale animations
    // 12% -> 38% -> 12%
    _opacityAnimations = [
      // First dot: 0.4s to 1.0s
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.12, end: 0.38)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 33.3,
        ),
        TweenSequenceItem(
          tween: ConstantTween<double>(0.38),
          weight: 33.3,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.38, end: 0.12)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 33.4,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.285, 0.714),
        ),
      ),
      // Second dot: 0.6s to 1.2s
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.12, end: 0.38)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 33.3,
        ),
        TweenSequenceItem(
          tween: ConstantTween<double>(0.38),
          weight: 33.3,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.38, end: 0.12)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 33.4,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.428, 0.857),
        ),
      ),
      // Third dot: 0.8s to 1.4s
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.12, end: 0.38)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 33.3,
        ),
        TweenSequenceItem(
          tween: ConstantTween<double>(0.38),
          weight: 33.3,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.38, end: 0.12)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 33.4,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.571, 1.0),
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.watch<SBUThemeProvider>().isLight();
    const maxAvatars = 4;
    final displayUsers = widget.typingUsers.take(maxAvatars).toList();
    final totalTypingUsers = widget.typingUsers.length;
    final hasMore = totalTypingUsers > maxAvatars;
    int displayCount = hasMore ? maxAvatars - 1 : displayUsers.length;
    // if (maxAvatars == 1 && displayCount == 0) {
    //   // Ensure at least one avatar is displayed when maxAvatars is 1.
    //   displayCount = 1;
    // }

    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 16, bottom: 16),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: SizedBox(
              width: // 30, 52, 74, ...
                  hasMore
                      ? 2 + (maxAvatars * 22) + 26 + 2
                      : 2 + ((displayCount - 1) * 22) + 26 + 2,
              height: 30,
              child: Stack(
                children: [
                  for (int i = 0; i < displayCount; i++)
                    Positioned(
                      left: i * 22,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (i > 0)
                              ? (isLightTheme
                                  ? SBUColors.background100
                                  : SBUColors.background400)
                              : null,
                          border: Border.all(
                            color: isLightTheme
                                ? SBUColors.background50
                                : SBUColors.background600,
                            width: 2,
                          ),
                        ),
                        child: getAvatarComponent(
                          isLightTheme: isLightTheme,
                          size: 26,
                          user: displayUsers[i],
                        ),
                      ),
                    ),
                  if (hasMore)
                    Positioned(
                      left: displayCount * 22,
                      child: Center(
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLightTheme
                                ? SBUColors.background100
                                : SBUColors.background400,
                            border: Border.all(
                              color: isLightTheme
                                  ? SBUColors.background50
                                  : SBUColors.background600,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: SBUTextComponent(
                              text: (totalTypingUsers >= displayCount + 99)
                                  ? '+99'
                                  : '+${totalTypingUsers - displayCount}',
                              textType: SBUTextType.caption3,
                              textColorType: SBUTextColorType.text02,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            width: 60,
            height: 34,
            decoration: BoxDecoration(
              color: isLightTheme
                  ? SBUColors.background100
                  : SBUColors.background400,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < 3; i++)
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _scaleAnimations[i],
                      _opacityAnimations[i],
                    ]),
                    builder: (context, child) {
                      // Scale oscillates between 1.0 and 1.5
                      final scale = _scaleAnimations[i].value;
                      // Opacity oscillates
                      final opacity = _opacityAnimations[i].value;

                      return Container(
                        margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                        width: 8 * scale,
                        height: 8 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLightTheme
                              ? Colors.black.withValues(alpha: opacity)
                              : Colors.white.withValues(alpha: opacity),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

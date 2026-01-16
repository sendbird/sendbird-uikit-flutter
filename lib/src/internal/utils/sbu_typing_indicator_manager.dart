// Copyright (c) 2026 Sendbird, Inc. All rights reserved.

import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_configuration_manager.dart';

class SBUTypingIndicatorManager {
  SBUTypingIndicatorManager._();

  static final SBUTypingIndicatorManager _instance =
      SBUTypingIndicatorManager._();

  factory SBUTypingIndicatorManager() => _instance;

  bool? useChannelListTypingIndicator;
  bool? useChannelTypingIndicator;
  SBUTypingIndicatorType? channelTypingIndicatorType;

  bool isChannelListTypingIndicatorOn() {
    final isChannelListTypingIndicatorEnabledOnDashboard =
        SBUConfigurationManager()
            .isChannelListTypingIndicatorEnabledOnDashboard();

    if (useChannelListTypingIndicator != null) {
      return useChannelListTypingIndicator!;
    } else if (isChannelListTypingIndicatorEnabledOnDashboard != null) {
      return isChannelListTypingIndicatorEnabledOnDashboard;
    }
    return true;
  }

  bool isChannelTypingIndicatorOn() {
    final isChannelTypingIndicatorEnabledOnDashboard =
        SBUConfigurationManager().isChannelTypingIndicatorEnabledOnDashboard();

    if (useChannelTypingIndicator != null) {
      return useChannelTypingIndicator!;
    } else if (isChannelTypingIndicatorEnabledOnDashboard != null) {
      return isChannelTypingIndicatorEnabledOnDashboard;
    }
    return true;
  }

  SBUTypingIndicatorType getChannelTypingIndicatorType() {
    if (channelTypingIndicatorType != null) {
      return channelTypingIndicatorType!;
    }
    return SBUTypingIndicatorType.text;
  }
}

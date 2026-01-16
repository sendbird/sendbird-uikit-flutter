// Copyright (c) 2025 Sendbird, Inc. All rights reserved.

import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_preferences.dart';

class SBUConfigurationManager {
  SBUConfigurationManager._();

  static final SBUConfigurationManager _instance = SBUConfigurationManager._();

  factory SBUConfigurationManager() => _instance;

  static String enableMarkAsUnreadKey =
      'group_channel-channel-enable_mark_as_unread';
  static String enableChannelListTypingIndicatorKey =
      'group_channel-channel_list-enable_typing_indicator';
  static String enableChannelTypingIndicatorKey =
      'group_channel-channel-enable_typing_indicator';

  Future<void> checkConfiguration() async {
    final cachedLastUpdatedAt =
        SBUPreferences().getConfigurationLastUpdatedAt();
    final lastUpdatedAt =
        SendbirdChat.getAppInfo()?.uikitConfigInfo?.lastUpdatedAt;

    if (lastUpdatedAt != null && lastUpdatedAt > cachedLastUpdatedAt) {
      try {
        final uikitConfiguration = await SendbirdChat.getUIKitConfiguration();
        if (uikitConfiguration != null) {
          Map<String, bool> configurations = {};

          // TODO: Other configurations can be added here as needed
          bool? enableMarkAsUnread = uikitConfiguration['configuration']
              ['group_channel']['channel']['enable_mark_as_unread'];
          if (enableMarkAsUnread != null) {
            configurations[enableMarkAsUnreadKey] = enableMarkAsUnread;
          }

          bool? enableChannelListTypingIndicator =
              uikitConfiguration['configuration']['group_channel']
                  ['channel_list']['enable_typing_indicator'];
          if (enableChannelListTypingIndicator != null) {
            configurations[enableChannelListTypingIndicatorKey] =
                enableChannelListTypingIndicator;
          }

          bool? enableChannelTypingIndicator =
              uikitConfiguration['configuration']['group_channel']['channel']
                  ['enable_typing_indicator'];
          if (enableChannelTypingIndicator != null) {
            configurations[enableChannelTypingIndicatorKey] =
                enableChannelTypingIndicator;
          }

          final configurationCaches =
              await SBUPreferences().setConfigurationCaches(configurations);
          if (configurationCaches != null) {
            await SBUPreferences().setConfigurationLastUpdatedAt(lastUpdatedAt);
          }
        }
      } catch (_) {
        // Check
      }
    }
  }

  bool? isMarkAsUnreadEnabledOnDashboard() {
    return SBUPreferences().getConfigurationCache(enableMarkAsUnreadKey);
  }

  bool? isChannelListTypingIndicatorEnabledOnDashboard() {
    return SBUPreferences()
        .getConfigurationCache(enableChannelListTypingIndicatorKey);
  }

  bool? isChannelTypingIndicatorEnabledOnDashboard() {
    return SBUPreferences()
        .getConfigurationCache(enableChannelTypingIndicatorKey);
  }
}

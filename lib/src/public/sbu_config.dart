// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

/// SBUReplyType
enum SBUReplyType {
  /// Do not display replies in the message list.
  none,

  /// Displays replies linearly in the message list.
  quoteReply,
}

/// SBUTypingIndicatorType
enum SBUTypingIndicatorType {
  /// Displays typing status as text in the header.
  text,

  /// Displays typing status as an animated bubble in the message list.
  bubble,
}

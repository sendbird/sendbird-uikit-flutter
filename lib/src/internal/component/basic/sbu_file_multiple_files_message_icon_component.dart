// Copyright (c) 2025 Sendbird, Inc. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_file_icon_component.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_thumbnail_manager.dart';
import 'package:sendbird_uikit/src/public/resource/sbu_colors.dart';
import 'package:sendbird_uikit/src/public/resource/sbu_icons.dart';
import 'package:sendbird_uikit/src/public/resource/sbu_theme_provider.dart';

class SBUMultipleFilesMessageIconComponent extends SBUStatefulComponent {
  final double iconSize;
  final MultipleFilesMessage multipleFilesMessage;

  const SBUMultipleFilesMessageIconComponent({
    required this.iconSize,
    required this.multipleFilesMessage,
    super.key,
  });

  @override
  State<StatefulWidget> createState() =>
      SBUMultipleFilesMessageIconComponentState();
}

class SBUMultipleFilesMessageIconComponentState
    extends State<SBUMultipleFilesMessageIconComponent> {
  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.watch<SBUThemeProvider>().isLight();

    final iconSize = widget.iconSize;
    final multipleFilesMessage = widget.multipleFilesMessage;

    if (multipleFilesMessage.files.isEmpty) {
      return Container();
    }

    const index = 0;
    final fileType = widget.getFileType(multipleFilesMessage.files[index].type);

    switch (fileType) {
      case SBUFileType.image:
      case SBUFileType.video:
        final isReplyMessageToChannel =
            widget.isReplyMessageToChannel(multipleFilesMessage);

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: iconSize,
            height: iconSize,
            child: SBUThumbnailManager().getThumbnailWidget(
                  isSucceededMessage: multipleFilesMessage.sendingStatus ==
                      SendingStatus.succeeded,
                  requestId: multipleFilesMessage.requestId,
                  messageId: multipleFilesMessage.messageId,
                  multipleFileIndex: null,
                  thumbnails: multipleFilesMessage.files[index].thumbnails,
                  mimeType: multipleFilesMessage.files[index].type,
                  secureUrl: multipleFilesMessage.files[index].secureUrl,
                  filePath: multipleFilesMessage.files[index].file?.path,
                  fileType: fileType,
                  isLightTheme: isLightTheme,
                  addGifIcon: false,
                  isParentMessage: isReplyMessageToChannel,
                ) ??
                Container(), // Check
          ),
        );
      case SBUFileType.other:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: iconSize,
            height: iconSize,
            child: SBUFileIconComponent(
              size: iconSize,
              backgroundColor: isLightTheme
                  ? SBUColors.background200
                  : SBUColors.background500,
              iconSize: 20,
              iconData: SBUIcons.fileDocument,
              iconColor: isLightTheme
                  ? SBUColors.lightThemeTextMidEmphasis
                  : SBUColors.darkThemeTextMidEmphasis,
            ), // Check
          ),
        );
    }
  }
}

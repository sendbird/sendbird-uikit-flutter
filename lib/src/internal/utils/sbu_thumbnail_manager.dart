// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:gif/gif.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_icon_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_image_component.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_preferences.dart';
import 'package:sendbird_uikit/src/internal/utils/sbu_thumbnail_cache.dart';
import 'package:sendbird_uikit/src/public/resource/sbu_colors.dart';
import 'package:sendbird_uikit/src/public/resource/sbu_icons.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class SBUThumbnailManager {
  SBUThumbnailManager._();

  static final SBUThumbnailManager _instance = SBUThumbnailManager._();

  factory SBUThumbnailManager() => _instance;

  List<String> completerKeys = [];
  Map<String, List<Completer<Widget?>>> completerMap = {};

  static String? getCacheKey({
    required bool isSucceededMessage,
    required String? requestId,
    required int messageId,
    required int? multipleFileIndex,
  }) {
    String? cacheKey;
    if (isSucceededMessage && messageId > 0) {
      cacheKey = messageId.toString();
    } else if (requestId != null && requestId.isNotEmpty) {
      cacheKey = requestId;
    }

    if (cacheKey != null && multipleFileIndex != null) {
      cacheKey = '${cacheKey}_$multipleFileIndex';
    }
    return cacheKey;
  }

  bool _isGif(String? mimeType) {
    if (mimeType != null && mimeType == 'image/gif') {
      return true;
    }
    return false;
  }

  Widget? getThumbnailWidget({
    required bool isSucceededMessage,
    required String? requestId,
    required int messageId,
    required int? multipleFileIndex,
    required List<Thumbnail>? thumbnails,
    required String? mimeType,
    required String secureUrl,
    required String? filePath,
    required SBUFileType fileType,
    required bool isLightTheme,
    required bool addGifIcon,
    required bool isParentMessage,
  }) {
    String? thumbnailUrl;
    if (thumbnails?.isNotEmpty ?? false) {
      final thumbnail = thumbnails!.first;
      if (thumbnail.secureUrl.isNotEmpty) {
        thumbnailUrl = thumbnail.secureUrl;
      }
    }

    final isGif = _isGif(mimeType);

    if (fileType == SBUFileType.image) {
      Widget? thumbnailWidget = _getThumbnail(
        isSucceededMessage: isSucceededMessage,
        requestId: requestId,
        messageId: messageId,
        multipleFileIndex: multipleFileIndex,
        mimeType: mimeType,
        fileType: fileType,
        filePath: filePath,
      );

      final size = isParentMessage || multipleFileIndex != null ? 31.2 : 48.0;
      final iconSize =
          isParentMessage || multipleFileIndex != null ? 18.2 : 28.0;

      if (thumbnailWidget == null) {
        if (isGif && thumbnailUrl == null && secureUrl.isNotEmpty) {
          Widget? gifWidget;
          runZonedGuarded(() {
            final gif = Gif(
              image: NetworkImage(secureUrl),
              autostart: Autostart.no,
              fit: BoxFit.cover,
              useCache: true,
            );

            if (addGifIcon) {
              gifWidget = _getGifWidget(
                thumbnailWidget: gif,
                size: size,
                iconSize: iconSize,
              );
            } else {
              gifWidget = gif;
            }
          }, (e, s) {
            // Check
          });
          return gifWidget;
        } else {
          thumbnailWidget = SBUImageComponent(
            imageUrl: thumbnailUrl ?? secureUrl,
            cacheKey: getCacheKey(
              isSucceededMessage: isSucceededMessage,
              requestId: requestId,
              messageId: messageId,
              multipleFileIndex: multipleFileIndex,
            ),
            errorWidget: isGif
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: SBUColors.darkThemeTextHighEmphasis,
                          borderRadius: BorderRadius.circular(size),
                        ),
                      ),
                      SBUIconComponent(
                        iconSize: iconSize,
                        iconData: SBUIcons.gif,
                        iconColor: SBUColors.lightThemeTextMidEmphasis,
                      ),
                    ],
                  )
                : SBUIconComponent(
                    iconSize: size,
                    iconData: SBUIcons.photo,
                    iconColor: isLightTheme
                        ? SBUColors.lightThemeTextMidEmphasis
                        : SBUColors.darkThemeTextMidEmphasis,
                  ),
          );
        }
      }

      if (isGif) {
        return _getGifWidget(
          thumbnailWidget: thumbnailWidget,
          size: size,
          iconSize: iconSize,
        );
      } else {
        return thumbnailWidget;
      }
    } else if (fileType == SBUFileType.video) {
      if (kIsWeb) {
        return null;
      }

      final widget = _getThumbnail(
        isSucceededMessage: isSucceededMessage,
        requestId: requestId,
        messageId: messageId,
        multipleFileIndex: multipleFileIndex,
        mimeType: mimeType,
        fileType: fileType,
        filePath: filePath,
      );
      if (widget != null) {
        return widget;
      }

      if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
        return SBUImageComponent(
          imageUrl: thumbnailUrl,
          cacheKey: getCacheKey(
            isSucceededMessage: isSucceededMessage,
            requestId: requestId,
            messageId: messageId,
            multipleFileIndex: multipleFileIndex,
          ),
        );
      }

      return FutureBuilder<Widget?>(
        future: _getVideoThumbnail(
          isSucceededMessage: isSucceededMessage,
          requestId: requestId,
          messageId: messageId,
          multipleFileIndex: multipleFileIndex,
          filePath: filePath,
          secureUrl: secureUrl,
        ),
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return Container(); // Check
          } else if (snapshot.hasData && snapshot.data != null) {
            final widget = snapshot.data!;
            return widget;
          } else if (snapshot.hasError) {
            return Container(); // Check
          } else {
            return Container(); // Check
          }
        },
      );
    }
    return null;
  }

  Widget _getGifWidget({
    required Widget thumbnailWidget,
    required double size,
    required double iconSize,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        thumbnailWidget,
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: SBUColors.darkThemeTextHighEmphasis,
            borderRadius: BorderRadius.circular(size),
          ),
        ),
        SBUIconComponent(
          iconSize: iconSize,
          iconData: SBUIcons.gif,
          iconColor: SBUColors.lightThemeTextMidEmphasis,
        ),
      ],
    );
  }

  Widget? _getThumbnail({
    required bool isSucceededMessage,
    required String? requestId,
    required int messageId,
    required int? multipleFileIndex,
    required String? mimeType,
    required SBUFileType fileType,
    required String? filePath,
  }) {
    SBUThumbnailCache? cache = SBUPreferences().getThumbnailCache(
      isSucceededMessage: isSucceededMessage,
      requestId: requestId,
      messageId: messageId,
      multipleFileIndex: multipleFileIndex,
    );

    if (cache == null && fileType == SBUFileType.image) {
      if (filePath != null && filePath.isNotEmpty) {
        SBUPreferences().addThumbnailCache(
          isSucceededMessage: isSucceededMessage,
          requestId: requestId,
          messageId: messageId,
          multipleFileIndex: multipleFileIndex,
          filePath: filePath,
        ); // No await
      }
    }

    if (cache != null && cache.path.isNotEmpty) {
      if (_isGif(mimeType)) {
        return Gif(
          image: FileImage(File(cache.path)),
          autostart: Autostart.no,
          fit: BoxFit.cover,
          useCache: true,
        );
      } else {
        return Image.file(
          File(cache.path),
          fit: BoxFit.cover,
        );
      }
    }
    return null;
  }

  Future<Widget?> _getVideoThumbnail({
    required bool isSucceededMessage,
    required String? requestId,
    required int messageId,
    required int? multipleFileIndex,
    required String? filePath,
    required String secureUrl,
  }) async {
    Widget? widget;
    String? videoPathOrUrl;

    if (filePath != null && filePath.isNotEmpty) {
      videoPathOrUrl = filePath;
    } else if (secureUrl.isNotEmpty) {
      videoPathOrUrl = secureUrl;
    }

    if (videoPathOrUrl != null && videoPathOrUrl.isNotEmpty) {
      final dir = await getTemporaryDirectory();
      final result = await _genVideoThumbnail(
        isSucceededMessage: isSucceededMessage,
        requestId: requestId,
        messageId: messageId,
        multipleFileIndex: multipleFileIndex,
        request: VideoThumbnailRequest(
          video: videoPathOrUrl,
          thumbnailPath: dir.path,
        ),
      );
      widget = result?.image;
    }

    if (widget != null) {
      await Future.delayed(const Duration(milliseconds: 1000)); // Anti-flicker
    }
    return widget;
  }

  Future<VideoThumbnailResult?> _genVideoThumbnail({
    required bool isSucceededMessage,
    required String? requestId,
    required int messageId,
    required int? multipleFileIndex,
    required VideoThumbnailRequest request,
  }) async {
    Uint8List? bytes;
    final completer = Completer<VideoThumbnailResult>();
    if (request.thumbnailPath != null) {
      var thumbnail = await VideoThumbnail.thumbnailFile(
        video: request.video,
        thumbnailPath: request.thumbnailPath,
        imageFormat: request.imageFormat ?? ImageFormat.PNG,
        maxHeight: request.maxHeight ?? 0,
        maxWidth: request.maxWidth ?? 0,
        timeMs: request.timeMs ?? 0,
        quality: request.quality ?? 10,
      );

      // Decode URL-encoded thumbnail path (for empty string)
      if (thumbnail != null) {
        thumbnail = Uri.decodeFull(thumbnail);
      }

      if (thumbnail != null) {
        await SBUPreferences().addThumbnailCache(
          isSucceededMessage: isSucceededMessage,
          requestId: requestId,
          messageId: messageId,
          multipleFileIndex: multipleFileIndex,
          filePath: thumbnail,
        );
        final file = File(thumbnail);
        bytes = await file.readAsBytes();
      }
    } else {
      bytes = await VideoThumbnail.thumbnailData(
        video: request.video,
        imageFormat: request.imageFormat ?? ImageFormat.PNG,
        maxHeight: request.maxHeight ?? 0,
        maxWidth: request.maxWidth ?? 0,
        timeMs: request.timeMs ?? 0,
        quality: request.quality ?? 10,
      );
    }

    if (bytes != null) {
      final imageDataSize = bytes.length;
      final image = Image.memory(bytes, fit: BoxFit.cover);
      image.image.resolve(ImageConfiguration.empty).addListener(
            ImageStreamListener(
              (ImageInfo info, bool synchronousCall) {
                completer.complete(
                  VideoThumbnailResult(
                    image: image,
                    dataSize: imageDataSize,
                    height: info.image.height,
                    width: info.image.width,
                  ),
                );
              },
              onError: completer.completeError,
            ),
          );
      return completer.future;
    }
    return null;
  }
}

class VideoThumbnailRequest {
  final String video;
  final String? thumbnailPath;
  final ImageFormat? imageFormat;
  final int? maxHeight;
  final int? maxWidth;
  final int? timeMs;
  final int? quality;

  const VideoThumbnailRequest({
    required this.video,
    this.thumbnailPath,
    this.imageFormat,
    this.maxHeight,
    this.maxWidth,
    this.timeMs,
    this.quality,
  });
}

class VideoThumbnailResult {
  final Image image;
  final int dataSize;
  final int height;
  final int width;

  const VideoThumbnailResult({
    required this.image,
    required this.dataSize,
    required this.height,
    required this.width,
  });
}

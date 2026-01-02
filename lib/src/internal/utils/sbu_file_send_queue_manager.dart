// Copyright (c) 2025 Sendbird, Inc. All rights reserved.

import 'dart:async';

import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';

class FileSendTask {
  final String channelUrl;
  final FileMessageCreateParams? fileParams;
  final MultipleFilesMessageCreateParams? multipleFilesParams;
  final FileMessageHandler? fileHandler;
  final MultipleFilesMessageHandler? multipleFilesHandler;
  final FileUploadHandler? fileUploadHandler;
  final Completer<void> completer;

  FileSendTask({
    required this.channelUrl,
    this.fileParams,
    this.multipleFilesParams,
    this.fileHandler,
    this.multipleFilesHandler,
    this.fileUploadHandler,
  }) : completer = Completer<void>();
}

class SBUFileSendQueueManager {
  SBUFileSendQueueManager._();

  static final SBUFileSendQueueManager _instance = SBUFileSendQueueManager._();

  factory SBUFileSendQueueManager() => _instance;

  final Map<String, List<FileSendTask>> _channelQueues = {};
  final Map<String, bool> _isProcessing = {};

  void addFileTask({
    required GroupChannel channel,
    required FileMessageCreateParams params,
    FileMessageHandler? handler,
  }) {
    final task = FileSendTask(
      channelUrl: channel.channelUrl,
      fileParams: params,
      fileHandler: handler,
    );

    _addTaskToQueue(channel.channelUrl, task);
    _processQueue(channel);
  }

  void addMultipleFilesTask({
    required GroupChannel channel,
    required MultipleFilesMessageCreateParams params,
    MultipleFilesMessageHandler? handler,
    FileUploadHandler? fileUploadHandler,
  }) {
    final task = FileSendTask(
      channelUrl: channel.channelUrl,
      multipleFilesParams: params,
      multipleFilesHandler: handler,
      fileUploadHandler: fileUploadHandler,
    );

    _addTaskToQueue(channel.channelUrl, task);
    _processQueue(channel);
  }

  void _addTaskToQueue(String channelUrl, FileSendTask task) {
    _channelQueues[channelUrl] ??= <FileSendTask>[];
    _channelQueues[channelUrl]!.add(task);
  }

  Future<void> _processQueue(GroupChannel channel) async {
    final channelUrl = channel.channelUrl;

    // If already processing this channel's queue, return
    if (_isProcessing[channelUrl] == true) {
      return;
    }

    _isProcessing[channelUrl] = true;

    try {
      while (_channelQueues[channelUrl] != null &&
          _channelQueues[channelUrl]!.isNotEmpty) {
        final task = _channelQueues[channelUrl]!.first;

        try {
          if (task.fileParams != null) {
            // Process single file message
            await _sendFileMessage(channel, task);
          } else if (task.multipleFilesParams != null) {
            // Process multiple files message
            await _sendMultipleFilesMessage(channel, task);
          }

          await Future.delayed(const Duration(milliseconds: 500));

          task.completer.complete();
        } catch (error) {
          task.completer.completeError(error);
        }

        if (_channelQueues[channelUrl] != null &&
            _channelQueues[channelUrl]!.isNotEmpty) {
          _channelQueues[channelUrl]!.removeAt(0);
        }
      }
    } finally {
      _isProcessing[channelUrl] = false;
    }
  }

  Future<void> _sendFileMessage(GroupChannel channel, FileSendTask task) async {
    final completer = Completer<void>();

    channel.sendFileMessage(
      task.fileParams!,
      handler: (message, error) {
        if (task.fileHandler != null) {
          task.fileHandler!(message, error);
        }
        if (error != null) {
          completer.completeError(error);
        } else {
          completer.complete();
        }
      },
    );

    await completer.future;
  }

  Future<void> _sendMultipleFilesMessage(
      GroupChannel channel, FileSendTask task) async {
    final completer = Completer<void>();

    channel.sendMultipleFilesMessage(
      task.multipleFilesParams!,
      handler: (message, error) {
        if (task.multipleFilesHandler != null) {
          task.multipleFilesHandler!(message, error);
        }
        if (error != null) {
          completer.completeError(error);
        } else {
          completer.complete();
        }
      },
      fileUploadHandler: task.fileUploadHandler,
    );

    await completer.future;
  }

  void clearQueue(String channelUrl) {
    _channelQueues.remove(channelUrl);
    _isProcessing.remove(channelUrl);
  }

  void clearAllQueues() {
    _channelQueues.clear();
    _isProcessing.clear();
  }
}

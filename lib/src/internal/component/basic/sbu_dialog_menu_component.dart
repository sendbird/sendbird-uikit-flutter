// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_button_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_component.dart';
import 'package:sendbird_uikit/src/internal/resource/sbu_text_styles.dart';

class SBUDialogMenuComponent extends SBUStatefulComponent {
  final String title;
  final List<String> buttonNames;
  final void Function(String buttonName) onButtonClicked;
  final bool isYesOrNo;
  final int? errorColorIndex;
  final int maxLines;

  const SBUDialogMenuComponent({
    required this.title,
    required this.buttonNames,
    required this.onButtonClicked,
    this.isYesOrNo = false,
    this.errorColorIndex,
    this.maxLines = 1,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => SBUDialogMenuComponentState();
}

class SBUDialogMenuComponentState extends State<SBUDialogMenuComponent> {
  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.watch<SBUThemeProvider>().isLight();

    final title = widget.title;
    final buttonNames = widget.buttonNames;
    final onButtonClicked = widget.onButtonClicked;
    final isYesOrNo = widget.isYesOrNo;
    final errorColorIndex = widget.errorColorIndex;

    if (isYesOrNo && buttonNames.length != 2) {
      return Container();
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      backgroundColor:
          isLightTheme ? SBUColors.background50 : SBUColors.background500,
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              child: SBUTextComponent(
                text: title,
                textType: SBUTextType.heading1,
                textColorType: SBUTextColorType.text01,
                maxLines: widget.maxLines,
              ),
            ),
            isYesOrNo
                ? SizedBox(
                    width: double.maxFinite,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: buttonNames.mapIndexed((index, name) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SBUTextButtonComponent(
                              height: 32,
                              text: SBUTextComponent(
                                text: name,
                                textType: SBUTextType.button,
                                textColorType: index == 0
                                    ? SBUTextColorType.primary
                                    : SBUTextColorType.error,
                              ),
                              onButtonClicked: () {
                                Navigator.pop(context);
                                onButtonClicked(buttonNames[index]);
                              },
                              padding: const EdgeInsets.all(8),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: buttonNames.mapIndexed((index, name) {
                      return SBUTextButtonComponent(
                        width: double.maxFinite,
                        height: 48,
                        text: SBUTextComponent(
                          text: name,
                          textType: SBUTextType.subtitle2,
                          textColorType: errorColorIndex == index
                              ? SBUTextColorType.error
                              : SBUTextColorType.text01,
                        ),
                        onButtonClicked: () {
                          Navigator.pop(context);
                          onButtonClicked(buttonNames[index]);
                        },
                        padding: const EdgeInsets.only(left: 24, right: 24),
                        isAlignmentStart: true,
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}

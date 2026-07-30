import 'package:eschool/ui/widgets/system/svgButton.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomBackButton extends StatelessWidget {
  final Function? onTap;
  final double? topPadding;
  final AlignmentDirectional? alignmentDirectional;
  final Color? iconColor;
  const CustomBackButton({
    Key? key,
    this.onTap,
    this.topPadding,
    this.alignmentDirectional,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignmentDirectional ?? AlignmentDirectional.topStart,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          top: topPadding ?? 0,
          start: Utils.screenContentHorizontalPadding,
        ),
        child: SvgButton(
          buttonColor: iconColor,
          onTap: () {
            if (onTap != null) {
              onTap?.call();
            } else {
              Get.back();
            }
          },
          svgIconUrl: Utils.getBackButtonPath(context),
        ),
      ),
    );
  }
}

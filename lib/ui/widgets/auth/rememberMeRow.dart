import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';

/// Row containing the "Remember Me" checkbox and the "Forgot Password" button.
/// The [onRememberMeChanged] callback fires when the checkbox or its label is tapped.
/// The [onForgotPassword] callback fires when the forgot-password button is tapped.
class RememberMeRow extends StatelessWidget {
  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;
  final VoidCallback? onForgotPassword;
  final Color primaryColor;

  const RememberMeRow({
    Key? key,
    required this.rememberMe,
    required this.onRememberMeChanged,
    this.onForgotPassword,
    required this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember Me Checkbox + label
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: Checkbox(
                value: rememberMe,
                onChanged: (value) => onRememberMeChanged(value!),
                activeColor: primaryColor,
                checkColor: Colors.white,
                fillColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return primaryColor;
                    }
                    return Colors.transparent;
                  },
                ),
                side: WidgetStateBorderSide.resolveWith(
                  (states) => BorderSide(
                    color: states.contains(WidgetState.selected)
                        ? primaryColor
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onRememberMeChanged(!rememberMe),
              child: Text(
                "Ingat Saya",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),

        // Forgot Password button
        if (onForgotPassword != null)
          TextButton(
            onPressed: onForgotPassword,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "${Utils.getTranslatedLabel(resetPasswordKey)}?",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/academic/studentSubjectAndSlidersCubit.dart';

import 'package:eschool/utils/system/app_config.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class EnvSwitcherUtil {
  static void showEnvDialog(BuildContext context) {
    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Pilih Environment',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogEnvOption(ctx, setDialogState, Environment.prod,
                    'Production', AppConfig.prodUrl, Colors.green.shade700),
                const SizedBox(height: 10),
                _dialogEnvOption(ctx, setDialogState, Environment.testing,
                    'Testing', AppConfig.testingUrl, Colors.blue.shade700),
                const SizedBox(height: 10),
                _dialogEnvOption(ctx, setDialogState, Environment.dev,
                    'Development', AppConfig.devUrl, Colors.orange.shade700),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      ),
      barrierDismissible: true,
    );
  }

  static Widget _dialogEnvOption(
    BuildContext dialogCtx,
    StateSetter setDialogState,
    Environment env,
    String label,
    String url,
    Color color,
  ) {
    final isActive = AppConfig.currentEnv == env;
    return GestureDetector(
      onTap: () async {
        if (isActive) {
          Get.back();
          return;
        }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   

        final authState = dialogCtx.read<AuthCubit>().state;
        final isLoggedIn = authState is Authenticated ||
            dialogCtx.read<AuthCubit>().authRepository.getIsLogIn();

        if (isLoggedIn) {
          Get.back();
          _showLogoutConfirmDialog(dialogCtx, env);
        } else {
          await _changeEnvUnauthenticated(dialogCtx, setDialogState, env);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              isActive ? color.withValues(alpha: 0.10) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade300,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isActive ? color : Colors.black87,
                    ),
                  ),
                  Text(
                    url,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isActive)
              Icon(Icons.check_circle_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  static void _showLogoutConfirmDialog(BuildContext context, Environment env) {
    // Capture cubit references immediately while context is still valid
    final authCubit = context.read<AuthCubit>();
    final subjectCubit = context.read<StudentSubjectsAndSlidersCubit>();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              "Mengganti environment akan mengeluarkan Anda dari sesi saat ini (Logout). Lanjutkan?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    child: Text(Utils.getTranslatedLabel(noKey)),
                    onPressed: () {
                      Get.back();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      Utils.getTranslatedLabel(yesKey),
                      style: const TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      // Close dialog first
                      Get.back();

                      // Use pre-captured cubit references (context is no longer valid after Get.back)
                      subjectCubit.clearSubjects();
                      authCubit.signOut();

                      await AppConfig.setEnvironment(env);

                      Get.offAllNamed(Routes.auth);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _changeEnvUnauthenticated(
    BuildContext context,
    StateSetter setDialogState,
    Environment env,
  ) async {
    // Clear potentially saved credentials so they don't leak into the new env
    final authRepository = context.read<AuthCubit>().authRepository;
    authRepository.clearStudentCredentials();
    authRepository.setRememberMeStudent(false);
    await authRepository.clearOtpCredentials();

    await AppConfig.setEnvironment(env);

    // Using Get.forceAppUpdate() to force widget tree rebuild across the app
    // if simple setStates inside the pop are not enough
    setDialogState(() {});
    Get.back();

    // Minor force UI rebuild specifically for AuthScreen which is likely active
    final currentState =
        context.findAncestorStateOfType<State<StatefulWidget>>();
    if (currentState != null && currentState.mounted) {
      // ignore: invalid_use_of_protected_member
      currentState.setState(() {});
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Environment diganti ke ${AppConfig.envName}'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

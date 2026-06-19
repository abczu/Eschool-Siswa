import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/student/guardianPhotoCubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/data/models/auth/guardian.dart';
import 'package:eschool/ui/widgets/system/customUserProfileImageWidget.dart';
import 'package:eschool/ui/widgets/student/guardian/guardianDetailItem.dart';
import 'package:eschool/ui/widgets/student/guardian/guardianEditProfileSheet.dart';
import 'package:eschool/ui/widgets/student/guardian/guardianEmailBadge.dart';
import 'package:eschool/ui/widgets/student/guardian/guardianQuickPhotoSheet.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

DateTime? _parseApiDob(String? s) {
  if (s == null || s.trim().isEmpty) return null;
  final raw = s.trim();
  try {
    return DateFormat('yyyy-MM-dd').parseStrict(raw);
  } catch (_) {
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }
}

String displayIndo(DateTime d) =>
    DateFormat('d MMMM yyyy', 'id_ID').format(d).toLowerCase();

String genderApiToUiTitle(String? api) {
  final s = (api ?? '').trim().toLowerCase();
  if (s == 'male') return 'Laki - Laki';
  if (s == 'female') return 'Perempuan';
  return '';
}

class GuardianDetailsContainer extends StatefulWidget {
  final Guardian guardian;
  const GuardianDetailsContainer({
    Key? key,
    required this.guardian,
  }) : super(key: key);

  @override
  State<GuardianDetailsContainer> createState() =>
      _GuardianDetailsContainerState();
}

class _GuardianDetailsContainerState extends State<GuardianDetailsContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Guardian _guardian;
  BuildContext? _lctx;
  final Color primaryColor = const Color(0xFFE53935);
  final Color secondaryColor = const Color(0xFFEF5350);
  final Color textColor = const Color(0xFF212121);
  final Color containerColor = Colors.white;

  String? _currentImageUrl;
  DateTime? _selectedDob;

  @override
  void initState() {
    super.initState();

    initializeDateFormatting('id_ID', null).then((_) {
      if (mounted) setState(() {});
    });

    _guardian = widget.guardian;
    _currentImageUrl = _guardian.image;
    _selectedDob = _parseApiDob(_guardian.dob);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _withCacheBuster(String url) {
    if (url.isEmpty) return url;
    final sep = url.contains('?') ? '&' : '?';
    return '$url${sep}v=${DateTime.now().millisecondsSinceEpoch}';
  }

  void _onChangeProfile() {
    final photoCubit = context.read<GuardianPhotoCubit>();
    showModalBottomSheet(
      context: _lctx ?? context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => GuardianQuickPhotoSheet(
        photoCubit: photoCubit,
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        onPickAndUpload: _pickAndUpload,
      ),
    );
  }

  Future<void> _pickAndUpload(
      ImageSource source, GuardianPhotoCubit cubit) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );
      if (file == null) return;

      final childId = context.read<AuthCubit>().getParentDetails().children?.first.id ?? 0;

      cubit.updateGuardianPhoto(
        guardian: _guardian,
        file: file,
        childId: childId,
      );

      _showLoadingSnackBar('Mengunggah foto…', Colors.orange[700]!);
    } catch (e) {
      _showErrorSnackBar('Gagal memilih gambar: $e');
    }
  }

  void _onEditFullProfile() {
    final photoCubit = context.read<GuardianPhotoCubit>();
    showModalBottomSheet(
      context: _lctx ?? context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GuardianEditProfileSheet(
        guardian: _guardian,
        photoCubit: photoCubit,
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        currentImageUrl: _currentImageUrl,
      ),
    );
  }

  void _showLoadingSnackBar(String message, Color color) {
    ScaffoldMessenger.of(_lctx ?? context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 30),
        elevation: 6,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(_lctx ?? context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 4),
        elevation: 6,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(_lctx ?? context).hideCurrentSnackBar();
    ScaffoldMessenger.of(_lctx ?? context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600]!,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: const Locale('id', 'ID'),
      delegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      child: Builder(
        builder: (ctx) {
          _lctx = ctx;

          return BlocConsumer<GuardianPhotoCubit, GuardianPhotoState>(
            listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
            listener: (context, state) async {
              if (state is GuardianPhotoSuccess) {
                _showSuccessSnackBar('Profil berhasil diperbarui');

                final oldUrl = _currentImageUrl ?? '';
                if (oldUrl.isNotEmpty) {
                  await CachedNetworkImage.evictFromCache(oldUrl);
                }
                final freshUrl = _withCacheBuster(state.data.image ?? '');

                setState(() {
                  _currentImageUrl = freshUrl;
                  _guardian = state.data;
                  _selectedDob = _parseApiDob(_guardian.dob);
                });

                if (mounted) {
                  context.read<AuthCubit>().updateParentProfile(state.data);
                }
              } else if (state is GuardianPhotoFailure) {
                ScaffoldMessenger.of(_lctx ?? context).hideCurrentSnackBar();
                _showErrorSnackBar('Gagal menyimpan: ${state.errorMessage}');
              }
            },
            builder: (context, state) {
              final bool isLoading = state is GuardianPhotoInProgress;

              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: MediaQuery.of(ctx).size.width * 0.9,
                    margin:
                        const EdgeInsets.only(right: 20, left: 20, bottom: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: containerColor,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.15),
                            spreadRadius: 2,
                            blurRadius: 12,
                            offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Profile section
                        Container(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Profile photo
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 600),
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                      scale: value, child: child);
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 90.0,
                                      height: 90.0,
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                              color: primaryColor.withValues(
                                                  alpha: 0.25),
                                              spreadRadius: 2,
                                              blurRadius: 10,
                                              offset: const Offset(0, 3))
                                        ],
                                      ),
                                      child: Hero(
                                        tag: 'guardian_${widget.guardian.id}',
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                primaryColor,
                                                secondaryColor
                                              ],
                                            ),
                                          ),
                                          child: CustomUserProfileImageWidget(
                                            key: ValueKey(
                                                _currentImageUrl ?? ""),
                                            profileUrl: _currentImageUrl ?? "",
                                          ),
                                        ),
                                      ),
                                    ),
                                    // edit foto
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: InkWell(
                                        onTap: isLoading
                                            ? null
                                            : _onChangeProfile,
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          width: 35,
                                          height: 35,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.15),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2))
                                            ],
                                            border: Border.all(
                                                color: primaryColor.withValues(
                                                    alpha: 0.2),
                                                width: 1),
                                          ),
                                          child: Center(
                                            child: isLoading
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2))
                                                : Icon(Icons.camera_alt,
                                                    size: 20,
                                                    color: primaryColor),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 20),

                              // Name + Email
                              Expanded(
                                child: AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _animationController.value,
                                      child: Transform.translate(
                                        offset: Offset(
                                            0,
                                            20 *
                                                (1 -
                                                    _animationController
                                                        .value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        Utils.formatEmptyValue(
                                            _guardian.getFullName()),
                                        style: TextStyle(
                                            fontSize: 20.0,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: GuardianEmailBadge(
                                                email: _guardian.email,
                                                onDarkBg: false),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton.icon(
                                          onPressed: isLoading
                                              ? null
                                              : _onEditFullProfile,
                                          icon: const Icon(Icons.edit_outlined),
                                          label: const Text('Edit Profil'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Divider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(
                              color: primaryColor.withValues(alpha: 0.15),
                              thickness: 1.5),
                        ),

                        // Detail
                        GuardianDetailItem(
                          title: Utils.getTranslatedLabel(phoneNumberKey),
                          value: Utils.formatEmptyValue(_guardian.mobile ?? ""),
                          primaryColor: primaryColor,
                          textColor: textColor,
                          animationController: _animationController,
                          index: 1,
                        ),
                        GuardianDetailItem(
                          title: Utils.getTranslatedLabel(addressKey),
                          value: Utils.formatEmptyValue(
                              _guardian.currentAddress ?? ""),
                          primaryColor: primaryColor,
                          textColor: textColor,
                          animationController: _animationController,
                          index: 2,
                        ),
                        GuardianDetailItem(
                          title: "Alamat Permanen",
                          value: Utils.formatEmptyValue(
                              _guardian.permanentAddress ?? ""),
                          primaryColor: primaryColor,
                          textColor: textColor,
                          animationController: _animationController,
                          index: 3,
                        ),
                        GuardianDetailItem(
                          title: "Jenis Kelamin",
                          value: Utils.formatEmptyValue(
                              genderApiToUiTitle(_guardian.gender)),
                          primaryColor: primaryColor,
                          textColor: textColor,
                          animationController: _animationController,
                          index: 4,
                        ),
                        GuardianDetailItem(
                          title: "Tanggal Lahir",
                          value: Utils.formatEmptyValue(_selectedDob != null
                              ? displayIndo(_selectedDob!)
                              : ''),
                          primaryColor: primaryColor,
                          textColor: textColor,
                          animationController: _animationController,
                          index: 5,
                        ),
                        GuardianDetailItem(
                          title: "Pekerjaan",
                          value: Utils.formatEmptyValue(
                              _guardian.occupation ?? ""),
                          primaryColor: primaryColor,
                          textColor: textColor,
                          animationController: _animationController,
                          index: 6,
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

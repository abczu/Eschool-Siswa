import 'dart:io';

import 'package:eschool/cubits/student/guardianPhotoCubit.dart';
import 'package:eschool/data/models/auth/guardian.dart';
import 'package:eschool/ui/widgets/system/customUserProfileImageWidget.dart';
import 'package:eschool/ui/widgets/student/guardian/guardianEmailBadge.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class GuardianEditProfileSheet extends StatefulWidget {
  final Guardian guardian;
  final GuardianPhotoCubit photoCubit;
  final Color primaryColor;
  final Color secondaryColor;
  final String? currentImageUrl;

  const GuardianEditProfileSheet({
    Key? key,
    required this.guardian,
    required this.photoCubit,
    required this.primaryColor,
    required this.secondaryColor,
    required this.currentImageUrl,
  }) : super(key: key);

  @override
  State<GuardianEditProfileSheet> createState() =>
      _GuardianEditProfileSheetState();
}

class _GuardianEditProfileSheetState extends State<GuardianEditProfileSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ImagePicker _picker = ImagePicker();
  XFile? _pendingFile;

  final _firstNameC = TextEditingController();
  final _lastNameC = TextEditingController();
  final _genderC = TextEditingController();
  final _dobC = TextEditingController();
  final _mobileC = TextEditingController();
  final _currentAddressC = TextEditingController();
  final _permanentAddressC = TextEditingController();
  final _occupationC = TextEditingController();

  final _firstNameFN = FocusNode();
  final _lastNameFN = FocusNode();
  final _genderFN = FocusNode();
  final _dobFN = FocusNode();
  final _mobileFN = FocusNode();
  final _currentAddressFN = FocusNode();
  final _permanentAddressFN = FocusNode();
  final _occupationFN = FocusNode();

  DateTime? _selectedDob;
  String? _selectedGenderApi;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();

    _initFields();
    _attachFocusListeners();
  }

  void _initFields() {
    final g = widget.guardian;
    _firstNameC.text = g.firstName ?? '';
    _lastNameC.text = g.lastName ?? '';
    _genderC.text = g.gender ?? '';
    _mobileC.text = g.mobile ?? '';
    _currentAddressC.text = g.currentAddress ?? '';
    _permanentAddressC.text = g.permanentAddress ?? '';
    _occupationC.text = g.occupation ?? '';

    _selectedDob = _parseApiDob(g.dob);
    _dobC.text = _selectedDob != null ? _displayIndo(_selectedDob!) : '';

    _selectedGenderApi = _genderAnyToApi(g.gender);
  }

  void _attachFocusListeners() {
    for (final fn in [
      _firstNameFN,
      _lastNameFN,
      _genderFN,
      _dobFN,
      _mobileFN,
      _currentAddressFN,
      _permanentAddressFN,
      _occupationFN,
    ]) {
      fn.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameC.dispose();
    _lastNameC.dispose();
    _genderC.dispose();
    _dobC.dispose();
    _mobileC.dispose();
    _currentAddressC.dispose();
    _permanentAddressC.dispose();
    _occupationC.dispose();
    _firstNameFN.dispose();
    _lastNameFN.dispose();
    _genderFN.dispose();
    _dobFN.dispose();
    _mobileFN.dispose();
    _currentAddressFN.dispose();
    _permanentAddressFN.dispose();
    _occupationFN.dispose();
    super.dispose();
  }

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

  String _displayIndo(DateTime d) =>
      DateFormat('d MMMM yyyy', 'id_ID').format(d).toLowerCase();

  String _apiYmd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String? _genderAnyToApi(String? any) {
    final s = (any ?? '').trim().toLowerCase();
    if (s == 'male' || s == 'l' || s == 'laki-laki' || s == 'laki laki') {
      return 'male';
    }
    if (s == 'female' || s == 'p' || s == 'perempuan') {
      return 'female';
    }
    return null;
  }

  Animation<Offset> _stagger(int index,
      {double start = 0.05, double gap = 0.08}) {
    final begin = (start + index * gap).clamp(0.0, 1.0);
    return Tween<Offset>(begin: const Offset(0, .12), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(begin, 1.0, curve: Curves.easeOutCubic),
      ),
    );
  }

  Future<void> _pickLocal() async {
    try {
      final XFile? f = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );
      if (f == null) return;
      setState(() => _pendingFile = f);
    } catch (e) {
      _showErrorSnackBar('Gagal memilih gambar: $e');
    }
  }

  Future<void> _pickDob() async {
    final DateTime initial =
        _selectedDob ?? DateTime.now().subtract(const Duration(days: 365 * 18));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
      builder: (ctx, child) {
        final base = Theme.of(ctx);
        const textCol = Color(0xFF212121);

        return Theme(
          data: base.copyWith(
            datePickerTheme: base.datePickerTheme.copyWith(
              headerForegroundColor: textCol,
              headerHeadlineStyle:
                  base.textTheme.headlineMedium?.copyWith(color: textCol),
              headerHelpStyle:
                  base.textTheme.labelMedium?.copyWith(color: textCol),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return null;
              }),
            ),
            colorScheme: base.colorScheme.copyWith(
              primary: widget.primaryColor,
              onPrimary: textCol,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: widget.primaryColor),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobC.text = _displayIndo(picked);
      });
    }
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final updatedGuardian = widget.guardian.copyWith(
      firstName: _firstNameC.text.trim(),
      lastName: _lastNameC.text.trim(),
      gender: _selectedGenderApi,
      dob: _selectedDob != null ? _apiYmd(_selectedDob!) : null,
      mobile: _mobileC.text.trim(),
      currentAddress: _currentAddressC.text.trim(),
      permanentAddress: _permanentAddressC.text.trim(),
      occupation: _occupationC.text.trim(),
    );

    Navigator.pop(context);

    final childId = (context.read<AuthCubit>().state as Authenticated).children.first.id ?? 0;

    widget.photoCubit
        .updateGuardianPhoto(guardian: updatedGuardian, file: _pendingFile, childId: childId);

    _showSavingSnackBar();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
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

  void _showSavingSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
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
            const Expanded(
              child: Text(
                'Menyimpan perubahan…',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700]!,
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

  Widget _imagePreview() {
    if (_pendingFile != null) {
      return CircleAvatar(
        radius: 44,
        backgroundImage: FileImage(File(_pendingFile!.path)),
      );
    }
    return CircleAvatar(
      radius: 44,
      backgroundColor: Colors.grey.shade200,
      child: ClipOval(
        child: SizedBox(
          width: 88,
          height: 88,
          child: CustomUserProfileImageWidget(
            profileUrl: widget.currentImageUrl ?? '',
          ),
        ),
      ),
    );
  }

  Widget _buildElegantTextField({
    required TextEditingController controller,
    required String hintText,
    required String labelText,
    bool obscureText = false,
    required IconData icon,
    required Animation<Offset> slideAnimation,
    Widget? suffixWidget,
    required bool isFocused,
    required FocusNode focusNode,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return SlideTransition(
      position: slideAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
          border: Border.all(
              color: isFocused ? widget.primaryColor : Colors.grey.shade200,
              width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 10),
              child: Text(
                labelText,
                style: TextStyle(
                  color: isFocused ? widget.primaryColor : Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 50,
                  child: Center(
                    child: Icon(
                      icon,
                      color: isFocused
                          ? widget.primaryColor
                          : Colors.grey.shade500,
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    validator: validator,
                    textInputAction: textInputAction,
                    onTap: onTap,
                    readOnly: readOnly,
                    maxLines: maxLines,
                    style: const TextStyle(
                      color: Color(0xFF303030),
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          vertical: maxLines > 1 ? 12 : 14),
                      isDense: true,
                    ),
                  ),
                ),
                if (suffixWidget != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: suffixWidget,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElegantDropdown<T>({
    required String labelText,
    required IconData icon,
    required Animation<Offset> slideAnimation,
    required FocusNode focusNode,
    required bool isFocused,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    T? value,
    String? hintText,
  }) {
    final Color borderCol =
        isFocused ? widget.primaryColor : Colors.grey.shade200;

    return SlideTransition(
      position: slideAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
          border: Border.all(color: borderCol, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 10, bottom: 6),
              child: Text(
                labelText,
                style: TextStyle(
                  color: isFocused ? widget.primaryColor : Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 12, 12),
              child: DropdownButtonFormField<T>(
                focusNode: focusNode,
                initialValue: value,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 2),
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: items,
                onChanged: onChanged,
                menuMaxHeight: 260,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double _kPinnedHeaderHeight = 160;
    final kb = MediaQuery.of(context).viewInsets.bottom;
    const double kStickyReserve = 90;
    final double bottomPad = (kb > 0 ? kb : kStickyReserve);

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Stack(
            children: [
              CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedHeader(
                      height: _kPinnedHeaderHeight,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(28)),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    widget.primaryColor,
                                    widget.secondaryColor
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.primaryColor
                                        .withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      _imagePreview(),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: InkWell(
                                          onTap: _pickLocal,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.15),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.camera_alt_outlined,
                                              size: 18,
                                              color: widget.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Edit Profil',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Flexible(
                                              child: GuardianEmailBadge(
                                                email: widget.guardian.email,
                                                onDarkBg: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // FORM FIELDS
                  SliverToBoxAdapter(
                    child: AnimatedPadding(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildElegantTextField(
                                    controller: _firstNameC,
                                    focusNode: _firstNameFN,
                                    isFocused: _firstNameFN.hasFocus,
                                    labelText: 'Nama Depan',
                                    hintText: 'Nama depan',
                                    icon: Icons.badge_outlined,
                                    slideAnimation: _stagger(0),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildElegantTextField(
                                    controller: _lastNameC,
                                    focusNode: _lastNameFN,
                                    isFocused: _lastNameFN.hasFocus,
                                    labelText: 'Nama Belakang',
                                    hintText: 'Nama belakang',
                                    icon: Icons.badge,
                                    slideAnimation: _stagger(1),
                                  ),
                                ),
                              ],
                            ),
                            _buildElegantDropdown<String>(
                              labelText: 'Jenis Kelamin',
                              icon: Icons.wc_outlined,
                              focusNode: _genderFN,
                              isFocused: _genderFN.hasFocus,
                              slideAnimation: _stagger(2),
                              value: _selectedGenderApi,
                              items: const [
                                DropdownMenuItem(
                                  value: 'male',
                                  child: Text('Laki - Laki'),
                                ),
                                DropdownMenuItem(
                                  value: 'female',
                                  child: Text('Perempuan'),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedGenderApi = val);
                              },
                              hintText: 'Pilih jenis kelamin',
                            ),
                            _buildElegantTextField(
                              controller: _dobC,
                              focusNode: _dobFN,
                              isFocused: _dobFN.hasFocus,
                              labelText: 'Tanggal Lahir',
                              hintText: '',
                              icon: Icons.event_outlined,
                              slideAnimation: _stagger(3),
                              readOnly: true,
                              onTap: _pickDob,
                              suffixWidget: IconButton(
                                icon: const Icon(Icons.calendar_today_outlined),
                                onPressed: _pickDob,
                                tooltip: 'Pilih tanggal',
                              ),
                            ),
                            _buildElegantTextField(
                              controller: _mobileC,
                              focusNode: _mobileFN,
                              isFocused: _mobileFN.hasFocus,
                              labelText: 'No. HP',
                              hintText: 'contoh: 0812xxxxxxx',
                              icon: Icons.phone_outlined,
                              slideAnimation: _stagger(4),
                              keyboardType: TextInputType.phone,
                            ),
                            _buildElegantTextField(
                              controller: _currentAddressC,
                              focusNode: _currentAddressFN,
                              isFocused: _currentAddressFN.hasFocus,
                              labelText: 'Alamat Saat Ini',
                              hintText: 'Jalan, RT/RW, Kel/Desa, Kec, Kota/Kab',
                              icon: Icons.location_on_outlined,
                              slideAnimation: _stagger(5),
                            ),
                            _buildElegantTextField(
                              controller: _permanentAddressC,
                              focusNode: _permanentAddressFN,
                              isFocused: _permanentAddressFN.hasFocus,
                              labelText: 'Alamat Permanen',
                              hintText: 'Jalan, RT/RW, Kel/Desa, Kec, Kota/Kab',
                              icon: Icons.home_outlined,
                              slideAnimation: _stagger(6),
                            ),
                            _buildElegantTextField(
                              controller: _occupationC,
                              focusNode: _occupationFN,
                              isFocused: _occupationFN.hasFocus,
                              labelText: 'Pekerjaan',
                              hintText: 'contoh: Wiraswasta, Karyawan, dll.',
                              icon: Icons.work_outline,
                              slideAnimation: _stagger(7),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Profil Lengkap'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PinnedHeader extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _PinnedHeader({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Colors.transparent,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeader oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

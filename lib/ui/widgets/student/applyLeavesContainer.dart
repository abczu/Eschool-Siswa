import 'dart:io';
import 'package:eschool/cubits/student/applyLeavesCubit.dart';
import 'package:eschool/data/models/student/leave.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/system/optimizedFileCompressionMixin.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/data/repositories/student/leavesRepository.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eschool/utils/system/optimizedFileCompressionUtils.dart';

class ApplyLeavesContainer extends StatefulWidget {
  final int? childId;
  final Leave? data;

  const ApplyLeavesContainer({Key? key, this.childId, this.data})
      : super(key: key);

  @override
  State<ApplyLeavesContainer> createState() => _ApplyLeavesContainerState();
}

class _ApplyLeavesContainerState extends State<ApplyLeavesContainer>
    with SingleTickerProviderStateMixin, OptimizedFileCompressionMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  final LeavesRepository _leavesRepository = LeavesRepository();
  late AnimationController _animationController;

  LeaveType _selectedLeaveType = LeaveType.sick;

  // NOTE: sekarang _selectedFile bisa berisi URL (remote) atau path lokal.
  String? _selectedFile;
  bool _selectedIsRemote = false;

  // Khusus cek izin hari ini (read-only)
  bool _isCheckingToday = false;
  bool _hasCheckedTodayLeave = false;
  bool _hasTodayLeave = false;
  bool isUpdate = false;

  @override
  void initState() {
    super.initState();

    isUpdate = widget.data != null;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    if (isUpdate) {
      final databinding = widget.data!;
      _reasonController.text = databinding.reason;

      // Ambil detail yang BUKAN file untuk tipe izin, sort by ID descending (terbaru)
      final nonFileDetails = databinding.leaveDetail
          .where((detail) => !detail.isFile)
          .toList()
        ..sort((a, b) => b.id.compareTo(a.id));

      // Ambil tipe dari leaveDetail dengan ID tertinggi (terbaru)
      String? leaveTypeFromData;

      if (nonFileDetails.isNotEmpty) {
        leaveTypeFromData = nonFileDetails.first.type;
      } else if (databinding.type.isNotEmpty) {
        leaveTypeFromData = databinding.type;
      }

      if (leaveTypeFromData != null && leaveTypeFromData.isNotEmpty) {
        final typeValue = leaveTypeFromData.toLowerCase();
        _selectedLeaveType =
            typeValue == "sick" ? LeaveType.sick : LeaveType.leave;
      }

      // Ambil file dari property fileDetail ATAU dari leaveDetail yang isFile = true
      LeaveDetail? fileDetail;

      // Prioritas 1: Cek property fileDetail (ini yang utama dari API)
      if (databinding.fileDetail.isNotEmpty) {
        fileDetail = databinding.fileDetail.first;
      }
      // Prioritas 2: Cek leaveDetail yang isFile = true (backup)
      else {
        final fileDetailsFromLeave =
            databinding.leaveDetail.where((detail) => detail.isFile).toList();
        if (fileDetailsFromLeave.isNotEmpty) {
          fileDetail = fileDetailsFromLeave.first;
        }
      }

      // Set file jika ada
      if (fileDetail != null && fileDetail.fileUrl != null) {
        _selectedFile = fileDetail.fileUrl;
        _selectedIsRemote = true; // File dari server pasti remote
      }
    }

    Future.delayed(Duration.zero, () {
      if (!isUpdate) {
        _checkTodayLeave();
      }
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // === Helpers untuk beda URL vs path lokal ===

  String _filenameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final last = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : url;
      return last.split('?').first;
    } catch (_) {
      return url;
    }
  }

  String _extFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return '.pdf';
    if (lower.endsWith('.jpg')) return '.jpg';
    if (lower.endsWith('.jpeg')) return '.jpeg';
    if (lower.endsWith('.png')) return '.png';
    final ext = path.extension(lower);
    return ext.isNotEmpty ? ext : '';
  }

  IconData _iconFromName(String name) {
    switch (_extFromName(name)) {
      case '.pdf':
        return Icons.picture_as_pdf_rounded;
      case '.jpg':
      case '.jpeg':
      case '.png':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _typeFromName(String name) {
    switch (_extFromName(name)) {
      case '.pdf':
        return 'PDF Document';
      case '.jpg':
      case '.jpeg':
        return 'JPEG Image';
      case '.png':
        return 'PNG Image';
      default:
        return 'File';
    }
  }

  // === PAKAI MIXIN UNTUK PILIH & KOMPRES ===
  Future<void> _pickFile() async {
    try {
      final File? file = await pickAndCompressSingleFile(
        context: context,
        fileType: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        // target 300KB biar selaras dgn target repo lama
        maxSizeInMB: 0.3,
        customQuality: 80,
        forceCompress: true,
      );

      if (file == null) return;

      // Untuk PDF: tetap patuhi batas 2MB di UI
      final ext = path.extension(file.path).toLowerCase();
      if (ext == '.pdf') {
        final size = await file.length();
        if (size > 2 * 1024 * 1024) {
          _showSnackBar(Utils.getTranslatedLabel(fileSizeExceededKey),
              isError: true);
          return;
        }
      }

      setState(() {
        _selectedFile = file.path; // path lokal
        _selectedIsRemote = false; // karena ini file baru dari device
      });
    } catch (e) {
      debugPrint('Error pick/compress: $e');
      _showSnackBar("Gagal memproses file", isError: true);
    }
  }

  Future<void> _compressAndSetFile(File rawFile) async {
    _showBlockingDialog("Mengoptimalkan file…");
    try {
      final compressedFile = await OptimizedFileCompressionUtils.compressFile(
        file: rawFile,
        maxSizeInMB: 0.3,
        customQuality: 80,
        forceCompress: true,
      );

      _safePopDialog();

      final originalSize = await rawFile.length();
      final compressedSize = await compressedFile.length();

      setState(() {
        _selectedFile = compressedFile.path;
        _selectedIsRemote = false;
      });

      showCompressionResult(
        context,
        originalSize: originalSize,
        compressedSize: compressedSize,
        fileName: path.basename(rawFile.path),
      );
    } catch (e) {
      _safePopDialog();
      debugPrint("Gagal mengompresi file: $e");
      setState(() {
        _selectedFile = rawFile.path;
        _selectedIsRemote = false;
      });
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (photo == null) return;
      await _compressAndSetFile(File(photo.path));
    } catch (e) {
      debugPrint('Error pick from camera: $e');
      _showSnackBar("Gagal mengambil foto dari kamera", isError: true);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (image == null) return;
      await _compressAndSetFile(File(image.path));
    } catch (e) {
      debugPrint('Error pick from gallery: $e');
      _showSnackBar("Gagal memilih foto dari galeri", isError: true);
    }
  }

  void _showAttachmentSourceBS(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pilih Lampiran",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Pilih file, foto dari galeri, atau ambil foto baru dengan kamera sebagai lampiran izin.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildBSOption(
                          icon: Icons.camera_alt_rounded,
                          label: "Kamera",
                          onTap: () {
                            Navigator.pop(context);
                            _pickFromCamera();
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildBSOption(
                          icon: Icons.photo_library_rounded,
                          label: "Galeri",
                          onTap: () {
                            Navigator.pop(context);
                            _pickFromGallery();
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildBSOption(
                          icon: Icons.insert_drive_file_rounded,
                          label: "Dokumen/PDF",
                          onTap: () {
                            Navigator.pop(context);
                            _pickFile();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBSOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    // Deteksi apakah pesan sukses

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // Icon dengan background circle
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Text message
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
        backgroundColor: isError
            ? const Color(0xFFD32F2F) // Merah lebih soft
            : Colors.green[600], // Hijau success - lebih terang!
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

  Future<void> _checkTodayLeave() async {
    if (_hasCheckedTodayLeave || widget.childId == null) return;

    setState(() => _isCheckingToday = true);
    try {
      final leaves = await _leavesRepository.fetchChildLeaves(
        childId: widget.childId!,
      );

      final today = DateFormat('dd-MM-yyyy').format(DateTime.now());
      _hasTodayLeave = leaves.any((leave) =>
          leave.leaveDetail.any((detail) => detail.formattedDate == today));

      _hasCheckedTodayLeave = true;

      if (_hasTodayLeave && mounted) {
        _showSnackBar(
          Utils.getTranslatedLabel(alreadyAppliedTodayKey),
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Error checking today leave: $e');
    } finally {
      if (mounted) setState(() => _isCheckingToday = false);
    }
  }

  Future<void> _submitLeave(BuildContext ctx) async {
    if (!_formKey.currentState!.validate()) return;

    if (!isUpdate && _hasTodayLeave) {
      _showSnackBar(Utils.getTranslatedLabel(alreadyAppliedTodayKey),
          isError: true);
      return;
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final leaveDetails = [
      {'date': today, 'type': _selectedLeaveType.value}
    ];

    // Kirim file hanya jika user memilih file BARU (lokal).
    final filesToSend = (_selectedFile != null && !_selectedIsRemote)
        ? <String>[_selectedFile!]
        : null;

    // gunakan ctx dari subtree (agar berada di bawah BlocProvider)
    ctx.read<ApplyLeaveCubit>().applyLeave(
          childId: widget.childId!,
          reason: _reasonController.text,
          leaveDetails: leaveDetails,
          files: filesToSend,
          leaveId: widget.data?.id,
        );
  }

  // Dialog progres upload (diselaraskan stylingnya)
  void _showBlockingDialog(String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              // Progress ring
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Texts
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        letterSpacing: .2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Mohon tunggu sebentar...",
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: .7),
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _safePopDialog() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  // Method untuk preview gambar (sama dengan subject attendance)
  void _showImageDialog(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (BuildContext context, _, __) {
          return StatefulBuilder(
            builder: (context, setState) {
              return GestureDetector(
                onTap: () {
                  // Close on tap anywhere on the screen
                  Navigator.of(context).pop();
                },
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: SafeArea(
                    child: Stack(
                      children: [
                        // Main image with zoom
                        Center(
                          child: GestureDetector(
                            // Prevent taps on the image from closing
                            onTap: () {
                              // Stop propagation by doing nothing
                            },
                            child: InteractiveViewer(
                              maxScale: 2.5,
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.white,
                                          size: 48,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Gagal memuat gambar',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        // Close button
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.black87,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildSelectedFile() {
    if (_selectedFile == null) return const SizedBox.shrink();

    final displayName = _selectedIsRemote
        ? _filenameFromUrl(_selectedFile!)
        : path.basename(_selectedFile!);

    final icon = _iconFromName(displayName);
    final isImage = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp']
        .any((ext) => displayName.toLowerCase().endsWith(ext));

    final subtitle = _selectedIsRemote
        ? '${_typeFromName(displayName)} • File lama'
        : _typeFromName(displayName);

    return Animate(
      effects: const [
        FadeEffect(duration: Duration(milliseconds: 300)),
        SlideEffect(
          begin: Offset(0, 0.2),
          end: Offset.zero,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOutQuint,
        ),
      ],
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          title: Text(
            displayName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            splashRadius: 20,
            onPressed: () {
              setState(() {
                _selectedFile = null;
                _selectedIsRemote = false;
              });
            },
          ),
          // Tap untuk preview gambar jika file remote dan adalah gambar
          onTap: _selectedIsRemote && isImage
              ? () {
                  _showImageDialog(context, _selectedFile!);
                }
              : null,
        ),
      ),
    );
  }

  Widget _buildReasonField() {
    return Animate(
      effects: const [
        FadeEffect(
            duration: Duration(milliseconds: 300),
            delay: Duration(milliseconds: 100)),
        SlideEffect(
          begin: Offset(0, 0.2),
          end: Offset.zero,
          duration: Duration(milliseconds: 300),
          delay: Duration(milliseconds: 100),
          curve: Curves.easeOutQuint,
        ),
      ],
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: TextFormField(
          controller: _reasonController,
          decoration: InputDecoration(
            labelText: Utils.getTranslatedLabel(reasonLeavesKey),
            labelStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.all(16.0),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return Utils.getTranslatedLabel(pleaseEnterReasonKey);
            }
            if (value!.length > 255) {
              return Utils.getTranslatedLabel(maxLengthExceededKey);
            }
            return null;
          },
          maxLines: 5,
          minLines: 3,
          maxLength: 255,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.newline,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            letterSpacing: 0.5,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildLeaveTypeSelection() {
    return Animate(
      effects: const [
        FadeEffect(
            duration: Duration(milliseconds: 300),
            delay: Duration(milliseconds: 200)),
        SlideEffect(
          begin: Offset(0, 0.2),
          end: Offset.zero,
          duration: Duration(milliseconds: 300),
          delay: Duration(milliseconds: 200),
          curve: Curves.easeOutQuint,
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Utils.getTranslatedLabel(leaveTypeKey),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildLeaveTypeOption(
                  type: LeaveType.sick,
                  icon: Icons.healing_rounded,
                  label: Utils.getTranslatedLabel(sickKey),
                ),
                const SizedBox(width: 16),
                _buildLeaveTypeOption(
                  type: LeaveType.leave,
                  icon: Icons.event_busy_rounded,
                  label: Utils.getTranslatedLabel(leavesKey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveTypeOption({
    required LeaveType type,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedLeaveType == type;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedLeaveType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade600,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade800,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningNote() {
    return Animate(
      effects: const [
        FadeEffect(duration: Duration(milliseconds: 300)),
        SlideEffect(
          begin: Offset(0, 0.2),
          end: Offset.zero,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOutQuint,
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                Utils.getTranslatedLabel(leaveWarningNoteKey),
                style: const TextStyle(color: Colors.black87, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayDateDisplay() {
    return Animate(
      effects: const [
        FadeEffect(
            duration: Duration(milliseconds: 300),
            delay: Duration(milliseconds: 50)),
        SlideEffect(
          begin: Offset(0, 0.2),
          end: Offset.zero,
          duration: Duration(milliseconds: 300),
          delay: Duration(milliseconds: 50),
          curve: Curves.easeOutQuint,
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Utils.getTranslatedLabel('date'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  DateFormat('dd MMMM yyyy', 'id').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadButton() {
    if (_selectedFile != null) return const SizedBox.shrink();

    return Animate(
      effects: const [
        FadeEffect(
            duration: Duration(milliseconds: 300),
            delay: Duration(milliseconds: 300)),
        ScaleEffect(
          duration: Duration(milliseconds: 300),
          delay: Duration(milliseconds: 300),
          curve: Curves.easeOutQuint,
        ),
      ],
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showAttachmentSourceBS(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Utils.getTranslatedLabel(attachmentsKey),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${Utils.getTranslatedLabel(uploadAttachmentKey)} (Max 2MB)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Animate(
      effects: const [
        FadeEffect(
            duration: Duration(milliseconds: 300),
            delay: Duration(milliseconds: 400)),
        SlideEffect(
          begin: Offset(0, 0.2),
          end: Offset.zero,
          duration: Duration(milliseconds: 300),
          delay: Duration(milliseconds: 400),
          curve: Curves.easeOutQuint,
        ),
      ],
      child: BlocBuilder<ApplyLeaveCubit, ApplyLeaveState>(
        builder: (context, state) {
          final isSubmitting = state is ApplyLeaveUploading;

          return SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isSubmitting || (!isUpdate && _hasTodayLeave)
                  ? null
                  : () => _submitLeave(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isUpdate
                          ? Utils.getTranslatedLabel("Perbarui")
                          : Utils.getTranslatedLabel(submitKey),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Provider cubit di sini agar 1 halaman 1 instance
    return BlocProvider(
      create: (_) => ApplyLeaveCubit(_leavesRepository),
      child: Scaffold(
        body: Column(
          children: [
            ScreenTopBackgroundContainer(
              heightPercentage: Utils.appBarSmallerHeightPercentage,
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    const CustomBackButton(),
                    Text(
                      isUpdate
                          ? "Perbarui Izin"
                          : Utils.getTranslatedLabel(applyLeavesKey),
                      style: TextStyle(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        fontSize: Utils.screenTitleFontSize,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Listener untuk upload / sukses / gagal
            BlocListener<ApplyLeaveCubit, ApplyLeaveState>(
              listener: (context, state) {
                if (state is ApplyLeaveUploading) {
                  _showBlockingDialog("Mengirimkan perizinan…");
                } else if (state is ApplyLeaveSuccess) {
                  _safePopDialog(); // tutup dialog upload
                  _showSnackBar(
                    isUpdate
                        ? Utils.getTranslatedLabel(leaveUpdatedSuccessfullyKey)
                        : Utils.getTranslatedLabel(leaveAppliedSuccessfullyKey),
                  );
                  Navigator.of(context).pop(true);
                } else if (state is ApplyLeaveFailure) {
                  _safePopDialog();
                  _showSnackBar(
                    Utils.getErrorMessageFromErrorCode(
                        context, state.errorMessage),
                    isError: true,
                  );
                }
              },
              child: Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWarningNote(),
                        const SizedBox(height: 20),
                        _buildTodayDateDisplay(),
                        const SizedBox(height: 20),
                        _buildReasonField(),
                        const SizedBox(height: 20),
                        _buildLeaveTypeSelection(),
                        const SizedBox(height: 20),
                        _buildFileUploadButton(),
                        _buildSelectedFile(),
                        const SizedBox(height: 30),
                        _buildSubmitButton(),
                        if (_isCheckingToday) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: const [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text("Memeriksa izin hari ini..."),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum LeaveType {
  sick,
  leave;

  String get value => name;
}

import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:eschool/cubits/academic/uploadAssignmentCubit.dart';
import 'package:eschool/data/models/academic/assignment.dart';
import 'package:eschool/ui/widgets/system/bottomsheetTopTitleAndCloseButton.dart';
import 'package:eschool/ui/widgets/system/customRoundedButton.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/optimizedFileCompressionMixin.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';
import 'package:path/path.dart' as path;

class UploadAssignmentFilesBottomsheetContainer extends StatefulWidget {
  final Assignment assignment;

  const UploadAssignmentFilesBottomsheetContainer({
    Key? key,
    required this.assignment,
  }) : super(key: key);

  @override
  State<UploadAssignmentFilesBottomsheetContainer> createState() =>
      _UploadAssignmentFilesBottomsheetContainerState();
}

class _UploadAssignmentFilesBottomsheetContainerState
    extends State<UploadAssignmentFilesBottomsheetContainer>
    with OptimizedFileCompressionMixin {
  final TextEditingController _answerController = TextEditingController();
  List<PlatformFile> uploadedFiles = [];

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    // batas maksimum per file (MB) dari assignment
    final double maxMB = widget.assignment.max_file.toDouble();

    // target kompres: 0.5 MB atau kurang kalau limit < 0.5 MB
    final double targetCompressMB = maxMB < 0.5 ? maxMB : 0.5;

    // pakai mixin: tampilkan dialog dan kompres yang perlu
    final List<File>? picked = await pickAndCompressFiles(
      fileType: FileType.custom,
      allowMultiple: true,
      allowedExtensions:
          widget.assignment.filetypes, // hormati tipe dari assignment
      maxSizeInMB: targetCompressMB, // target ukuran akhir
      customQuality: 80, // kualitas awal yang aman
      forceCompress: true, // paksa kompres untuk jaga ukuran konsisten
      context: context,
    );

    if (picked == null) return; // user batal

    // validasi ukuran akhir terhadap limit assignment
    final int maxBytes = (maxMB * 1024 * 1024).round();

    // konversi ke PlatformFile agar kompatibel dengan struktur existing
    final List<PlatformFile> accepted = [];
    final List<String> rejected = [];

    for (final file in picked) {
      try {
        final int size = file.lengthSync();

        if (size > maxBytes) {
          rejected.add('${path.basename(file.path)} '
              '(${(size / (1024 * 1024)).toStringAsFixed(2)} MB)');
          continue;
        }

        accepted.add(
          PlatformFile(
            name: path.basename(file.path),
            path: file.path,
            size: size,
          ),
        );
      } catch (_) {
        // kalau gagal baca size, tolak file-nya
        rejected.add(path.basename(file.path));
      }
    }

    if (rejected.isNotEmpty) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: '${Utils.getTranslatedLabel(fileSizeExceededKey)} '
            '(${widget.assignment.max_file} MB): ${rejected.join(', ')}',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }

    if (accepted.isEmpty) return;

    uploadedFiles.addAll(accepted);
    if (mounted) setState(() {});
  }

  Future<void> _addFiles() async {
    //upload files
    final permissionGiven = await Utils.hasStoragePermissionGiven();

    if (permissionGiven) {
      await _pickFiles();
    } else {
      if (context.mounted) {
        Utils.showCustomSnackBar(
          context: context,
          errorMessage:
              Utils.getTranslatedLabel(allowStoragePermissionToContinueKey),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  Widget _buildAddFileButton() {
    if (widget.assignment.filetypes.isEmpty) {
      return const SizedBox();
    }
    return InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () async {
          _addFiles();
        },
        child: DottedBorder(
          borderType: BorderType.RRect,
          dashPattern: const [10, 10],
          radius: const Radius.circular(15.0),
          color: Theme.of(context).colorScheme.onSurface,
          child: Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width * (0.8),
            height: MediaQuery.of(context).size.height * (0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 15,
                        offset: const Offset(0, 1.5),
                        color: Theme.of(context).colorScheme.primary,
                      )
                    ],
                  ),
                  width: 25,
                  height: 25,
                  child: Icon(
                    Icons.add,
                    size: 15,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * (0.05),
                ),
                Text(
                  Utils.getTranslatedLabel(addFilesKey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                )
              ],
            ),
          ),
        ));
  }

  Widget _buildAnswerTextField() {
    if (!widget.assignment.isText) {
      return const SizedBox();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      width: MediaQuery.of(context).size.width * (0.8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _answerController,
        maxLines: 5,
        minLines: 3,
        maxLength: 4096,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 14.0,
        ),
        decoration: InputDecoration(
          hintText: Utils.getTranslatedLabel(fillAssignmentTextKey),
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
          ),
          contentPadding: const EdgeInsets.all(15.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          counterStyle: TextStyle(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadedFileContainer(int fileIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Theme.of(context).colorScheme.surface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10.0),
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          return Row(
            children: [
              SizedBox(
                width: boxConstraints.maxWidth * (0.75),
                child: Text(
                  uploadedFiles[fileIndex].name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  if (context.read<UploadAssignmentCubit>().state
                      is UploadAssignmentInProgress) {
                    return;
                  }
                  uploadedFiles.removeAt(fileIndex);
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (context.read<UploadAssignmentCubit>().state
            is UploadAssignmentInProgress) {
          context.read<UploadAssignmentCubit>().cancelUploadAssignmentProcess();
        }
      },
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context)
                .scaffoldBackgroundColor, // Pastikan background putih/terang
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * (0.075),
            vertical: MediaQuery.of(context).size.height * (0.04),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BottomsheetTopTitleAndCloseButton(
                onTapCloseButton: () {
                  if (context.read<UploadAssignmentCubit>().state
                      is UploadAssignmentInProgress) {
                    context
                        .read<UploadAssignmentCubit>()
                        .cancelUploadAssignmentProcess();
                  }
                  Get.back();
                },
                titleKey: Utils.getTranslatedLabel(doAssignmentKey),
              ),

              Container(
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width * (0.8),
                child: Text(
                    Utils.getTranslatedLabel(
                      assignmentSubmissionDisclaimerKey,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
              ),

              SizedBox(
                height: MediaQuery.of(context).size.height * (0.025),
              ),

              // Add text field for answer
              _buildAnswerTextField(),

              SizedBox(
                height: uploadedFiles.isNotEmpty
                    ? MediaQuery.of(context).size.height * (0.025)
                    : 0,
              ),

              _buildAddFileButton(),

              SizedBox(
                height: MediaQuery.of(context).size.height * (0.015),
              ),
              ...List.generate(uploadedFiles.length, (index) => index)
                  .map((fileIndex) => _buildUploadedFileContainer(fileIndex))
                  .toList(),

              BlocConsumer<UploadAssignmentCubit, UploadAssignmentState>(
                listener: (context, state) {
                  if (state is UploadAssignmentFetchSuccess) {
                    Get.back(result: {
                      "error": false,
                      "assignmentSubmission": state.assignmentSubmission,
                      "answerText": _answerController.text,
                    });
                  } else if (state is UploadAssignmentFailure) {
                    Get.back(
                        result: {"error": true, "message": state.errorMessage});
                  }
                },
                builder: (context, state) {
                  return CustomRoundedButton(
                    onTap: () {
                      // Dismiss the keyboard if it's showing
                      FocusScope.of(context).unfocus();

                      if (state is UploadAssignmentInProgress) return;

                      final bool isTextEnabled = widget.assignment.isText;
                      final bool isFileEnabled = widget.assignment.filetypes.isNotEmpty;

                      if (isTextEnabled && isFileEnabled) {
                        if (_answerController.text.isEmpty && uploadedFiles.isEmpty) {
                          Utils.showCustomSnackBar(
                            context: context,
                            errorMessage: "Kamu harus mengisi teks atau melampirkan file terlebih dahulu",
                            backgroundColor: Theme.of(context).colorScheme.error,
                          );
                          return;
                        }
                      } else if (isTextEnabled) {
                        if (_answerController.text.isEmpty) {
                          Utils.showCustomSnackBar(
                            context: context,
                            errorMessage: "Kamu harus mengisi teks terlebih dahulu",
                            backgroundColor: Theme.of(context).colorScheme.error,
                          );
                          return;
                        }
                      } else if (isFileEnabled) {
                        if (uploadedFiles.isEmpty) {
                          Utils.showCustomSnackBar(
                            context: context,
                            errorMessage: "Kamu harus melampirkan file terlebih dahulu",
                            backgroundColor: Theme.of(context).colorScheme.error,
                          );
                          return;
                        }
                      }

                      context.read<UploadAssignmentCubit>().uploadAssignment(
                            assignmentId: widget.assignment.id,
                            filePaths: uploadedFiles
                                .map((file) => file.path!)
                                .toList(),
                            answerText:
                                _answerController.text.isNotEmpty == true
                                    ? _answerController.text
                                    : null,
                          );
                    },
                    height: 50,
                    widthPercentage:
                        state is UploadAssignmentInProgress ? 0.70 : 0.40,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    buttonTitle: state is UploadAssignmentInProgress
                        ? "${Utils.getTranslatedLabel(submittingKey)} (${state.uploadedProgress.toStringAsFixed(2)}%)"
                        : Utils.getTranslatedLabel(submitKey),
                    showBorder: false,
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

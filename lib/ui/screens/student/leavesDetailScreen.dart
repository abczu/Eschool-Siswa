import 'package:eschool/data/models/student/leave.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:eschool/ui/widgets/system/svgButton.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LeavesDetailScreen extends StatefulWidget {
  final Leave leave;

  const LeavesDetailScreen({Key? key, required this.leave}) : super(key: key);

  @override
  _LeavesDetailScreenState createState() => _LeavesDetailScreenState();
}

class _LeavesDetailScreenState extends State<LeavesDetailScreen> {
  Widget _buildAttachmentItem(LeaveDetail detail) {
    bool isImage = detail.fileExtension != null &&
        ['jpg', 'jpeg', 'png', 'gif']
            .contains(detail.fileExtension!.toLowerCase());

    return GestureDetector(
      onTap: () {
        if (detail.fileUrl != null) {
          _showAttachmentDialog(context, detail);
        }
      },
      child: Container(
        margin: EdgeInsets.only(right: 8),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300] ?? Colors.grey),
        ),
        child: isImage && detail.fileUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: detail.fileUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      _buildFileTypeIcon(detail),
                  placeholder: (context, url) =>
                      Center(child: CircularProgressIndicator()),
                ),
              )
            : _buildFileTypeIcon(detail),
      ),
    );
  }

  Widget _buildFileTypeIcon(LeaveDetail detail) {
    IconData iconData;
    Color iconColor;

    switch (detail.fileExtension?.toLowerCase()) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'doc':
      case 'docx':
        iconData = Icons.description;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(iconData, color: iconColor, size: 32),
        if (detail.fileName != null) ...[
          SizedBox(height: 4),
          Text(
            detail.fileName!,
            style: TextStyle(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  void _showAttachmentDialog(BuildContext context, LeaveDetail detail) {
    bool isImage = detail.fileExtension != null &&
        ['jpg', 'jpeg', 'png', 'gif']
            .contains(detail.fileExtension!.toLowerCase());

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(detail.fileName ?? 'Lampiran'),
              leading: IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                // if (detail.fileUrl != null)
                // IconButton(
                //   icon: Icon(Icons.download),
                //   onPressed: () {
                //     print("ONGKEH");
                // showModalBottomSheet(
                //   context: context,
                //   builder: (_) => DownloadFileBottomsheetContainer(
                //     studyMaterial: StudyMaterial(
                //         fileExtension: detail.fileExtension ?? "",
                //         fileUrl: detail.fileUrl ?? "",
                //         fileThumbnail: "",
                //         fileName: detail.fileName ?? 'Lampiran',
                //         id: 1,
                //         studyMaterialType: getStudyMaterialType(1)),
                //     storeInExternalStorage: true,
                //   ),
                // );
                //   },
                // ),
              ],
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: MediaQuery.of(context).size.width,
              ),
              child: isImage && detail.fileUrl != null
                  ? CachedNetworkImage(
                      imageUrl: detail.fileUrl!,
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) => Center(
                          child: Text(Utils.getTranslatedLabel(
                              error_loading_imageKey))),
                      placeholder: (context, url) =>
                          Center(child: CircularProgressIndicator()),
                    )
                  : Center(
                      child: Text(Utils.getTranslatedLabel(
                        'preview_not_availableKey',
                      )),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: Utils.getScrollViewTopPadding(
                context: context,
                appBarHeightPercentage: Utils.appBarMediumtHeightPercentage,
              ),
              bottom: 20,
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Text(
                              //   '',
                              //   style: TextStyle(
                              //     fontSize: 0,
                              //     fontWeight: FontWeight.bold,
                              //   ),
                              // ),
                              // _buildStatusChip(widget.leave.status),
                              Text(
                                'Izinn',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Text(_formatDateRange(widget.leave.fromDate, widget.leave.toDate)),
                              // Text(_formatDateRange(widget.leave.fromDate)),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (widget.leave.leaveDetail
                                      .any((detail) => !detail.isFile))
                                    Chip(
                                      label: Text(
                                        widget.leave.leaveDetail
                                            .firstWhere(
                                                (detail) => !detail.isFile)
                                            .formattedDate,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor:
                                          Theme.of(context).colorScheme.surface,
                                    ),
                                ],
                              )
                            ],
                          ),
                          Text(
                            'Alasan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            widget.leave.reason,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.leave.fileDetail.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      'Lampiran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: widget.leave.fileDetail
                            .map((detail) => _buildAttachmentItem(detail))
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top +
                    Utils.screenContentTopPadding * 1.5,
              ),
              alignment: Alignment.topCenter,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height *
                  Utils.appBarSmallerHeightPercentage,
              color: Utils.getColorScheme(context).primary,
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  return Stack(
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: Utils.screenContentHorizontalPadding,
                          ),
                          child: SvgButton(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            svgIconUrl: Utils.getBackButtonPath(context),
                          ),
                        ),
                      ),
                      Align(
                        child: Container(
                          alignment: Alignment.center,
                          width: boxConstraints.maxWidth * 0.6,
                          child: Text(
                            Utils.getTranslatedLabel(leaveDetailKey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: Utils.screenTitleFontSize,
                              color: Theme.of(context).scaffoldBackgroundColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

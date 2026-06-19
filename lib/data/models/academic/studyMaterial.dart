enum StudyMaterialType { file, youtubeVideo, uploadedVideoUrl, other }

StudyMaterialType getStudyMaterialType(int type) {
  if (type == 1) {
    return StudyMaterialType.file;
  }
  if (type == 2) {
    return StudyMaterialType.youtubeVideo;
  }
  if (type == 3) {
    return StudyMaterialType.uploadedVideoUrl;
  }

  return StudyMaterialType.other;
}

class StudyMaterial {
  final StudyMaterialType studyMaterialType;

  final int id;
  final String fileName;
  final String fileThumbnail;
  final String fileUrl;
  final String fileExtension;

  StudyMaterial({
    required this.fileExtension,
    required this.fileUrl,
    required this.fileThumbnail,
    required this.fileName,
    required this.id,
    required this.studyMaterialType,
  });

  factory StudyMaterial.fromJson(Map<String, dynamic> json) {
    return StudyMaterial(
      studyMaterialType: getStudyMaterialType(
          int.tryParse(json['type']?.toString() ?? "0") ?? 0),
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      fileName: json['file_name'] ?? "",
      fileThumbnail: json['file_thumbnail'] ?? "",
      fileUrl: json['file_url']?.toString() ?? "",
      fileExtension: json['file_extension'] ?? "",
    );
  }
}

import 'package:eschool/data/models/system/galleryFile.dart';

class Gallery {
  final int? id;
  final String? title;
  final String? description;
  final String? thumbnail;
  final int? sessionYearId;
  final int? schoolId;
  final String? createdAt;
  final String? updatedAt;
  final List<GalleryFile>? files;
  final String? thumbnailFileExtension;

  Gallery(
      {this.id,
      this.thumbnailFileExtension,
      this.title,
      this.description,
      this.thumbnail,
      this.sessionYearId,
      this.schoolId,
      this.createdAt,
      this.updatedAt,
      this.files});

  Gallery copyWith({
    int? id,
    String? title,
    String? description,
    String? thumbnail,
    int? sessionYearId,
    int? schoolId,
    String? createdAt,
    String? updatedAt,
    List<GalleryFile>? files,
    String? thumbnailFileExtension,
  }) {
    return Gallery(
      thumbnailFileExtension:
          thumbnailFileExtension ?? this.thumbnailFileExtension,
      files: files ?? this.files,
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnail: thumbnail ?? this.thumbnail,
      sessionYearId: sessionYearId ?? this.sessionYearId,
      schoolId: schoolId ?? this.schoolId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Gallery.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        thumbnailFileExtension = json['file_extension'] as String?,
        title = json['title'] as String?,
        description = json['description'] as String?,
        thumbnail = json['thumbnail'] as String?,
        sessionYearId = json['session_year_id'] as int?,
        schoolId = json['school_id'] as int?,
        createdAt = json['created_at'] as String?,
        files = ((json['file'] ?? []) as List)
            .map((galleryFile) => GalleryFile.fromJson(galleryFile ?? {}))
            .toList(),
        updatedAt = json['updated_at'] as String?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'file_extension': thumbnailFileExtension,
        'description': description,
        'thumbnail': thumbnail,
        'session_year_id': sessionYearId,
        'school_id': schoolId,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'file': files?.map((e) => e.toJson()).toList(),
      };

  /// Returns video files (Type 2 = YouTube Video, Type 3 = Direct Uploaded Video)
  List<GalleryFile> getVideos() {
    return (files ?? []).where((element) => element.isVideo()).toList();
  }

  /// Returns image files (Type 1 = Image File Upload)
  List<GalleryFile> getImages() {
    return (files ?? []).where((element) => element.isImage()).toList();
  }

  bool isThumbnailSvg() {
    final url = thumbnail?.toLowerCase() ?? "";
    if (url.endsWith(".jpg") || url.endsWith(".jpeg") || url.endsWith(".png")) {
      return false;
    }
    return (thumbnailFileExtension?.toLowerCase() == "svg") ||
        url.endsWith(".svg");
  }
}

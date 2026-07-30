class Extracurricular {
  final int? id;
  final String? title;
  final String? description;
  final String? image;
  final String? instructor;
  final int? coachId;
  final String? schedule;
  final String? location;
  final int? maxParticipants;
  final int? currentParticipants;
  final String? status;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  Extracurricular({
    this.id,
    this.title,
    this.description,
    this.image,
    this.instructor,
    this.coachId,
    this.schedule,
    this.location,
    this.maxParticipants,
    this.currentParticipants,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  Extracurricular copyWith({
    int? id,
    String? title,
    String? description,
    String? image,
    String? instructor,
    int? coachId,
    String? schedule,
    String? location,
    int? maxParticipants,
    int? currentParticipants,
    String? status,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
  }) {
    return Extracurricular(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      instructor: instructor ?? this.instructor,
      coachId: coachId ?? this.coachId,
      schedule: schedule ?? this.schedule,
      location: location ?? this.location,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory Extracurricular.fromJson(Map<String, dynamic> json) {
    // Logic Pencarian Jadwal (Smart Detection)
    String? scheduleData;

    // 1. Helper function for list formatting
    String? formatScheduleList(dynamic list) {
      if (list is! List || list.isEmpty) return null;
      
      String formatTime(dynamic time) {
        if (time == null) return '';
        String t = time.toString();
        if (t.contains(':') && t.split(':').length == 3) {
          return t.substring(0, 5); // Keep only HH:mm
        }
        return t;
      }
      
      return list.map((t) {
        if (t is Map) {
          String day = t['day'] ?? t['hari'] ?? '';
          
          // Translate English days to Indonesian
          final dayTranslations = {
            'Monday': 'Senin',
            'Tuesday': 'Selasa',
            'Wednesday': 'Rabu',
            'Thursday': 'Kamis',
            'Friday': 'Jumat',
            'Saturday': 'Sabtu',
            'Sunday': 'Minggu',
          };
          if (dayTranslations.containsKey(day)) {
            day = dayTranslations[day]!;
          }
          
          final startTime = formatTime(t['start_time'] ?? t['jam_mulai'] ?? t['time'] ?? t['jam'] ?? '');
          final endTime = formatTime(t['end_time'] ?? t['jam_selesai'] ?? '');
          
          if (startTime.isNotEmpty && endTime.isNotEmpty) {
            return '$day ($startTime - $endTime)';
          } else if (startTime.isNotEmpty) {
            return '$day ($startTime)';
          }
          return day.toString();
        }
        return t.toString();
      }).where((s) => s.isNotEmpty).join('\n');
    }

    // 2. Try to find schedule in various fields
    if (json['schedule'] != null) {
      if (json['schedule'] is List) {
        scheduleData = formatScheduleList(json['schedule']);
      } else if (json['schedule'].toString().isNotEmpty) {
        scheduleData = json['schedule'].toString();
      }
    }
    
    if (scheduleData == null && json['jadwal'] != null) {
      if (json['jadwal'] is List) {
        scheduleData = formatScheduleList(json['jadwal']);
      } else if (json['jadwal'].toString().isNotEmpty) {
        scheduleData = json['jadwal'].toString();
      }
    }
    
    if (scheduleData == null && json['timetables'] != null) {
      if (json['timetables'] is List) {
        scheduleData = formatScheduleList(json['timetables']);
      } else if (json['timetables'].toString().isNotEmpty) {
        scheduleData = json['timetables'].toString();
      }
    }

    return Extracurricular(
      id: _parseInt(json['id']),
      title: json['name']?.toString(),
      description: json['description']?.toString(),
      image: json['image']?.toString(),
      instructor: json['coach_name']?.toString() ??
          json['coach']?['full_name']?.toString() ??
          '${json['coach']?['first_name'] ?? ''} ${json['coach']?['last_name'] ?? ''}'
              .trim(),
      coachId: _parseInt(json['coach_id']),
      schedule: (scheduleData == null ||
              scheduleData.isEmpty ||
              scheduleData == 'null')
          ? null
          : scheduleData,
      location: json['location']?.toString(),
      maxParticipants: _parseInt(json['max_participants']),
      currentParticipants: _parseInt(json['current_participants']),
      status: json['status']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      deletedAt: json['deleted_at']?.toString(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': title, // Konsisten dengan API response
      'description': description,
      'image': image,
      'coach_name': instructor, // Konsisten dengan API response
      'coach_id': coachId,
      'schedule': schedule,
      'location': location,
      'max_participants': maxParticipants,
      'current_participants': currentParticipants,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  bool get isAvailable => 
      (maxParticipants == null || currentParticipants == null) ||
      (currentParticipants! < maxParticipants!);

  double get participationPercentage {
    if (maxParticipants == null || currentParticipants == null || maxParticipants == 0) {
      return 0.0;
    }
    return (currentParticipants! / maxParticipants!) * 100;
  }

  @override
  String toString() {
    return 'Extracurricular{id: $id, title: $title, instructor: $instructor}';
  }
}

import 'package:flutter/foundation.dart';

class StudentProfileExtraDetails {
  final int? id;
  final int? studentId;
  final int? formFieldId;
  final String? data;
  final int? schoolId;
  final FormField? formField;

  StudentProfileExtraDetails({
    this.id,
    this.studentId,
    this.formFieldId,
    this.data,
    this.schoolId,
    this.formField,
  });

  StudentProfileExtraDetails copyWith(
      {int? id,
      int? studentId,
      int? formFieldId,
      String? data,
      int? schoolId,
      FormField? formField}) {
    return StudentProfileExtraDetails(
        id: id ?? this.id,
        studentId: studentId ?? this.studentId,
        formFieldId: formFieldId ?? this.formFieldId,
        data: data ?? this.data,
        schoolId: schoolId ?? this.schoolId,
        formField: formField ?? this.formField);
  }

  StudentProfileExtraDetails.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        studentId = json['student_id'] as int?,
        formFieldId = json['form_field_id'] as int?,
        data = json['data']?.toString(),
        formField = _parseFormField(json),
        schoolId = json['school_id'] as int? {
    debugPrint("🔍 [ExtraDetails.fromJson] raw json: $json -> formField.name: '${formField?.name}'");
  }

  static FormField _parseFormField(Map<String, dynamic> json) {
    Map<String, dynamic> fieldMap = Map.from(
      json['form_field'] ??
          json['formfield'] ??
          json['form_fields'] ??
          json['field'] ??
          json['field_details'] ??
          json['form_field_details'] ??
          {},
    );

    FormField parsed = FormField.fromJson(fieldMap);
    if (parsed.name == null || parsed.name!.trim().isEmpty) {
      final rootName = (json['name'] ??
              json['label'] ??
              json['form_field_name'] ??
              json['title'] ??
              json['field_name'] ??
              json['input_label'] ??
              json['field_label'] ??
              json['question'] ??
              json['header'] ??
              json['slug'] ??
              json['key'])
          ?.toString()
          .trim();

      if (rootName != null && rootName.isNotEmpty) {
        parsed = parsed.copyWith(name: rootName);
      }
    }
    return parsed;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'form_field_id': formFieldId,
        'data': data,
        'school_id': schoolId,
        'form_field': formField?.toJson()
      };
}

//
class FormField {
  final int? id;
  final String? name;

  FormField({
    this.id,
    this.name,
  });

  FormField copyWith({
    int? id,
    String? name,
  }) {
    return FormField(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  FormField.fromJson(Map<String, dynamic> json)
      : id = (json['id'] ?? json['form_field_id']) as int?,
        name = (json['name'] ??
                json['label'] ??
                json['title'] ??
                json['field_name'] ??
                json['form_field_name'] ??
                json['input_label'] ??
                json['field_label'] ??
                json['question'] ??
                json['header'] ??
                json['slug'] ??
                json['key'])
            ?.toString()
            .trim();

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

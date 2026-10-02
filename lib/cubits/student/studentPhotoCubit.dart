import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:bloc/bloc.dart';
import 'package:eschool/data/models/auth/student.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eschool/data/repositories/student/studentProfileRepository.dart';

/// State
abstract class StudentPhotoState {}

class StudentPhotoInitial extends StudentPhotoState {}

class StudentPhotoInProgress extends StudentPhotoState {}

class StudentPhotoSuccess extends StudentPhotoState {
  final Student data;
  StudentPhotoSuccess({required this.data});
}

class StudentPhotoFailure extends StudentPhotoState {
  final String errorMessage;
  StudentPhotoFailure(this.errorMessage);
}

/// Cubit untuk ubah foto profil siswa sendiri.
/// Mirip pola GuardianPhotoCubit: emit InProgress -> Success/Failure.
class StudentPhotoCubit extends Cubit<StudentPhotoState> {
  final StudentProfileRepository _repository;

  StudentPhotoCubit(this._repository) : super(StudentPhotoInitial());

  void updateStudentPhoto({
    required XFile file,
  }) {
    emit(StudentPhotoInProgress());
    debugPrint("StudentPhotoCubit: uploading ${file.path}");
    _repository
        .updateStudentPhoto(filePath: file.path)
        .then((r) => emit(StudentPhotoSuccess(data: r)))
        .catchError(
      (e) => emit(StudentPhotoFailure(e.toString())),
    );
  }

  void reset() => emit(StudentPhotoInitial());
}

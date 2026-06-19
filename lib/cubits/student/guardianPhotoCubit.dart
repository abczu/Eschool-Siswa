import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:bloc/bloc.dart';
import 'package:eschool/data/models/auth/guardian.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eschool/data/repositories/auth/guardianProfileRepository.dart';

/// State
abstract class GuardianPhotoState {}

class GuardianPhotoInitial extends GuardianPhotoState {}

class GuardianPhotoInProgress extends GuardianPhotoState {}

class GuardianPhotoSuccess extends GuardianPhotoState {
  final Guardian data;
  GuardianPhotoSuccess({required this.data});
}

class GuardianPhotoFailure extends GuardianPhotoState {
  final String errorMessage;
  GuardianPhotoFailure(this.errorMessage);
}

/// Cubit
class GuardianPhotoCubit extends Cubit<GuardianPhotoState> {
  final GuardianProfileRepository _repository;

  GuardianPhotoCubit(this._repository) : super(GuardianPhotoInitial());

  /// Konsisten dengan pola ExamDetailsCubit: emit InProgress -> Success/Failure
  void updateGuardianPhoto({
    required Guardian guardian,
    required int childId,
    XFile? file,
  }) {
    emit(GuardianPhotoInProgress());
    debugPrint("dicubit");
    _repository
        .updateGuardianPhoto(
      guardianData: guardian,
      filePath: file != null ? file.path : "",
      childId: childId,
    )
        .then((r) => emit(GuardianPhotoSuccess(data: r)))
        .catchError(
      (e) => emit(GuardianPhotoFailure(e.toString())),
    );
    debugPrint("dicubit2");
  }
}



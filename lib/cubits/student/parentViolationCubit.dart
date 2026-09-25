import 'package:equatable/equatable.dart';
import 'package:eschool/data/models/student/violation.dart';
import 'package:eschool/data/repositories/student/violationRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ParentViolationState extends Equatable {
  const ParentViolationState();
}

class ParentViolationInitial extends ParentViolationState {
  @override
  List<Object?> get props => [];
}

class ParentViolationFetchInProgress extends ParentViolationState {
  @override
  List<Object?> get props => [];
}

class ParentViolationFetchSuccess extends ParentViolationState {
  final ViolationSummary summary;

  const ParentViolationFetchSuccess({required this.summary});

  @override
  List<Object?> get props => [summary];
}

class ParentViolationFetchFailure extends ParentViolationState {
  final String errorMessage;

  const ParentViolationFetchFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

/// Cubit untuk sisi Orang Tua:
/// GET /api/parent/violations?child_id={student_id}
class ParentViolationCubit extends Cubit<ParentViolationState> {
  final ViolationRepository _violationRepository;

  ParentViolationCubit(this._violationRepository)
      : super(ParentViolationInitial());

  Future<void> fetchChildViolation({required int studentId}) async {
    emit(ParentViolationFetchInProgress());
    try {
      final summary = await _violationRepository.fetchChildViolation(
        studentId: studentId,
      );
      emit(ParentViolationFetchSuccess(summary: summary));
    } catch (e) {
      emit(ParentViolationFetchFailure(e.toString()));
    }
  }
}

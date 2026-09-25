import 'package:equatable/equatable.dart';
import 'package:eschool/data/models/student/violation.dart';
import 'package:eschool/data/repositories/student/violationRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ViolationState extends Equatable {
  const ViolationState();
}

class ViolationInitial extends ViolationState {
  @override
  List<Object?> get props => [];
}

class ViolationFetchInProgress extends ViolationState {
  @override
  List<Object?> get props => [];
}

class ViolationFetchSuccess extends ViolationState {
  final ViolationSummary summary;

  const ViolationFetchSuccess({required this.summary});

  @override
  List<Object?> get props => [summary];
}

class ViolationFetchFailure extends ViolationState {
  final String errorMessage;

  const ViolationFetchFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class ViolationCubit extends Cubit<ViolationState> {
  final ViolationRepository _violationRepository;

  ViolationCubit(this._violationRepository) : super(ViolationInitial());

  Future<void> fetchSummary() async {
    emit(ViolationFetchInProgress());
    try {
      final summary = await _violationRepository.fetchViolationSummary();
      emit(ViolationFetchSuccess(summary: summary));
    } catch (e) {
      emit(ViolationFetchFailure(e.toString()));
    }
  }
}

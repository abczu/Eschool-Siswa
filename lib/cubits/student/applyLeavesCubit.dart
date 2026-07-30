import 'package:eschool/data/repositories/student/leavesRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class ApplyLeaveCubit extends Cubit<ApplyLeaveState> {
  final LeavesRepository _leavesRepository;

  ApplyLeaveCubit(this._leavesRepository) : super(ApplyLeaveInitial());

  Future<void> applyLeave({
    required int childId,
    required String reason,
    required List<Map<String, String>> leaveDetails,
    List<String>? files,
    int? leaveId,
  }) async {
    try {
      // Kompresi sudah dilakukan di UI (saat pilih file).
      emit(ApplyLeaveUploading());

      await _leavesRepository.applyLeave(
        childId: childId,
        reason: reason,
        leaveDetails: leaveDetails,
        files:
            files, // file sudah siap (termasuk hasil kompres dari UI jika ada)
        leaveId: leaveId,
      );

      emit(ApplyLeaveSuccess());
    } catch (e) {
      emit(ApplyLeaveFailure(e.toString()));
    }
  }
}

abstract class ApplyLeaveState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ApplyLeaveInitial extends ApplyLeaveState {}

class ApplyLeaveUploading extends ApplyLeaveState {}

class ApplyLeaveSuccess extends ApplyLeaveState {}

class ApplyLeaveFailure extends ApplyLeaveState {
  final String errorMessage;
  ApplyLeaveFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

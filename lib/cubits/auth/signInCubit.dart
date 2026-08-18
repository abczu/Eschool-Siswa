import 'package:equatable/equatable.dart';
import 'package:eschool/data/models/auth/guardian.dart';
import 'package:eschool/data/models/auth/student.dart';
import 'package:eschool/data/repositories/auth/authRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SignInState extends Equatable {}

class SignInInitial extends SignInState {
  @override
  List<Object?> get props => [];
}

class SignInInProgress extends SignInState {
  @override
  List<Object?> get props => [];
}

class SignInSuccess extends SignInState {
  final String jwtToken;
  final bool isStudentLogIn;
  final Student student;
  final String schoolCode;
  final Guardian parent;
  final List<Student> children;
  final List<Map<String, dynamic>> schools;

  SignInSuccess({
    required this.jwtToken,
    required this.isStudentLogIn,
    required this.student,
    required this.parent,
    required this.schoolCode,
    this.children = const [],
    this.schools = const [],
  });

  @override
  List<Object?> get props => [jwtToken, isStudentLogIn, student, children, schools];
}

class SignInFailure extends SignInState {
  final String errorMessage;

  SignInFailure(this.errorMessage);

  @override
  List<Object?> get props => [];
}

class OtpRequestInProgress extends SignInState {
  @override
  List<Object?> get props => [];
}

class OtpRequestSuccess extends SignInState {
  @override
  List<Object?> get props => [];
}

class OtpRequestFailure extends SignInState {
  final String errorMessage;
  OtpRequestFailure(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
}

class OtpRequestFailure444 extends SignInState {
  @override
  List<Object?> get props => [];
}

class OtpRequestFailure429 extends SignInState {
  @override
  List<Object?> get props => [];
}

class OtpVerifyInProgress extends SignInState {
  @override
  List<Object?> get props => [];
}

class OtpVerifyFailure extends SignInState {
  final String errorMessage;
  OtpVerifyFailure(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
}

class SignInCubit extends Cubit<SignInState> {
  final AuthRepository _authRepository;

  SignInCubit(this._authRepository) : super(SignInInitial());

  Future<void> signInUser({
    required String userId,
    required String password,
    String? schoolCode,
    required bool isStudentLogin,
  }) async {
    emit(SignInInProgress());

    try {
      late Map<String, dynamic> result;

      if (isStudentLogin) {
        result = await _authRepository.signInStudent(
          grNumber: userId,
          schoolCode: schoolCode!,
          password: password,
        );
      } else {
        result = await _authRepository.signInParent(
          email: userId,
          password: password,
        );
      }

      emit(
        SignInSuccess(
          schoolCode: result['schoolCode'] ?? '',
          jwtToken: result['jwtToken'],
          isStudentLogIn: isStudentLogin,
          student: isStudentLogin ? result['student'] : Student.fromJson({}),
          parent: isStudentLogin ? Guardian.fromJson({}) : result['parent'],
          children: result['children'] ?? [],
        ),
      );
    } catch (e) {
      emit(SignInFailure(e.toString()));
    }
  }

  Future<void> requestOtp({required String identifier}) async {
    emit(OtpRequestInProgress());
    try {
      await _authRepository.requestOtp(identifier: identifier);
      emit(OtpRequestSuccess());
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('444') || errorStr.contains('404')) {
        emit(OtpRequestFailure444());
      } else if (errorStr.contains('429')) {
        emit(OtpRequestFailure429());
      } else {
        emit(OtpRequestFailure(errorStr));
      }
    }
  }

  Future<void> verifyOtp({
    required String identifier,
    required String otpCode,
  }) async {
    emit(OtpVerifyInProgress());
    try {
      final result = await _authRepository.verifyOtp(
        identifier: identifier,
        otpCode: otpCode,
      );

      final isStudent = result['userType'] == 'student';

      emit(
        SignInSuccess(
          schoolCode: result['schoolCode'] ?? '',
          jwtToken: result['jwtToken'],
          isStudentLogIn: isStudent,
          student: result['student'],
          parent: result['parent'],
          children: result['children'] ?? [],
          schools: result['schools'] ?? [],
        ),
      );
    } catch (e) {
      emit(OtpVerifyFailure(e.toString()));
    }
  }
}

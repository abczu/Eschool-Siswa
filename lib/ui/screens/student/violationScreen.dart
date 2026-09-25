import 'package:eschool/cubits/student/violationCubit.dart';
import 'package:eschool/data/repositories/student/violationRepository.dart';
import 'package:eschool/ui/widgets/student/violationContainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ViolationScreen extends StatelessWidget {
  const ViolationScreen({Key? key}) : super(key: key);

  static Widget routeInstance() {
    return BlocProvider<ViolationCubit>(
      create: (_) => ViolationCubit(ViolationRepository()),
      child: const ViolationScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ViolationContainer(),
    );
  }
}

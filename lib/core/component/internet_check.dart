// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:chat_web/controller/internet_cubit/internet_connection_cubit.dart';
// import 'package:chat_web/core/component/internet_error.dart';
// import 'package:chat_web/core/component/loading_widget.dart';

// class InternetCheckWidget extends StatelessWidget {
//   const InternetCheckWidget({super.key, required this.child,required this.onRefresh});
//   final Widget child;
//   final VoidCallback onRefresh;
  

//   @override
//   Widget build(BuildContext context) {
//     return BlocConsumer<InternetConnectionCubit, InternetConnectionState>(
//       listener: (context, state) {
//         if (state is InternetConnectedState) {
//           onRefresh();
//         } else {}
//       },
//       builder: (context, state) {
//         if (state is InternetConnectedState) {
//           return child;
//         } else if (state is InternetDisconnectedState) {
//           return const Center(child: InternetErrorWidget());
//         } else if (state is InternetLoadingState) {
//           return const LoadingWidget();
//         } else {
//           return Container();
//         }
//       },
//     );
//   }
// }

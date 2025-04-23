// import 'package:flutter/widgets.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// class ScaleOnTap extends StatefulWidget {
//   final Widget child;
//   final VoidCallback? onTap;
//   final Offset offset;
//   final int durationMilliseconds;

//   ScaleOnTap({
//     super.key,
//     this.onTap,
//     double scale = 0.96,
//     this.durationMilliseconds = 100,
//     required this.child,
//   }) : offset = Offset(scale, scale);

//   @override
//   State<ScaleOnTap> createState() => _ScaleOnTapState();
// }

// class _ScaleOnTapState extends State<ScaleOnTap> with TickerProviderStateMixin {
  
//   late AnimationController _controller;

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 80),
//       vsync: this,
//     );
//   }

//   bool _longPress = false;

//   void _callBack() {
//     if (widget.onTap != null) {
//       widget.onTap!();

//       _controller.reverse();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       behavior: HitTestBehavior.opaque,
//       onTap: widget.onTap == null ? null : () => _controller.forward(),
//       onLongPress: widget.onTap == null
//           ? null
//           : () {
//               _longPress = true;
//               _controller.forward();
//             },
//       onLongPressEnd: widget.onTap == null
//           ? null
//           : (details) {
//               setState(() {
//                 _longPress = false;
//                 _callBack();
//               });
//             },
//       child: widget.child
//           .animate(
//             controller: _controller,
//             autoPlay: false,
//             onComplete: (controller) {
//               if (!_longPress &&
//                   controller.status == AnimationStatus.completed) {
//                 _callBack();
//               }
//             },
//           )
//           .scale(
//             curve: Curves.easeIn,
//             begin: const Offset(1, 1),
//             end: widget.offset,
//             duration: Duration(milliseconds: widget.durationMilliseconds),
//           ),
//     );
//   }
// }

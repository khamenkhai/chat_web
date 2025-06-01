import 'package:chat_web/core/utils/context_extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.color, this.radius = 15});
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return LoadingAnimationWidget.discreteCircle(
      color: color ?? context.primaryColor,
      size: radius,
    );
  }
}

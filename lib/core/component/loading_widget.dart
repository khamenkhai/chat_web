import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.color, this.radius = 10});
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CupertinoActivityIndicator(
      color: color ?? Theme.of(context).primaryColor,
      radius: radius,
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_web/core/component/loading_widget.dart';
import 'package:flutter/material.dart';

class CustomNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Image.network(
    //   imageUrl,
    //   errorBuilder: (context, error, stackTrace) {
    //     return const Icon(Icons.error); // or a placeholder image
    //   },
    // );

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width ?? 100,
      height: height ?? 100,
      fit: fit,
      placeholder: (context, url) => placeholder ?? const LoadingWidget(),
      errorWidget: (context, url, error) =>
          errorWidget ??
          const Center(
            child: Icon(
              Icons.broken_image,
              size: 50,
              color: Colors.grey,
            ),
          ),
    );
  }
}

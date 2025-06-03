import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_web/core/component/custom_network_image.dart';
import 'package:flutter/material.dart';
import 'package:chat_web/chat_service/models/message_models.dart' as types;
import 'package:photo_view/photo_view.dart';

class ImageMessageTile extends StatelessWidget {
  const ImageMessageTile({super.key, required this.message});
  final types.Message message;

  @override
  Widget build(BuildContext context) {
    final imageUrl = (message as types.ImageMessage).uri;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              // backgroundColor: Colors.black,
              appBar: AppBar(),
              body: Center(
                child: PhotoView(
                  imageProvider: CachedNetworkImageProvider(imageUrl),
                  backgroundDecoration:
                      const BoxDecoration(color: Colors.black),
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: const Radius.circular(12),
            bottomRight: const Radius.circular(12),
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: CachedImage(
            imageUrl: imageUrl,
            width: 220,
            height: 220,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

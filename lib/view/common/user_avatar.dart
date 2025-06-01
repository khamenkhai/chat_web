import 'package:chat_web/core/component/custom_network_image.dart';
import 'package:flutter/material.dart';
import 'package:chat_web/chat_service/models/message_models.dart' as types;
import 'package:photo_view/photo_view.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.room,
    this.size,
    this.image,
  });

  final types.Room room;
  final double? size;
  final String? image;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final imageUrl = image ?? room.imageUrl;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _FullImageViewer(imageUrl: imageUrl),
            ),
          );
        }
      },
      child: _buildAvatar(room),
    );
  }

  Widget _buildAvatar(types.Room room) {
    final name = room.name ?? '';

    return SizedBox(
      width: size ?? 40,
      height: size ?? 40,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: CustomNetworkImage(
          imageUrl: image ?? room.imageUrl ?? "",
          fit: BoxFit.cover,
          errorWidget: Center(
            child: Text(
              name.isEmpty ? '' : name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}


class _FullImageViewer extends StatelessWidget {
  const _FullImageViewer({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        ),
      ),
    );
  }
}

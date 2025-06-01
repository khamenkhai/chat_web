import 'package:flutter/material.dart';
import 'package:chat_web/chat_service/models/message_models.dart' as types;
import 'package:iconly/iconly.dart';
import 'package:photo_view/photo_view.dart';

class ImageMessageTile extends StatelessWidget {
  const ImageMessageTile({super.key,required this.message});
  final types.Message message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                  imageProvider: NetworkImage(imageUrl),
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
          borderRadius:BorderRadius.only(
      bottomLeft: const Radius.circular(12),
      bottomRight: const Radius.circular(12),
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
    ),
          child: Image.network(
            imageUrl,
            width: 220,
            height: 220,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return _buildImageLoadingIndicator(progress);
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildImageErrorPlaceholder(colorScheme);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImageLoadingIndicator(ImageChunkEvent progress) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Center(
        child: CircularProgressIndicator(
          value: progress.expectedTotalBytes != null
              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }

  Widget _buildImageErrorPlaceholder(ColorScheme colorScheme) {
    return Container(
      width: 220,
      height: 220,
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          IconlyLight.image,
          size: 48,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

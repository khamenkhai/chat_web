import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_web/core/component/custom_network_image.dart';
import 'package:flutter/material.dart';
import 'package:chat_web/chat_service/models/message_models.dart' as types;
import 'package:photo_view/photo_view.dart';

class ImageMessageTile extends StatelessWidget {
  final types.Message message;

  const ImageMessageTile({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (message as types.ImageMessage).uri;

    return GestureDetector(
      onTap: () => _openImageViewer(context, imageUrl),
      child: Container(
        margin: const EdgeInsets.all(3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedImage(
            imageUrl: imageUrl,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  void _openImageViewer(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              body: Center(
                child: PhotoView(
                  imageProvider: CachedNetworkImageProvider(imageUrl),
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                ),
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }
}

// class ImageMessageTile extends StatelessWidget {
//   const ImageMessageTile({super.key, required this.message});
//   final types.Message message;

//   @override
//   Widget build(BuildContext context) {
//     final imageUrl = (message as types.ImageMessage).uri;

//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => Scaffold(
//               backgroundColor: Colors.black,
//               appBar: AppBar(
//                 backgroundColor: Colors.black,
//                 foregroundColor: Colors.white,
//                 leading: IconButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   icon: const Icon(
//                     Icons.arrow_back,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//               body: Center(
//                 child: PhotoView(
//                   imageProvider: CachedNetworkImageProvider(imageUrl),
//                   backgroundDecoration:
//                       const BoxDecoration(color: Colors.black),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 5),
//         child: ClipRRect(
//           borderRadius: const BorderRadius.only(
//             bottomLeft: Radius.circular(12),
//             bottomRight: Radius.circular(12),
//             topLeft: Radius.circular(12),
//             topRight: Radius.circular(12),
//           ),
//           child: CachedImage(
//             imageUrl: imageUrl,
//             width: 220,
//             height: 220,
//             fit: BoxFit.cover,
//           ),
//         ),
//       ),
//     );
//   }
// }

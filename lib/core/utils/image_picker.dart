// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:image_cropper/image_cropper.dart';
// import 'package:image_picker/image_picker.dart';

// class ImagePickerUtil {
  
//   /// make single pattern to the image picker class so that it doesn't recreate on the memory it self
//   static final ImagePickerUtil _instance = ImagePickerUtil._internal();
//   factory ImagePickerUtil() => _instance;
//   ImagePickerUtil._internal();

//   /// select image
//   Future<File?> selectImage({required bool isGallery}) async {
//     final File? file = await pickImage(
//       isGallery: isGallery,
//       cropImage: cropSquareImage,
//     );

//     return file;
//   }

//   /// select image and convert to base 4
//   Future<String?> selectImageAndConvertToBase64(
//       {required bool isGallery}) async {
//     final File? file = await pickImage(
//       isGallery: isGallery,
//       cropImage: cropSquareImage,
//     );

//     String? base64Strig;

//     if (file != null) {
//       base64Strig = await convertFileToBase64(file);
//     }
//     return base64Strig;
//   }

//   /// convert to base64
//   Future<String?> convertFileToBase64(File file) async {
//     try {
//       final List<int> fileBytes = await file.readAsBytes();

//       final String base64String = base64Encode(fileBytes);

//       return base64String;
//     } catch (e) {
//       debugPrint('Error converting file to Base64: $e');
//       return null;
//     }
//   }

//   /// pick image
//   Future<File?> pickImage({
//     required bool isGallery,
//     required Future<File?> Function(File file) cropImage,
//   }) async {
//     final source = isGallery ? ImageSource.gallery : ImageSource.camera;
//     final pickedFile = await ImagePicker().pickImage(source: source);

//     if (pickedFile == null) return null;

//     final file = File(pickedFile.path);
//     return await cropImage(file);
//   }

//   /// crop squre image
//   Future<File?> cropSquareImage(File imageFile) async {
//     final croppedFile = await ImageCropper().cropImage(
//       sourcePath: imageFile.path,
//       aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
//       // aspectRatioPresets: [CropAspectRatioPreset.square],
//       compressQuality: 70,
//       compressFormat: ImageCompressFormat.jpg,
//     );

//     return croppedFile != null ? File(croppedFile.path) : null;
//   }
// }

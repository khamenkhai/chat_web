import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// A class that represents data obtained from the web resource (link preview).
@immutable
abstract class PreviewData extends Equatable {
  /// Creates preview data.
  const PreviewData._({
    this.description,
    this.image,
    this.link,
    this.title,
  });

  const factory PreviewData({
    String? description,
    PreviewDataImage? image,
    String? link,
    String? title,
  }) = _PreviewData;

  /// Link description (usually og:description meta tag).
  final String? description;

  /// See [PreviewDataImage].
  final PreviewDataImage? image;

  /// Remote resource URL.
  final String? link;

  /// Link title (usually og:title meta tag).
  final String? title;

  /// Equatable props.
  @override
  List<Object?> get props => [description, image, link, title];

  PreviewData copyWith({
    String? description,
    PreviewDataImage? image,
    String? link,
    String? title,
  });

  /// Manually converts the preview data to a map representation (encodable to JSON).
  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'image': image?.toMap(),
      'link': link,
      'title': title,
    };
  }

  /// Manually creates preview data from a map representation.
  factory PreviewData.fromMap(Map<String, dynamic> map) {
    return _PreviewData(
      description: map['description'] as String?,
      image: map['image'] != null
          ? PreviewDataImage.fromMap(map['image'] as Map<String, dynamic>)
          : null,
      link: map['link'] as String?,
      title: map['title'] as String?,
    );
  }
}

/// A utility class to enable better copyWith.
class _PreviewData extends PreviewData {
  const _PreviewData({
    super.description,
    super.image,
    super.link,
    super.title,
  }) : super._();

  @override
  PreviewData copyWith({
    dynamic description = _Unset,
    dynamic image = _Unset,
    dynamic link = _Unset,
    dynamic title = _Unset,
  }) =>
      _PreviewData(
        description:
            description == _Unset ? this.description : description as String?,
        image: image == _Unset ? this.image : image as PreviewDataImage?,
        link: link == _Unset ? this.link : link as String?,
        title: title == _Unset ? this.title : title as String?,
      );
}

class _Unset {}

/// A utility class that forces image's width and height to be stored
/// alongside the url.
@immutable
class PreviewDataImage extends Equatable {
  /// Creates preview data image.
  const PreviewDataImage({
    required this.height,
    required this.url,
    required this.width,
  });

  /// Image height in pixels.
  final double height;

  /// Remote image URL.
  final String url;

  /// Image width in pixels.
  final double width;

  /// Equatable props.
  @override
  List<Object> get props => [height, url, width];

  /// Manually converts the preview data image to a map representation (encodable to JSON).
  Map<String, dynamic> toMap() {
    return {
      'height': height,
      'url': url,
      'width': width,
    };
  }

  /// Manually creates preview data image from a map representation.
  factory PreviewDataImage.fromMap(Map<String, dynamic> map) {
    return PreviewDataImage(
      height: map['height'] as double,
      url: map['url'] as String,
      width: map['width'] as double,
    );
  }
}

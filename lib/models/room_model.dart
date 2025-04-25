import 'package:chat_web/models/user_model.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// All possible room types.
enum RoomType { channel, direct, group }

/// A class that represents a room where 2 or more participants can chat.
@immutable
abstract class Room extends Equatable {
  /// Creates a [Room].
  const Room._({
    this.createdAt,
    required this.id,
    this.imageUrl,
    this.lastMessage,
    this.metadata,
    this.name,
    required this.type,
    this.updatedAt,
    required this.users,
  });

  const factory Room({
    int? createdAt,
    required String id,
    String? imageUrl,
    String? lastMessage,
    Map<String, dynamic>? metadata,
    String? name,
    required RoomType? type,
    int? updatedAt,
    required List<User> users,
  }) = _Room;

  /// Created room timestamp, in ms.
  final int? createdAt;

  /// Room's unique ID.
  final String id;

  /// Room's image. In case of the [RoomType.direct] - avatar of the second person,
  /// otherwise a custom image [RoomType.group].
  final String? imageUrl;

  /// List of last messages this room has received.
  final String? lastMessage;

  /// Additional custom metadata or attributes related to the room.
  final Map<String, dynamic>? metadata;

  /// Room's name. In case of the [RoomType.direct] - name of the second person,
  /// otherwise a custom name [RoomType.group].
  final String? name;

  /// [RoomType].
  final RoomType? type;

  /// Updated room timestamp, in ms.
  final int? updatedAt;

  /// List of users which are in the room.
  final List<User> users;

  /// Equatable props.
  @override
  List<Object?> get props => [
        createdAt,
        id,
        imageUrl,
        lastMessage,
        metadata,
        name,
        type,
        updatedAt,
        users,
      ];

  /// Creates a copy of the room with updated data.
  Room copyWith({
    int? createdAt,
    String? id,
    String? imageUrl,
    String? lastMessage,
    Map<String, dynamic>? metadata,
    String? name,
    RoomType? type,
    int? updatedAt,
    List<User>? users,
  });

  /// Manually converts the room to a map representation (without JSON serializable).
  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt,
      'id': id,
      'imageUrl': imageUrl,
      'lastMessage': lastMessage,
      'metadata': metadata,
      'name': name,
      'type': type?.toString().split('.').last, // Convert enum to string
      'updatedAt': updatedAt,
      'users': users.map((user) => user.toMap()).toList(),
    };
  }

  /// Manually creates a room from a map representation (without JSON serializable).
  factory Room.fromMap(Map<String, dynamic> map) {
    return _Room(
      createdAt: map['createdAt'] as int?,
      id: map['id'] as String,
      imageUrl: map['imageUrl'] as String?,
      lastMessage: map['lastMessage'] ?? "",
      metadata: map['metadata'] as Map<String, dynamic>?,
      name: map['name'] as String?,
      type: RoomType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => RoomType.channel, // Default to channel if unknown type
      ),
      updatedAt: map['updatedAt'] as int?,
      users: (map['users'] as List)
          .map((userMap) => User.fromMap(userMap as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A utility class to enable better copyWith.
class _Room extends Room {
  const _Room({
    super.createdAt,
    required super.id,
    super.imageUrl,
    super.lastMessage,
    super.metadata,
    super.name,
    required super.type,
    super.updatedAt,
    required super.users,
  }) : super._();

  @override
  Room copyWith({
    dynamic createdAt = _Unset,
    String? id,
    dynamic imageUrl = _Unset,
    dynamic lastMessage = _Unset,
    dynamic metadata = _Unset,
    dynamic name = _Unset,
    dynamic type = _Unset,
    dynamic updatedAt = _Unset,
    List<User>? users,
  }) =>
      _Room(
        createdAt: createdAt == _Unset ? this.createdAt : createdAt as int?,
        id: id ?? this.id,
        imageUrl: imageUrl == _Unset ? this.imageUrl : imageUrl as String?,
        lastMessage: lastMessage == _Unset
            ? this.lastMessage
            : lastMessage as String?,
        metadata: metadata == _Unset
            ? this.metadata
            : metadata as Map<String, dynamic>?,
        name: name == _Unset ? this.name : name as String?,
        type: type == _Unset ? this.type : type as RoomType?,
        updatedAt: updatedAt == _Unset ? this.updatedAt : updatedAt as int?,
        users: users ?? this.users,
      );
}

class _Unset {}

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// All possible roles user can have.
enum Role { admin, agent, moderator, user }

/// A class that represents a user.
@immutable
abstract class User extends Equatable {
  /// Creates a user.
  const User._({
    this.createdAt,
    this.firstName,
    required this.id,
    this.imageUrl,
    this.lastName,
    this.lastSeen,
    this.metadata,
    this.role,
    this.updatedAt,
  });

  const factory User({
    int? createdAt,
    String? firstName,
    required String id,
    String? imageUrl,
    String? lastName,
    int? lastSeen,
    Map<String, dynamic>? metadata,
    Role? role,
    int? updatedAt,
  }) = _User;

  /// Created user timestamp, in ms.
  final int? createdAt;

  /// First name of the user.
  final String? firstName;

  /// Unique ID of the user.
  final String id;

  /// Remote image URL representing user's avatar.
  final String? imageUrl;

  /// Last name of the user.
  final String? lastName;

  /// Timestamp when user was last visible, in ms.
  final int? lastSeen;

  /// Additional custom metadata or attributes related to the user.
  final Map<String, dynamic>? metadata;

  /// User [Role].
  final Role? role;

  /// Updated user timestamp, in ms.
  final int? updatedAt;

  /// Equatable props.
  @override
  List<Object?> get props => [
        createdAt,
        firstName,
        id,
        imageUrl,
        lastName,
        lastSeen,
        metadata,
        role,
        updatedAt,
      ];

  User copyWith({
    int? createdAt,
    String? firstName,
    String? id,
    String? imageUrl,
    String? lastName,
    int? lastSeen,
    Map<String, dynamic>? metadata,
    Role? role,
    int? updatedAt,
  });

  /// Manually converts the user to a map representation (encodable to JSON).
  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt,
      'firstName': firstName,
      'id': id,
      'imageUrl': imageUrl,
      'lastName': lastName,
      'lastSeen': lastSeen,
      'metadata': metadata,
      'role': role?.toString().split('.').last, // Convert enum to string
      'updatedAt': updatedAt,
    };
  }

  /// Manually creates a user from a map representation (without JSON serializable).
  factory User.fromMap(Map<String, dynamic> map) {
    return _User(
      createdAt: map['createdAt'] as int?,
      firstName: map['firstName'] as String?,
      id: map['id'] as String,
      imageUrl: map['imageUrl'] as String?,
      lastName: map['lastName'] as String?,
      lastSeen: map['lastSeen'] as int?,
      metadata: map['metadata'] as Map<String, dynamic>?,
      role: Role.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
        orElse: () => Role.user, // Default to user if unknown role
      ),
      updatedAt: map['updatedAt'] as int?,
    );
  }
}

/// A utility class to enable better copyWith.
class _User extends User {
  const _User({
    super.createdAt,
    super.firstName,
    required super.id,
    super.imageUrl,
    super.lastName,
    super.lastSeen,
    super.metadata,
    super.role,
    super.updatedAt,
  }) : super._();

  @override
  User copyWith({
    dynamic createdAt = _Unset,
    dynamic firstName = _Unset,
    String? id,
    dynamic imageUrl = _Unset,
    dynamic lastName = _Unset,
    dynamic lastSeen = _Unset,
    dynamic metadata = _Unset,
    dynamic role = _Unset,
    dynamic updatedAt = _Unset,
  }) =>
      _User(
        createdAt: createdAt == _Unset ? this.createdAt : createdAt as int?,
        firstName: firstName == _Unset ? this.firstName : firstName as String?,
        id: id ?? this.id,
        imageUrl: imageUrl == _Unset ? this.imageUrl : imageUrl as String?,
        lastName: lastName == _Unset ? this.lastName : lastName as String?,
        lastSeen: lastSeen == _Unset ? this.lastSeen : lastSeen as int?,
        metadata: metadata == _Unset
            ? this.metadata
            : metadata as Map<String, dynamic>?,
        role: role == _Unset ? this.role : role as Role?,
        updatedAt: updatedAt == _Unset ? this.updatedAt : updatedAt as int?,
      );
}

class _Unset {}

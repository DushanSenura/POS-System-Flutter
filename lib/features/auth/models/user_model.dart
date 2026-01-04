import 'package:hive/hive.dart';

part 'user_model.g.dart';

/// User model for authentication
@HiveType(typeId: 3)
class User {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String role;

  @HiveField(4)
  final String? avatarUrl;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime lastLogin;

  @HiveField(7)
  final String? passwordHash;

  @HiveField(8)
  final String? employeeId;

  @HiveField(9)
  final String? qrCode;

  @HiveField(10)
  final bool qrCodeDownloaded;

  @HiveField(11)
  final bool mustChangePassword;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
    required this.lastLogin,
    this.passwordHash,
    this.employeeId,
    this.qrCode,
    this.qrCodeDownloaded = false,
    this.mustChangePassword = false,
  });

  /// Create a copy with modified fields
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? passwordHash,
    String? employeeId,
    String? qrCode,
    bool? qrCodeDownloaded,
    bool? mustChangePassword,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      passwordHash: passwordHash ?? this.passwordHash,
      employeeId: employeeId ?? this.employeeId,
      qrCode: qrCode ?? this.qrCode,
      qrCodeDownloaded: qrCodeDownloaded ?? this.qrCodeDownloaded,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'passwordHash': passwordHash,
      'employeeId': employeeId,
      'qrCode': qrCode,
      'qrCodeDownloaded': qrCodeDownloaded,
      'mustChangePassword': mustChangePassword,
    };
  }

  /// Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLogin: DateTime.parse(json['lastLogin'] as String),
      passwordHash: json['passwordHash'] as String?,
      employeeId: json['employeeId'] as String?,
      qrCode: json['qrCode'] as String?,
      qrCodeDownloaded: json['qrCodeDownloaded'] as bool? ?? false,
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
    );
  }
}

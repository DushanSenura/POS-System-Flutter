import 'package:hive_flutter/hive_flutter.dart';

part 'employee_model.g.dart';

@HiveType(typeId: 5)
class Employee {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String phone;

  @HiveField(4)
  final String role;

  @HiveField(5)
  final double salary;

  @HiveField(6)
  final String salaryMethod; // Daily, Weekly, Monthly

  @HiveField(7)
  final DateTime joinDate;

  @HiveField(8)
  final String? address;

  @HiveField(9)
  final bool isActive;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime updatedAt;

  @HiveField(12)
  final double workHoursPerDay; // Work hours per day (e.g., 8.0)

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.salary,
    required this.salaryMethod,
    required this.joinDate,
    this.address,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.workHoursPerDay = 8.0, // Default to 8 hours per day
  });

  Employee copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    double? salary,
    String? salaryMethod,
    DateTime? joinDate,
    String? address,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? workHoursPerDay,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      salary: salary ?? this.salary,
      salaryMethod: salaryMethod ?? this.salaryMethod,
      joinDate: joinDate ?? this.joinDate,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workHoursPerDay: workHoursPerDay ?? this.workHoursPerDay,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'salary': salary,
      'salaryMethod': salaryMethod,
      'joinDate': joinDate.toIso8601String(),
      'address': address,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'workHoursPerDay': workHoursPerDay,
    };
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      salary: (json['salary'] as num).toDouble(),
      salaryMethod: json['salaryMethod'] as String? ?? 'Monthly',
      joinDate: DateTime.parse(json['joinDate'] as String),
      address: json['address'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      workHoursPerDay: (json['workHoursPerDay'] as num?)?.toDouble() ?? 8.0,
    );
  }
}

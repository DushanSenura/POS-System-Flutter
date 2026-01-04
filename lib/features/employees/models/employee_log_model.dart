import 'package:hive_flutter/hive_flutter.dart';

part 'employee_log_model.g.dart';

@HiveType(typeId: 6)
class EmployeeLog {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String employeeId;

  @HiveField(2)
  final String employeeName;

  @HiveField(3)
  final DateTime activeTime;

  @HiveField(4)
  final DateTime? deactiveTime;

  @HiveField(5)
  final double? hoursWorked; // Calculated hours

  @HiveField(6)
  final DateTime createdAt;

  EmployeeLog({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.activeTime,
    this.deactiveTime,
    this.hoursWorked,
    required this.createdAt,
  });

  /// Calculate hours worked between active and deactive time
  double calculateHours() {
    if (deactiveTime == null) return 0;
    final duration = deactiveTime!.difference(activeTime);
    return duration.inMinutes / 60.0;
  }

  EmployeeLog copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    DateTime? activeTime,
    DateTime? deactiveTime,
    double? hoursWorked,
    DateTime? createdAt,
  }) {
    return EmployeeLog(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      activeTime: activeTime ?? this.activeTime,
      deactiveTime: deactiveTime ?? this.deactiveTime,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'activeTime': activeTime.toIso8601String(),
      'deactiveTime': deactiveTime?.toIso8601String(),
      'hoursWorked': hoursWorked,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EmployeeLog.fromJson(Map<String, dynamic> json) {
    return EmployeeLog(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String,
      activeTime: DateTime.parse(json['activeTime'] as String),
      deactiveTime: json['deactiveTime'] != null
          ? DateTime.parse(json['deactiveTime'] as String)
          : null,
      hoursWorked: json['hoursWorked'] as double?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

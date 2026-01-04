// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmployeeAdapter extends TypeAdapter<Employee> {
  @override
  final int typeId = 5;

  @override
  Employee read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Handle backward compatibility for old employees without salaryMethod
    if (numOfFields < 12) {
      // Old format: fields 0-10 without salaryMethod at field 6
      return Employee(
        id: fields[0] as String,
        name: fields[1] as String,
        email: fields[2] as String,
        phone: fields[3] as String,
        role: fields[4] as String,
        salary: fields[5] as double,
        salaryMethod: 'Monthly', // Default for old employees
        joinDate: fields[6] as DateTime,
        address: fields[7] as String?,
        isActive: fields[8] as bool,
        createdAt: fields[9] as DateTime,
        updatedAt: fields[10] as DateTime,
        workHoursPerDay: 8.0, // Default for old employees
      );
    }

    // Handle format without workHoursPerDay
    if (numOfFields < 13) {
      return Employee(
        id: fields[0] as String,
        name: fields[1] as String,
        email: fields[2] as String,
        phone: fields[3] as String,
        role: fields[4] as String,
        salary: fields[5] as double,
        salaryMethod: fields[6] as String? ?? 'Monthly',
        joinDate: fields[7] as DateTime,
        address: fields[8] as String?,
        isActive: fields[9] as bool,
        createdAt: fields[10] as DateTime,
        updatedAt: fields[11] as DateTime,
        workHoursPerDay: 8.0, // Default for old employees
      );
    }

    // New format with workHoursPerDay
    return Employee(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      phone: fields[3] as String,
      role: fields[4] as String,
      salary: fields[5] as double,
      salaryMethod: fields[6] as String? ?? 'Monthly',
      joinDate: fields[7] as DateTime,
      address: fields[8] as String?,
      isActive: fields[9] as bool,
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime,
      workHoursPerDay: fields[12] as double? ?? 8.0,
    );
  }

  @override
  void write(BinaryWriter writer, Employee obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.role)
      ..writeByte(5)
      ..write(obj.salary)
      ..writeByte(6)
      ..write(obj.salaryMethod)
      ..writeByte(7)
      ..write(obj.joinDate)
      ..writeByte(8)
      ..write(obj.address)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.workHoursPerDay);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

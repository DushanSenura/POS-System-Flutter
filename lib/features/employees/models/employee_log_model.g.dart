// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmployeeLogAdapter extends TypeAdapter<EmployeeLog> {
  @override
  final int typeId = 6;

  @override
  EmployeeLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmployeeLog(
      id: fields[0] as String,
      employeeId: fields[1] as String,
      employeeName: fields[2] as String,
      activeTime: fields[3] as DateTime,
      deactiveTime: fields[4] as DateTime?,
      hoursWorked: fields[5] as double?,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, EmployeeLog obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.employeeId)
      ..writeByte(2)
      ..write(obj.employeeName)
      ..writeByte(3)
      ..write(obj.activeTime)
      ..writeByte(4)
      ..write(obj.deactiveTime)
      ..writeByte(5)
      ..write(obj.hoursWorked)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

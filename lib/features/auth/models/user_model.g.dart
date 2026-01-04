// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 3;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as String,
      email: fields[1] as String,
      name: fields[2] as String,
      role: fields[3] as String,
      avatarUrl: fields[4] as String?,
      createdAt: fields[5] as DateTime,
      lastLogin: fields[6] as DateTime,
      passwordHash: fields[7] as String?,
      employeeId: fields[8] as String?,
      qrCode: fields[9] as String?,
      qrCodeDownloaded: fields[10] as bool? ?? false,
      mustChangePassword: fields[11] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.avatarUrl)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastLogin)
      ..writeByte(7)
      ..write(obj.passwordHash)
      ..writeByte(8)
      ..write(obj.employeeId)
      ..writeByte(9)
      ..write(obj.qrCode)
      ..writeByte(10)
      ..write(obj.qrCodeDownloaded)
      ..writeByte(11)
      ..write(obj.mustChangePassword);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StoreSettingsAdapter extends TypeAdapter<StoreSettings> {
  @override
  final int typeId = 4;

  @override
  StoreSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoreSettings(
      storeName: fields[0] as String? ?? 'My Store',
      storeAddress: fields[1] as String? ?? '123 Main St',
      storePhone: fields[2] as String? ?? '+1 (555) 123-4567',
      storeEmail: fields[3] as String?,
      logoUrl: fields[4] as String?,
      taxRate: (fields[5] as num?)?.toDouble() ?? 0.0,
      currency: fields[6] as String? ?? 'LKR',
      autoPrintReceipt: (fields[7] as bool?) ?? false,
      printerType: fields[8] as String? ?? 'None',
      printerAddress: fields[9] as String?,
      isDarkMode: (fields[10] as bool?) ?? false,
      enableBarcodeScanner: (fields[11] as bool?) ?? true,
      autofillProductDetails: (fields[12] as bool?) ?? true,
      enableBeepSound: (fields[13] as bool?) ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, StoreSettings obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.storeName)
      ..writeByte(1)
      ..write(obj.storeAddress)
      ..writeByte(2)
      ..write(obj.storePhone)
      ..writeByte(3)
      ..write(obj.storeEmail)
      ..writeByte(4)
      ..write(obj.logoUrl)
      ..writeByte(5)
      ..write(obj.taxRate)
      ..writeByte(6)
      ..write(obj.currency)
      ..writeByte(7)
      ..write(obj.autoPrintReceipt)
      ..writeByte(8)
      ..write(obj.printerType)
      ..writeByte(9)
      ..write(obj.printerAddress)
      ..writeByte(10)
      ..write(obj.isDarkMode)
      ..writeByte(11)
      ..write(obj.enableBarcodeScanner)
      ..writeByte(12)
      ..write(obj.autofillProductDetails)
      ..writeByte(13)
      ..write(obj.enableBeepSound);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

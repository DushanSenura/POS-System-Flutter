import 'package:hive/hive.dart';

part 'store_settings_model.g.dart';

/// Store settings model
@HiveType(typeId: 4)
class StoreSettings {
  @HiveField(0)
  final String storeName;

  @HiveField(1)
  final String storeAddress;

  @HiveField(2)
  final String storePhone;

  @HiveField(3)
  final String? storeEmail;

  @HiveField(4)
  final String? logoUrl;

  @HiveField(5)
  final double taxRate;

  @HiveField(6)
  final String currency;

  @HiveField(7)
  final bool autoPrintReceipt;

  @HiveField(8)
  final String printerType;

  @HiveField(9)
  final String? printerAddress;

  @HiveField(10)
  final bool isDarkMode;

  @HiveField(11)
  final bool enableBarcodeScanner;

  @HiveField(12)
  final bool autofillProductDetails;

  @HiveField(13)
  final bool enableBeepSound;

  StoreSettings({
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
    this.storeEmail,
    this.logoUrl,
    required this.taxRate,
    required this.currency,
    this.autoPrintReceipt = false,
    this.printerType = 'None',
    this.printerAddress,
    this.isDarkMode = false,
    this.enableBarcodeScanner = true,
    this.autofillProductDetails = true,
    this.enableBeepSound = true,
  });

  /// Create a copy with modified fields
  StoreSettings copyWith({
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? storeEmail,
    String? logoUrl,
    double? taxRate,
    String? currency,
    bool? autoPrintReceipt,
    String? printerType,
    String? printerAddress,
    bool? isDarkMode,
    bool? enableBarcodeScanner,
    bool? autofillProductDetails,
    bool? enableBeepSound,
  }) {
    return StoreSettings(
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      storePhone: storePhone ?? this.storePhone,
      storeEmail: storeEmail ?? this.storeEmail,
      logoUrl: logoUrl ?? this.logoUrl,
      taxRate: taxRate ?? this.taxRate,
      currency: currency ?? this.currency,
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
      printerType: printerType ?? this.printerType,
      printerAddress: printerAddress ?? this.printerAddress,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      enableBarcodeScanner: enableBarcodeScanner ?? this.enableBarcodeScanner,
      autofillProductDetails:
          autofillProductDetails ?? this.autofillProductDetails,
      enableBeepSound: enableBeepSound ?? this.enableBeepSound,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'storeName': storeName,
      'storeAddress': storeAddress,
      'storePhone': storePhone,
      'storeEmail': storeEmail,
      'logoUrl': logoUrl,
      'taxRate': taxRate,
      'currency': currency,
      'autoPrintReceipt': autoPrintReceipt,
      'printerType': printerType,
      'printerAddress': printerAddress,
      'isDarkMode': isDarkMode,
      'enableBarcodeScanner': enableBarcodeScanner,
      'autofillProductDetails': autofillProductDetails,
      'enableBeepSound': enableBeepSound,
    };
  }

  /// Create from JSON
  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    return StoreSettings(
      storeName: json['storeName'] as String,
      storeAddress: json['storeAddress'] as String,
      storePhone: json['storePhone'] as String,
      storeEmail: json['storeEmail'] as String?,
      logoUrl: json['logoUrl'] as String?,
      taxRate: (json['taxRate'] as num).toDouble(),
      currency: json['currency'] as String,
      autoPrintReceipt: json['autoPrintReceipt'] as bool? ?? false,
      printerType: json['printerType'] as String? ?? 'None',
      printerAddress: json['printerAddress'] as String?,
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      enableBarcodeScanner: json['enableBarcodeScanner'] as bool? ?? true,
      autofillProductDetails: json['autofillProductDetails'] as bool? ?? true,
      enableBeepSound: json['enableBeepSound'] as bool? ?? true,
    );
  }

  /// Default settings
  factory StoreSettings.defaultSettings() {
    return StoreSettings(
      storeName: 'My Store',
      storeAddress: '123 Main St, City, State 12345',
      storePhone: '+1 (555) 123-4567',
      taxRate: 0.0,
      currency: 'LKR',
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/store_settings_model.dart';
import 'package:flutter/material.dart';

/// Settings state notifier
class SettingsNotifier extends StateNotifier<StoreSettings> {
  SettingsNotifier() : super(StoreSettings.defaultSettings());

  /// Update store name
  void updateStoreName(String name) {
    state = state.copyWith(storeName: name);
  }

  /// Update store address
  void updateStoreAddress(String address) {
    state = state.copyWith(storeAddress: address);
  }

  /// Update store phone
  void updateStorePhone(String phone) {
    state = state.copyWith(storePhone: phone);
  }

  /// Update store email
  void updateStoreEmail(String email) {
    state = state.copyWith(storeEmail: email);
  }

  /// Update tax rate
  void updateTaxRate(double rate) {
    state = state.copyWith(taxRate: rate);
  }

  /// Update currency
  void updateCurrency(String currency) {
    state = state.copyWith(currency: currency);
  }

  /// Toggle auto print receipt
  void toggleAutoPrintReceipt() {
    state = state.copyWith(autoPrintReceipt: !state.autoPrintReceipt);
  }

  /// Update printer type
  void updatePrinterType(String type) {
    state = state.copyWith(printerType: type);
  }

  /// Update printer address
  void updatePrinterAddress(String address) {
    state = state.copyWith(printerAddress: address);
  }

  /// Toggle dark mode
  void toggleDarkMode() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
  }

  /// Toggle barcode scanner
  void toggleBarcodeScanner() {
    state = state.copyWith(enableBarcodeScanner: !state.enableBarcodeScanner);
  }

  /// Toggle autofill product details
  void toggleAutofillProductDetails() {
    state = state.copyWith(
      autofillProductDetails: !state.autofillProductDetails,
    );
  }

  /// Toggle beep sound
  void toggleBeepSound() {
    state = state.copyWith(enableBeepSound: !state.enableBeepSound);
  }

  /// Load settings from storage
  Future<void> loadSettings() async {
    // In production, load from Hive
    // For now, use default settings
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Save settings to storage
  Future<void> saveSettings() async {
    // In production, save to Hive
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

/// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, StoreSettings>(
  (ref) {
    return SettingsNotifier();
  },
);

/// Theme mode provider
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
});

/// Tax rate provider
final taxRateProvider = Provider<double>((ref) {
  return ref.watch(settingsProvider).taxRate;
});

/// Currency provider
final currencyProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).currency;
});

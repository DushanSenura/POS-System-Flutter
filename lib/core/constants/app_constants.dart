/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'POS Management System';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String userBoxName = 'user_box';
  static const String cartBoxName = 'cart_box';
  static const String productsBoxName = 'products_box';
  static const String salesBoxName = 'sales_box';
  static const String settingsBoxName = 'settings_box';

  // Settings Keys
  static const String rememberMeKey = 'remember_me';
  static const String themeKey = 'theme_mode';
  static const String taxRateKey = 'tax_rate';
  static const String storeNameKey = 'store_name';
  static const String storeAddressKey = 'store_address';
  static const String storePhoneKey = 'store_phone';

  // Default Values
  static const double defaultTaxRate = 0.0; // 0%
  static const String defaultCurrency = 'LKR';
  static const int itemsPerPage = 20;

  // Payment Methods
  static const String paymentCash = 'Cash';
  static const String paymentCard = 'Card';
  static const String paymentQR = 'QR Code';
  static const String paymentWallet = 'Digital Wallet';

  // Salary Methods
  static const String salaryDaily = 'Daily';
  static const String salaryWeekly = 'Weekly';
  static const String salaryMonthly = 'Monthly';

  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'HH:mm:ss';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm:ss';
}

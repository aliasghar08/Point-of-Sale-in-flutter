class AppSettings {
  final String themeMode; // 'light', 'dark', 'system'
  final String currencySymbol;
  final String currencyCode;
  final bool enableNotifications;
  final bool enableSound;
  final bool enableVibration;
  final bool autoPrintReceipt;
  final bool showProfitInPOS;
  final int lowStockThreshold;
  final String dateFormat;
  final String timeFormat;
  final bool enableOfflineMode;
  final bool autoSyncData;

  AppSettings({
    this.themeMode = 'system',
    this.currencySymbol = '₹',
    this.currencyCode = 'INR',
    this.enableNotifications = true,
    this.enableSound = true,
    this.enableVibration = true,
    this.autoPrintReceipt = false,
    this.showProfitInPOS = true,
    this.lowStockThreshold = 10,
    this.dateFormat = 'dd/MM/yyyy',
    this.timeFormat = 'HH:mm',
    this.enableOfflineMode = false,
    this.autoSyncData = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode,
      'currencySymbol': currencySymbol,
      'currencyCode': currencyCode,
      'enableNotifications': enableNotifications,
      'enableSound': enableSound,
      'enableVibration': enableVibration,
      'autoPrintReceipt': autoPrintReceipt,
      'showProfitInPOS': showProfitInPOS,
      'lowStockThreshold': lowStockThreshold,
      'dateFormat': dateFormat,
      'timeFormat': timeFormat,
      'enableOfflineMode': enableOfflineMode,
      'autoSyncData': autoSyncData,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      themeMode: map['themeMode'] ?? 'system',
      currencySymbol: map['currencySymbol'] ?? '₹',
      currencyCode: map['currencyCode'] ?? 'INR',
      enableNotifications: map['enableNotifications'] ?? true,
      enableSound: map['enableSound'] ?? true,
      enableVibration: map['enableVibration'] ?? true,
      autoPrintReceipt: map['autoPrintReceipt'] ?? false,
      showProfitInPOS: map['showProfitInPOS'] ?? true,
      lowStockThreshold: map['lowStockThreshold'] ?? 10,
      dateFormat: map['dateFormat'] ?? 'dd/MM/yyyy',
      timeFormat: map['timeFormat'] ?? 'HH:mm',
      enableOfflineMode: map['enableOfflineMode'] ?? false,
      autoSyncData: map['autoSyncData'] ?? true,
    );
  }

  AppSettings copyWith({
    String? themeMode,
    String? currencySymbol,
    String? currencyCode,
    bool? enableNotifications,
    bool? enableSound,
    bool? enableVibration,
    bool? autoPrintReceipt,
    bool? showProfitInPOS,
    int? lowStockThreshold,
    String? dateFormat,
    String? timeFormat,
    bool? enableOfflineMode,
    bool? autoSyncData,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
      showProfitInPOS: showProfitInPOS ?? this.showProfitInPOS,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      enableOfflineMode: enableOfflineMode ?? this.enableOfflineMode,
      autoSyncData: autoSyncData ?? this.autoSyncData,
    );
  }
}
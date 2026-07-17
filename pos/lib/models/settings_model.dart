import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AppSettings {
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
  final bool autoDetectCurrency;

  AppSettings({
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
    this.autoDetectCurrency = true,
  });

  Map<String, dynamic> toMap() {
    return {
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
      'autoDetectCurrency': autoDetectCurrency,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
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
      autoDetectCurrency: map['autoDetectCurrency'] ?? true,
    );
  }

  AppSettings copyWith({
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
    bool? autoDetectCurrency,
  }) {
    return AppSettings(
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
      autoDetectCurrency: autoDetectCurrency ?? this.autoDetectCurrency,
    );
  }

  // ========== CURRENCY MAPPING ==========
  static final Map<String, Map<String, String>> _currencyMap = {
    'AF': {'symbol': '؋', 'code': 'AFN'},
    'AL': {'symbol': 'L', 'code': 'ALL'},
    'DZ': {'symbol': 'دج', 'code': 'DZD'},
    'AD': {'symbol': '€', 'code': 'EUR'},
    'AO': {'symbol': 'Kz', 'code': 'AOA'},
    'AR': {'symbol': '\$', 'code': 'ARS'},
    'AM': {'symbol': '֏', 'code': 'AMD'},
    'AU': {'symbol': '\$', 'code': 'AUD'},
    'AT': {'symbol': '€', 'code': 'EUR'},
    'AZ': {'symbol': '₼', 'code': 'AZN'},
    'BS': {'symbol': '\$', 'code': 'BSD'},
    'BH': {'symbol': '.د.ب', 'code': 'BHD'},
    'BD': {'symbol': '৳', 'code': 'BDT'},
    'BY': {'symbol': 'Br', 'code': 'BYN'},
    'BE': {'symbol': '€', 'code': 'EUR'},
    'BZ': {'symbol': '\$', 'code': 'BZD'},
    'BJ': {'symbol': 'CFA', 'code': 'XOF'},
    'BT': {'symbol': 'Nu.', 'code': 'BTN'},
    'BO': {'symbol': 'Bs.', 'code': 'BOB'},
    'BA': {'symbol': 'KM', 'code': 'BAM'},
    'BW': {'symbol': 'P', 'code': 'BWP'},
    'BR': {'symbol': 'R\$', 'code': 'BRL'},
    'BN': {'symbol': '\$', 'code': 'BND'},
    'BG': {'symbol': 'лв', 'code': 'BGN'},
    'BF': {'symbol': 'CFA', 'code': 'XOF'},
    'BI': {'symbol': 'FBu', 'code': 'BIF'},
    'KH': {'symbol': '៛', 'code': 'KHR'},
    'CM': {'symbol': 'CFA', 'code': 'XAF'},
    'CA': {'symbol': '\$', 'code': 'CAD'},
    'CV': {'symbol': '\$', 'code': 'CVE'},
    'CF': {'symbol': 'CFA', 'code': 'XAF'},
    'TD': {'symbol': 'CFA', 'code': 'XAF'},
    'CL': {'symbol': '\$', 'code': 'CLP'},
    'CN': {'symbol': '¥', 'code': 'CNY'},
    'CO': {'symbol': '\$', 'code': 'COP'},
    'KM': {'symbol': 'CF', 'code': 'KMF'},
    'CG': {'symbol': 'CFA', 'code': 'XAF'},
    'CR': {'symbol': '₡', 'code': 'CRC'},
    'HR': {'symbol': '€', 'code': 'EUR'},
    'CU': {'symbol': '\$', 'code': 'CUP'},
    'CY': {'symbol': '€', 'code': 'EUR'},
    'CZ': {'symbol': 'Kč', 'code': 'CZK'},
    'DK': {'symbol': 'kr', 'code': 'DKK'},
    'DJ': {'symbol': 'Fdj', 'code': 'DJF'},
    'DO': {'symbol': '\$', 'code': 'DOP'},
    'EC': {'symbol': '\$', 'code': 'USD'},
    'EG': {'symbol': '£', 'code': 'EGP'},
    'SV': {'symbol': '\$', 'code': 'USD'},
    'GQ': {'symbol': 'CFA', 'code': 'XAF'},
    'ER': {'symbol': 'Nfk', 'code': 'ERN'},
    'EE': {'symbol': '€', 'code': 'EUR'},
    'ET': {'symbol': 'Br', 'code': 'ETB'},
    'FJ': {'symbol': '\$', 'code': 'FJD'},
    'FI': {'symbol': '€', 'code': 'EUR'},
    'FR': {'symbol': '€', 'code': 'EUR'},
    'GA': {'symbol': 'CFA', 'code': 'XAF'},
    'GM': {'symbol': 'D', 'code': 'GMD'},
    'GE': {'symbol': '₾', 'code': 'GEL'},
    'DE': {'symbol': '€', 'code': 'EUR'},
    'GH': {'symbol': '₵', 'code': 'GHS'},
    'GR': {'symbol': '€', 'code': 'EUR'},
    'GT': {'symbol': 'Q', 'code': 'GTQ'},
    'GN': {'symbol': 'FG', 'code': 'GNF'},
    'GY': {'symbol': '\$', 'code': 'GYD'},
    'HT': {'symbol': 'G', 'code': 'HTG'},
    'HN': {'symbol': 'L', 'code': 'HNL'},
    'HU': {'symbol': 'Ft', 'code': 'HUF'},
    'IS': {'symbol': 'kr', 'code': 'ISK'},
    'IN': {'symbol': '₹', 'code': 'INR'},
    'ID': {'symbol': 'Rp', 'code': 'IDR'},
    'IR': {'symbol': '﷼', 'code': 'IRR'},
    'IQ': {'symbol': 'د.ع', 'code': 'IQD'},
    'IE': {'symbol': '€', 'code': 'EUR'},
    'IL': {'symbol': '₪', 'code': 'ILS'},
    'IT': {'symbol': '€', 'code': 'EUR'},
    'CI': {'symbol': 'CFA', 'code': 'XOF'},
    'JP': {'symbol': '¥', 'code': 'JPY'},
    'JO': {'symbol': 'د.ا', 'code': 'JOD'},
    'KZ': {'symbol': '₸', 'code': 'KZT'},
    'KE': {'symbol': 'KSh', 'code': 'KES'},
    'KI': {'symbol': '\$', 'code': 'AUD'},
    'KW': {'symbol': 'د.ك', 'code': 'KWD'},
    'KG': {'symbol': 'с', 'code': 'KGS'},
    'LA': {'symbol': '₭', 'code': 'LAK'},
    'LV': {'symbol': '€', 'code': 'EUR'},
    'LB': {'symbol': 'ل.ل', 'code': 'LBP'},
    'LS': {'symbol': 'L', 'code': 'LSL'},
    'LR': {'symbol': '\$', 'code': 'LRD'},
    'LY': {'symbol': 'ل.د', 'code': 'LYD'},
    'LI': {'symbol': 'CHF', 'code': 'CHF'},
    'LT': {'symbol': '€', 'code': 'EUR'},
    'LU': {'symbol': '€', 'code': 'EUR'},
    'MG': {'symbol': 'Ar', 'code': 'MGA'},
    'MW': {'symbol': 'MK', 'code': 'MWK'},
    'MY': {'symbol': 'RM', 'code': 'MYR'},
    'MV': {'symbol': 'Rf', 'code': 'MVR'},
    'ML': {'symbol': 'CFA', 'code': 'XOF'},
    'MT': {'symbol': '€', 'code': 'EUR'},
    'MH': {'symbol': '\$', 'code': 'USD'},
    'MR': {'symbol': 'UM', 'code': 'MRU'},
    'MU': {'symbol': '₨', 'code': 'MUR'},
    'MX': {'symbol': '\$', 'code': 'MXN'},
    'FM': {'symbol': '\$', 'code': 'USD'},
    'MD': {'symbol': 'L', 'code': 'MDL'},
    'MC': {'symbol': '€', 'code': 'EUR'},
    'MN': {'symbol': '₮', 'code': 'MNT'},
    'ME': {'symbol': '€', 'code': 'EUR'},
    'MA': {'symbol': 'د.م.', 'code': 'MAD'},
    'MZ': {'symbol': 'MT', 'code': 'MZN'},
    'MM': {'symbol': 'K', 'code': 'MMK'},
    'NA': {'symbol': '\$', 'code': 'NAD'},
    'NR': {'symbol': '\$', 'code': 'AUD'},
    'NP': {'symbol': 'Rs', 'code': 'NPR'},
    'NL': {'symbol': '€', 'code': 'EUR'},
    'NZ': {'symbol': '\$', 'code': 'NZD'},
    'NI': {'symbol': 'C\$', 'code': 'NIO'},
    'NE': {'symbol': 'CFA', 'code': 'XOF'},
    'NG': {'symbol': '₦', 'code': 'NGN'},
    'NO': {'symbol': 'kr', 'code': 'NOK'},
    'OM': {'symbol': 'ر.ع.', 'code': 'OMR'},
    'PK': {'symbol': '₨', 'code': 'PKR'},  // ✅ Pakistan
    'PW': {'symbol': '\$', 'code': 'USD'},
    'PA': {'symbol': 'B/.', 'code': 'PAB'},
    'PG': {'symbol': 'K', 'code': 'PGK'},
    'PY': {'symbol': '₲', 'code': 'PYG'},
    'PE': {'symbol': 'S/', 'code': 'PEN'},
    'PH': {'symbol': '₱', 'code': 'PHP'},
    'PL': {'symbol': 'zł', 'code': 'PLN'},
    'PT': {'symbol': '€', 'code': 'EUR'},
    'QA': {'symbol': 'ر.ق', 'code': 'QAR'},
    'RO': {'symbol': 'lei', 'code': 'RON'},
    'RU': {'symbol': '₽', 'code': 'RUB'},
    'RW': {'symbol': 'FRw', 'code': 'RWF'},
    'WS': {'symbol': 'T', 'code': 'WST'},
    'SM': {'symbol': '€', 'code': 'EUR'},
    'SA': {'symbol': 'ر.س', 'code': 'SAR'},
    'SN': {'symbol': 'CFA', 'code': 'XOF'},
    'RS': {'symbol': 'дин', 'code': 'RSD'},
    'SC': {'symbol': '₨', 'code': 'SCR'},
    'SL': {'symbol': 'Le', 'code': 'SLL'},
    'SG': {'symbol': '\$', 'code': 'SGD'},
    'SK': {'symbol': '€', 'code': 'EUR'},
    'SI': {'symbol': '€', 'code': 'EUR'},
    'SB': {'symbol': '\$', 'code': 'SBD'},
    'SO': {'symbol': 'S', 'code': 'SOS'},
    'ZA': {'symbol': 'R', 'code': 'ZAR'},
    'KR': {'symbol': '₩', 'code': 'KRW'},
    'ES': {'symbol': '€', 'code': 'EUR'},
    'LK': {'symbol': 'Rs', 'code': 'LKR'},
    'SD': {'symbol': '£', 'code': 'SDG'},
    'SR': {'symbol': '\$', 'code': 'SRD'},
    'SE': {'symbol': 'kr', 'code': 'SEK'},
    'CH': {'symbol': 'CHF', 'code': 'CHF'},
    'SY': {'symbol': '£', 'code': 'SYP'},
    'TW': {'symbol': 'NT\$', 'code': 'TWD'},
    'TJ': {'symbol': 'ЅМ', 'code': 'TJS'},
    'TZ': {'symbol': 'TSh', 'code': 'TZS'},
    'TH': {'symbol': '฿', 'code': 'THB'},
    'TG': {'symbol': 'CFA', 'code': 'XOF'},
    'TO': {'symbol': 'T\$', 'code': 'TOP'},
    'TT': {'symbol': '\$', 'code': 'TTD'},
    'TN': {'symbol': 'د.ت', 'code': 'TND'},
    'TR': {'symbol': '₺', 'code': 'TRY'},
    'TM': {'symbol': 'm', 'code': 'TMT'},
    'TV': {'symbol': '\$', 'code': 'AUD'},
    'UG': {'symbol': 'USh', 'code': 'UGX'},
    'UA': {'symbol': '₴', 'code': 'UAH'},
    'AE': {'symbol': 'د.إ', 'code': 'AED'},
    'GB': {'symbol': '£', 'code': 'GBP'},
    'US': {'symbol': '\$', 'code': 'USD'},
    'UY': {'symbol': '\$', 'code': 'UYU'},
    'UZ': {'symbol': 'soʻm', 'code': 'UZS'},
    'VU': {'symbol': 'Vt', 'code': 'VUV'},
    'VE': {'symbol': 'Bs.', 'code': 'VES'},
    'VN': {'symbol': '₫', 'code': 'VND'},
    'YE': {'symbol': '﷼', 'code': 'YER'},
    'ZM': {'symbol': 'ZK', 'code': 'ZMW'},
    'ZW': {'symbol': '\$', 'code': 'ZWL'},
  };

  // ========== LOCATION-BASED CURRENCY DETECTION ==========

  /// Detect country from IP address
  static Future<String?> detectCountryFromIP() async {
    try {
      final response = await http
          .get(Uri.parse('https://ip-api.com/json/'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['countryCode']?.toString().toUpperCase();
        }
      }
      return null;
    } catch (e) {
      print('IP detection error: $e');
      return null;
    }
  }

  /// Detect country from device locale (fallback)
  static String? detectCountryFromLocale() {
    try {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      return locale.countryCode?.toUpperCase();
    } catch (e) {
      return null;
    }
  }

  /// Get currency for a country code
  static Map<String, String>? getCurrencyForCountry(String countryCode) {
    if (countryCode.isEmpty) return null;
    return _currencyMap[countryCode.toUpperCase()];
  }

  /// Get default currency based on location
  static Future<Map<String, String>> getDefaultCurrencyFromLocation() async {
    try {
      // Try to detect country from IP
      String? countryCode = await detectCountryFromIP();
      
      // If IP detection fails, try device locale
      if (countryCode == null || countryCode.isEmpty) {
        countryCode = detectCountryFromLocale();
      }

      // If country detected, get its currency
      if (countryCode != null && countryCode.isNotEmpty) {
        final currency = getCurrencyForCountry(countryCode);
        if (currency != null) {
          print('✅ Currency detected: ${currency['symbol']} (${currency['code']}) for $countryCode');
          return currency;
        }
      }

      // Default to India (INR) if detection fails
      print('⚠️ Using default currency: ₹ (INR)');
      return {'symbol': '₹', 'code': 'INR'};
    } catch (e) {
      print('❌ Currency detection error: $e');
      return {'symbol': '₹', 'code': 'INR'};
    }
  }

  /// Create AppSettings with location-based default currency
  static Future<AppSettings> createWithLocationBasedCurrency() async {
    final currency = await getDefaultCurrencyFromLocation();
    return AppSettings(
      currencySymbol: currency['symbol']!,
      currencyCode: currency['code']!,
      autoDetectCurrency: true, // Enable auto-detect by default
    );
  }

  // Get default currency (fallback to India)
  static Map<String, String> getDefaultCurrency() {
    return {'symbol': '₹', 'code': 'INR'};
  }
}
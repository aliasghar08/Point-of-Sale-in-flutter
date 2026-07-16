import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/settings_model.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings();
  bool _isLoading = false;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  // Theme related getters
  ThemeMode get themeMode {
    switch (_settings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String get currencySymbol => _settings.currencySymbol;
  String get currencyCode => _settings.currencyCode;
  bool get showProfitInPOS => _settings.showProfitInPOS;
  int get lowStockThreshold => _settings.lowStockThreshold;

  SettingsProvider() {
    loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? settingsJson = prefs.getString('app_settings');
      
      if (settingsJson != null) {
        final Map<String, dynamic> data = json.decode(settingsJson);
        _settings = AppSettings.fromMap(data);
      }
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_settings', json.encode(_settings.toMap()));
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  // Update settings
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    notifyListeners();
  }

  // Update individual settings
  Future<void> updateThemeMode(String themeMode) async {
    _settings = _settings.copyWith(themeMode: themeMode);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateCurrency(String symbol, String code) async {
    _settings = _settings.copyWith(
      currencySymbol: symbol,
      currencyCode: code,
    );
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateLowStockThreshold(int threshold) async {
    _settings = _settings.copyWith(lowStockThreshold: threshold);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleShowProfit() async {
    _settings = _settings.copyWith(showProfitInPOS: !_settings.showProfitInPOS);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    _settings = _settings.copyWith(enableNotifications: !_settings.enableNotifications);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleSound() async {
    _settings = _settings.copyWith(enableSound: !_settings.enableSound);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleVibration() async {
    _settings = _settings.copyWith(enableVibration: !_settings.enableVibration);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleAutoPrint() async {
    _settings = _settings.copyWith(autoPrintReceipt: !_settings.autoPrintReceipt);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleOfflineMode() async {
    _settings = _settings.copyWith(enableOfflineMode: !_settings.enableOfflineMode);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleAutoSync() async {
    _settings = _settings.copyWith(autoSyncData: !_settings.autoSyncData);
    await _saveSettings();
    notifyListeners();
  }

  // Reset to default settings
  Future<void> resetToDefault() async {
    _settings = AppSettings();
    await _saveSettings();
    notifyListeners();
  }
}
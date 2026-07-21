import 'package:flutter/material.dart';
import 'package:pos/providers/settings_provider.dart';
import 'package:pos/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pos/providers/auth_provider.dart';
import 'package:pos/services/permission_service.dart';
import 'package:pos/models/countries.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _storeNameController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'owner';
  bool _isDetectingCountry = false;
  bool _locationPermissionDenied = false;

  // Country code related - Default to Pakistan
  String _selectedCountryCode = '+92';
  String _countryFlag = '🇵🇰';
  String _countryName = 'Pakistan';

  // ✅ Use the imported countries list
  List<Country> get _countries => countries;

  @override
  void initState() {
    super.initState();
    // ✅ Set Pakistan as default immediately
    _setDefaultCountry();
    // Then try to detect country
    _detectCountry();
    
    // ✅ Add listener to format phone number as user types
    _phoneController.addListener(_formatPhoneNumberOnType);
  }

  // ✅ Set Pakistan as default country
  void _setDefaultCountry() {
    final pakistan = CountryHelper.getCountryByCode('+92');
    if (pakistan != null) {
      setState(() {
        _selectedCountryCode = pakistan.code;
        _countryFlag = pakistan.flag;
        _countryName = pakistan.name;
      });
    }
  }

  // ✅ Format phone number as user types
  void _formatPhoneNumberOnType() {
    final text = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (text.isEmpty) return;

    String formatted = '';
    if (text.length <= 4) {
      formatted = text;
    } else if (text.length <= 7) {
      formatted = '${text.substring(0, 4)} ${text.substring(4)}';
    } else {
      formatted = '${text.substring(0, 4)} ${text.substring(4, 7)} ${text.substring(7)}';
    }

    if (_phoneController.text != formatted) {
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> _detectCountry() async {
    setState(() {
      _isDetectingCountry = true;
      _locationPermissionDenied = false;
    });

    try {
      String? detectedCountryCode;

      // ===== METHOD 1: Try IP Geolocation =====
      try {
        final response = await http
            .get(Uri.parse('https://ip-api.com/json/'))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'success') {
            detectedCountryCode = data['countryCode']?.toString().toUpperCase();
            print('📍 Country detected via IP: $detectedCountryCode');
          }
        }
      } catch (e) {
        print('IP Geolocation failed: $e');
      }

      // ===== METHOD 2: Try Device Locale =====
      if (detectedCountryCode == null || detectedCountryCode.isEmpty) {
        try {
          final locale = WidgetsBinding.instance.platformDispatcher.locale;
          detectedCountryCode = locale.countryCode?.toUpperCase() ?? '';
          print('📍 Country detected via Locale: $detectedCountryCode');
        } catch (e) {
          print('Locale detection failed: $e');
        }
      }

      // ===== SET FINAL COUNTRY =====
      if (detectedCountryCode != null && 
          detectedCountryCode.isNotEmpty && 
          detectedCountryCode != 'US' && 
          detectedCountryCode != 'CA') {
        final matchingCountry = CountryHelper.getCountryByIso(detectedCountryCode);
        
        if (matchingCountry != null) {
          setState(() {
            _selectedCountryCode = matchingCountry.code;
            _countryFlag = matchingCountry.flag;
            _countryName = matchingCountry.name;
            _isDetectingCountry = false;
          });
          print('✅ Country set to: $_countryName ($_selectedCountryCode)');
        } else {
          print('⚠️ Country not found, keeping Pakistan');
          setState(() {
            _isDetectingCountry = false;
          });
        }
      } else {
        print('⚠️ Keeping default country: Pakistan (+92)');
        setState(() {
          _isDetectingCountry = false;
        });
      }
    } catch (e) {
      print('❌ Country detection error: $e');
      setState(() {
        _isDetectingCountry = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final currencySymbol = settingsProvider.currencySymbol;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Account',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.white),
        ),
        backgroundColor: isDarkMode
            ? Colors.blue.shade800
            : Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo/Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.storefront,
                size: 40,
                color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Create Your Business',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set up your business and add your first team member',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            // Currency display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.blue.shade900.withOpacity(0.5)
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.blue.shade700
                      : Colors.blue.shade200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.currency_exchange,
                    size: 14,
                    color: isDarkMode
                        ? Colors.blue.shade400
                        : Colors.blue.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Currency: $currencySymbol',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.blue.shade400
                          : Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Show detection status
            if (_isDetectingCountry)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.blue.shade900.withOpacity(0.5)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Detecting your country...',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode
                            ? Colors.blue.shade400
                            : Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            // Show location permission status
            if (_locationPermissionDenied)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.orange.shade900.withOpacity(0.5)
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.orange.shade700
                        : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 16,
                      color: isDarkMode
                          ? Colors.orange.shade400
                          : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location permission denied. Using default country.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? Colors.orange.shade400
                              : Colors.orange.shade700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        PermissionService.openAppSettings();
                      },
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? Colors.blue.shade400
                              : Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // ===== BUSINESS/STORE NAME (NEW) =====
                  TextFormField(
                    controller: _storeNameController,
                    decoration: InputDecoration(
                      labelText: 'Business / Store Name *',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      hintText: 'Enter your business name',
                      hintStyle: TextStyle(
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      prefixIcon: Icon(
                        Icons.storefront,
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade50,
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your business name';
                      }
                      if (value.length < 3) {
                        return 'Business name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // ===== YOUR NAME (Owner) =====
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Your Full Name (Owner) *',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      hintText: 'Enter your full name',
                      hintStyle: TextStyle(
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      prefixIcon: Icon(
                        Icons.person,
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade50,
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      if (value.length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email *',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      hintText: 'Enter your email',
                      hintStyle: TextStyle(
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      prefixIcon: Icon(
                        Icons.email,
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!EmailValidator.validate(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      hintText: 'Enter your password',
                      hintStyle: TextStyle(
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      prefixIcon: Icon(
                        Icons.lock,
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade50,
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password *',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      hintText: 'Confirm your password',
                      hintStyle: TextStyle(
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade50,
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // ===== PHONE NUMBER WITH COUNTRY CODE =====
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.grey.shade600
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCountryCode,
                            isExpanded: true,
                            dropdownColor: isDarkMode
                                ? Colors.grey.shade800
                                : Colors.white,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: 12,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            items: _countries.map((country) {
                              return DropdownMenuItem(
                                value: country.code,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(country.flag, style: const TextStyle(fontSize: 14)),
                                    const SizedBox(width: 2),
                                    Text(
                                      country.iso,
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      country.code,
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade500,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                final selected = CountryHelper.getCountryByCode(value)!;
                                setState(() {
                                  _selectedCountryCode = selected.code;
                                  _countryFlag = selected.flag;
                                  _countryName = selected.name;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number *',
                            labelStyle: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            hintText: '0300 123 4567',
                            hintStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                            prefixIcon: Icon(
                              Icons.phone,
                              color: isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.grey.shade800
                                : Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                            if (digitsOnly.length < 7) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  if (!_isDetectingCountry)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Row(
                        children: [
                          Text(
                            '$_countryFlag $_countryName',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? Colors.green.shade400
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_phoneController.text.isNotEmpty)
                            Text(
                              '• Full: $_selectedCountryCode ${_phoneController.text}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // ===== ROLE SELECTION (Now only Owner is shown, others added later) =====
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.blue.shade900.withOpacity(0.3)
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.blue.shade700
                            : Colors.blue.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: isDarkMode
                              ? Colors.blue.shade400
                              : Colors.blue.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Role: Owner',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                'You are creating this business as the owner. '
                                'You can add managers and workers later.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.orange.shade900.withOpacity(0.5)
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.orange.shade700
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: isDarkMode
                              ? Colors.orange.shade400
                              : Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Each business can have only ONE manager. '
                            'Additional managers cannot be added.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? Colors.orange.shade400
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (authProvider.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.red.shade900.withOpacity(0.5)
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.red.shade700
                              : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: isDarkMode
                                ? Colors.red.shade400
                                : Colors.red.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authProvider.error!,
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.red.shade400
                                    : Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: isDarkMode
                                  ? Colors.red.shade400
                                  : Colors.red.shade700,
                            ),
                            onPressed: () {
                              authProvider.clearError();
                            },
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading || _isDetectingCountry
                          ? null
                          : () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
                                
                                // ✅ The business name is now stored as the storeName
                                // ✅ The owner is created with role 'owner'
                                bool success = await authProvider.signUp(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                  name: _nameController.text.trim(),
                                  role: 'owner',  // Always owner for the first user
                                  phone: _selectedCountryCode + phoneDigits,
                                  storeName: _storeNameController.text.trim(),
                                );

                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Business created successfully! Please sign in.',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      backgroundColor: isDarkMode
                                          ? Colors.green.shade400
                                          : Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(8),
                                        ),
                                      ),
                                    ),
                                  );

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? Colors.blue.shade400
                            : Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: isDarkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Create Business',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account?',
                  style: TextStyle(
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.blue.shade400
                          : Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Version info
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
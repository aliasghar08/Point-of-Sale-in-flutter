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
import 'package:pos/services/firebase_service.dart';

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

  // ✅ Business suggestions
  final FirebaseService _firebaseService = FirebaseService();
  List<String> _businessSuggestions = [];
  bool _showSuggestions = false;
  bool _isValidatingBusiness = false;
  String? _businessValidationError;

  // ✅ Add role options
  final List<Map<String, dynamic>> _roleOptions = [
    {'value': 'owner', 'label': 'Owner', 'icon': Icons.admin_panel_settings},
    {'value': 'manager', 'label': 'Manager', 'icon': Icons.people_alt},
    {'value': 'worker', 'label': 'Worker', 'icon': Icons.person_outline},
  ];

  // Use the imported countries list
  List<Country> get _countries => countries;

  @override
  void initState() {
    super.initState();
    _setDefaultCountry();
    _detectCountry();
    _phoneController.addListener(_formatPhoneNumberOnType);
    _storeNameController.addListener(_onBusinessNameChanged);
  }

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

  // ✅ Fixed phone number formatting - formats as XXX XXX XXXX
  void _formatPhoneNumberOnType() {
    final text = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (text.isEmpty) {
      if (_phoneController.text.isNotEmpty) {
        _phoneController.text = '';
      }
      return;
    }

    // Silently remove leading zero if present
    String cleaned = text;
    while (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    // Limit to 10 digits max (for PK phone numbers)
    if (cleaned.length > 10) {
      cleaned = cleaned.substring(0, 10);
    }

    // ✅ CHANGED: Format the number to XXX XXX XXXX
    String formatted = '';
    if (cleaned.isEmpty) {
      formatted = '';
    } else if (cleaned.length <= 3) {
      formatted = cleaned;
    } else if (cleaned.length <= 6) {
      formatted = '${cleaned.substring(0, 3)} ${cleaned.substring(3)}';
    } else {
      formatted =
          '${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    }

    // Update the text field
    if (_phoneController.text != formatted) {
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  // Handle business name changes for suggestions
  void _onBusinessNameChanged() {
    final query = _storeNameController.text;
    if (query.isEmpty) {
      setState(() {
        _businessSuggestions = [];
        _showSuggestions = false;
        _businessValidationError = null;
      });
      return;
    }

    // Only show suggestions if role is manager or worker (NOT for owner)
    // Owner should not see suggestions, they are creating a new business
    if (_selectedRole == 'owner') {
      setState(() {
        _businessSuggestions = [];
        _showSuggestions = false;
        _businessValidationError = null;
      });
      return;
    }

    // Search for businesses (for manager/worker)
    _searchBusinesses(query);
  }

  // Search businesses for suggestions (only for manager/worker)
  Future<void> _searchBusinesses(String query) async {
    if (query.length < 2) {
      setState(() {
        _businessSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    try {
      final results = await _firebaseService.searchBusinesses(query);
      setState(() {
        _businessSuggestions = results.map((b) => b['name'] as String).toList();
        _showSuggestions = true;
        _businessValidationError = null;
      });
    } catch (e) {
      setState(() {
        _businessSuggestions = [];
        _showSuggestions = false;
      });
    }
  }

  // Validate business name when user selects or types (only for manager/worker)
  Future<void> _validateBusinessName() async {
    final businessName = _storeNameController.text.trim();
    if (businessName.isEmpty) {
      setState(() {
        _businessValidationError = 'Please enter a business name';
      });
      return;
    }

    setState(() {
      _isValidatingBusiness = true;
      _businessValidationError = null;
    });

    try {
      final exists = await _firebaseService.businessExists(businessName);
      if (!exists) {
        setState(() {
          _businessValidationError =
              'Business "$businessName" not found. Please check the spelling or create a new business as Owner.';
          _isValidatingBusiness = false;
        });
      } else {
        setState(() {
          _businessValidationError = null;
          _isValidatingBusiness = false;
          _showSuggestions = false;
        });
      }
    } catch (e) {
      setState(() {
        _businessValidationError = 'Error validating business: $e';
        _isValidatingBusiness = false;
      });
    }
  }

  // Select a suggestion (only for manager/worker)
  void _selectSuggestion(String suggestion) {
    setState(() {
      _storeNameController.text = suggestion;
      _businessSuggestions = [];
      _showSuggestions = false;
      _businessValidationError = null;
    });
    // Validate after selection
    _validateBusinessName();
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
            debugPrint('📍 Country detected via IP: $detectedCountryCode');
          }
        }
      } catch (e) {
        debugPrint('IP Geolocation failed: $e');
      }

      // ===== METHOD 2: Try Device Locale =====
      if (detectedCountryCode == null || detectedCountryCode.isEmpty) {
        try {
          final locale = WidgetsBinding.instance.platformDispatcher.locale;
          detectedCountryCode = locale.countryCode?.toUpperCase() ?? '';
          debugPrint('📍 Country detected via Locale: $detectedCountryCode');
        } catch (e) {
          debugPrint('Locale detection failed: $e');
        }
      }

      // ===== SET FINAL COUNTRY =====
      if (detectedCountryCode != null &&
          detectedCountryCode.isNotEmpty &&
          detectedCountryCode != 'US' &&
          detectedCountryCode != 'CA') {
        final matchingCountry = CountryHelper.getCountryByIso(
          detectedCountryCode,
        );

        if (matchingCountry != null) {
          setState(() {
            _selectedCountryCode = matchingCountry.code;
            _countryFlag = matchingCountry.flag;
            _countryName = matchingCountry.name;
            _isDetectingCountry = false;
          });
          debugPrint('✅ Country set to: $_countryName ($_selectedCountryCode)');
        } else {
          debugPrint('⚠️ Country not found, keeping Pakistan');
          setState(() {
            _isDetectingCountry = false;
          });
        }
      } else {
        debugPrint('⚠️ Keeping default country: Pakistan (+92)');
        setState(() {
          _isDetectingCountry = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Country detection error: $e');
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

    // Business name field is ALWAYS enabled
    // Only show suggestions for manager/worker
    final bool showBusinessSuggestions =
        (_selectedRole == 'manager' || _selectedRole == 'worker') &&
        _showSuggestions &&
        _businessSuggestions.isNotEmpty;

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
              'Create Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedRole == 'owner'
                  ? 'Set up your business and add your first team member'
                  : 'Join an existing business as a $_selectedRole',
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
                  // ===== ROLE SELECTION DROPDOWN (Moved to top) =====
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role *',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      dropdownColor: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.white,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      items: _roleOptions.map((role) {
                        return DropdownMenuItem(
                          value: role['value'] as String,
                          child: Row(
                            children: [
                              Icon(
                                role['icon'],
                                size: 20,
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                role['label'],
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                          _businessSuggestions = [];
                          _showSuggestions = false;
                          _businessValidationError = null;
                          _storeNameController.clear();
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a role';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 8),
                  // Info about roles
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.blue.shade900.withOpacity(0.3)
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.blue.shade700
                            : Colors.blue.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedRole == 'owner'
                              ? Icons.admin_panel_settings
                              : Icons.info_outline,
                          size: 16,
                          color: isDarkMode
                              ? Colors.blue.shade400
                              : Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedRole == 'owner'
                                ? 'You are creating a new business as the owner.'
                                : 'You are joining an existing business as a $_selectedRole.',
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

                  const SizedBox(height: 16),

                  // ===== BUSINESS/STORE NAME (ALWAYS ENABLED) =====
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _storeNameController,
                              enabled: true, // ALWAYS ENABLED
                              decoration: InputDecoration(
                                labelText: 'Business / Store Name *',
                                labelStyle: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                hintText: _selectedRole == 'owner'
                                    ? 'Enter your business name'
                                    : 'Enter existing business name',
                                hintStyle: TextStyle(
                                  color: isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                                prefixIcon: Icon(
                                  _selectedRole == 'owner'
                                      ? Icons.storefront
                                      : Icons.search,
                                  color: isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                                suffixIcon: _isValidatingBusiness
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : null,
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
                                  return 'Please enter a business name';
                                }
                                if (_selectedRole != 'owner' &&
                                    _businessValidationError != null) {
                                  return _businessValidationError;
                                }
                                return null;
                              },
                            ),
                          ),
                          if (_selectedRole != 'owner' &&
                              _storeNameController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.check_circle,
                                color: _businessValidationError == null
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              onPressed: _validateBusinessName,
                              tooltip: 'Validate Business',
                            ),
                        ],
                      ),
                      // Suggestions dropdown (only for manager/worker)
                      if (showBusinessSuggestions)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey.shade800
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(maxHeight: 150),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _businessSuggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = _businessSuggestions[index];
                              return Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  leading: Icon(
                                    Icons.storefront,
                                    color: isDarkMode
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                    size: 16,
                                  ),
                                  title: Text(
                                    suggestion,
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.add_circle_outline,
                                    color: isDarkMode
                                        ? Colors.blue.shade400
                                        : Colors.blue.shade700,
                                    size: 16,
                                  ),
                                  onTap: () => _selectSuggestion(suggestion),
                                ),
                              );
                            },
                          ),
                        ),
                      // Validation error message (only for manager/worker)
                      if (_selectedRole != 'owner' &&
                          _businessValidationError != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.red.shade900.withOpacity(0.3)
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 14,
                                color: isDarkMode
                                    ? Colors.red.shade400
                                    : Colors.red.shade700,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _businessValidationError!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode
                                        ? Colors.red.shade400
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Found message (only for manager/worker)
                      if (_selectedRole != 'owner' &&
                          _businessValidationError == null &&
                          _storeNameController.text.isNotEmpty &&
                          !_isValidatingBusiness)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.green.shade900.withOpacity(0.3)
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: isDarkMode
                                    ? Colors.green.shade400
                                    : Colors.green.shade700,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '✓ Business found! You will be added as a $_selectedRole.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode
                                        ? Colors.green.shade400
                                        : Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ===== YOUR NAME =====
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Your Full Name *',
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
                                    Text(
                                      country.flag,
                                      style: const TextStyle(fontSize: 14),
                                    ),
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
                                final selected = CountryHelper.getCountryByCode(
                                  value,
                                )!;
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
                            hintText: '300 123 4567',
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
                            _NoLeadingZeroFormatter(),
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(
                              10,
                            ), // Limit to 10 digits
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            final digitsOnly = value.replaceAll(
                              RegExp(r'\D'),
                              '',
                            );
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
                                final phoneDigits = _phoneController.text
                                    .replaceAll(RegExp(r'\D'), '');

                                bool success = await authProvider.signUp(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                  name: _nameController.text.trim(),
                                  role: _selectedRole,
                                  phone: _selectedCountryCode + phoneDigits,
                                  storeName: _storeNameController.text.trim(),
                                );

                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _selectedRole == 'owner'
                                            ? 'Business created successfully! Please sign in.'
                                            : 'Account created successfully! Please sign in.',
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
                                      shape: const RoundedRectangleBorder(
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
                          : Text(
                              _selectedRole == 'owner'
                                  ? 'Create Business'
                                  : 'Join Business',
                              style: const TextStyle(
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

// Custom TextInputFormatter that silently removes leading zero
class _NoLeadingZeroFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Get the text without spaces
    final String newText = newValue.text.replaceAll(RegExp(r'\s'), '');

    // If the text starts with '0', silently remove it
    if (newText.startsWith('0')) {
      final String cleanedText = newValue.text.replaceFirst('0', '');
      return newValue.copyWith(
        text: cleanedText,
        selection: TextSelection.collapsed(offset: cleanedText.length),
      );
    }

    return newValue;
  }
}

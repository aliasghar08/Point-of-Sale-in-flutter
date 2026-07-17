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

  // List of countries with codes - Including Pakistan
  final List<Map<String, String>> _countries = [
    // ... (keep your existing countries list)
    {'code': '+93', 'flag': '🇦🇫', 'name': 'Afghanistan'},
    {'code': '+355', 'flag': '🇦🇱', 'name': 'Albania'},
    {'code': '+213', 'flag': '🇩🇿', 'name': 'Algeria'},
    {'code': '+376', 'flag': '🇦🇩', 'name': 'Andorra'},
    {'code': '+244', 'flag': '🇦🇴', 'name': 'Angola'},
    {'code': '+54', 'flag': '🇦🇷', 'name': 'Argentina'},
    {'code': '+61', 'flag': '🇦🇺', 'name': 'Australia'},
    {'code': '+43', 'flag': '🇦🇹', 'name': 'Austria'},
    {'code': '+994', 'flag': '🇦🇿', 'name': 'Azerbaijan'},
    {'code': '+1242', 'flag': '🇧🇸', 'name': 'Bahamas'},
    {'code': '+973', 'flag': '🇧🇭', 'name': 'Bahrain'},
    {'code': '+880', 'flag': '🇧🇩', 'name': 'Bangladesh'},
    {'code': '+375', 'flag': '🇧🇾', 'name': 'Belarus'},
    {'code': '+32', 'flag': '🇧🇪', 'name': 'Belgium'},
    {'code': '+501', 'flag': '🇧🇿', 'name': 'Belize'},
    {'code': '+229', 'flag': '🇧🇯', 'name': 'Benin'},
    {'code': '+975', 'flag': '🇧🇹', 'name': 'Bhutan'},
    {'code': '+591', 'flag': '🇧🇴', 'name': 'Bolivia'},
    {'code': '+387', 'flag': '🇧🇦', 'name': 'Bosnia'},
    {'code': '+267', 'flag': '🇧🇼', 'name': 'Botswana'},
    {'code': '+55', 'flag': '🇧🇷', 'name': 'Brazil'},
    {'code': '+673', 'flag': '🇧🇳', 'name': 'Brunei'},
    {'code': '+359', 'flag': '🇧🇬', 'name': 'Bulgaria'},
    {'code': '+226', 'flag': '🇧🇫', 'name': 'Burkina Faso'},
    {'code': '+95', 'flag': '🇲🇲', 'name': 'Myanmar'},
    {'code': '+257', 'flag': '🇧🇮', 'name': 'Burundi'},
    {'code': '+855', 'flag': '🇰🇭', 'name': 'Cambodia'},
    {'code': '+237', 'flag': '🇨🇲', 'name': 'Cameroon'},
    {'code': '+1', 'flag': '🇨🇦', 'name': 'Canada'},
    {'code': '+238', 'flag': '🇨🇻', 'name': 'Cape Verde'},
    {'code': '+236', 'flag': '🇨🇫', 'name': 'Central African Republic'},
    {'code': '+235', 'flag': '🇹🇩', 'name': 'Chad'},
    {'code': '+56', 'flag': '🇨🇱', 'name': 'Chile'},
    {'code': '+86', 'flag': '🇨🇳', 'name': 'China'},
    {'code': '+57', 'flag': '🇨🇴', 'name': 'Colombia'},
    {'code': '+269', 'flag': '🇰🇲', 'name': 'Comoros'},
    {'code': '+242', 'flag': '🇨🇬', 'name': 'Congo'},
    {'code': '+506', 'flag': '🇨🇷', 'name': 'Costa Rica'},
    {'code': '+385', 'flag': '🇭🇷', 'name': 'Croatia'},
    {'code': '+53', 'flag': '🇨🇺', 'name': 'Cuba'},
    {'code': '+357', 'flag': '🇨🇾', 'name': 'Cyprus'},
    {'code': '+420', 'flag': '🇨🇿', 'name': 'Czech Republic'},
    {'code': '+45', 'flag': '🇩🇰', 'name': 'Denmark'},
    {'code': '+253', 'flag': '🇩🇯', 'name': 'Djibouti'},
    {'code': '+1809', 'flag': '🇩🇴', 'name': 'Dominican Republic'},
    {'code': '+593', 'flag': '🇪🇨', 'name': 'Ecuador'},
    {'code': '+20', 'flag': '🇪🇬', 'name': 'Egypt'},
    {'code': '+503', 'flag': '🇸🇻', 'name': 'El Salvador'},
    {'code': '+240', 'flag': '🇬🇶', 'name': 'Equatorial Guinea'},
    {'code': '+291', 'flag': '🇪🇷', 'name': 'Eritrea'},
    {'code': '+372', 'flag': '🇪🇪', 'name': 'Estonia'},
    {'code': '+251', 'flag': '🇪🇹', 'name': 'Ethiopia'},
    {'code': '+679', 'flag': '🇫🇯', 'name': 'Fiji'},
    {'code': '+358', 'flag': '🇫🇮', 'name': 'Finland'},
    {'code': '+33', 'flag': '🇫🇷', 'name': 'France'},
    {'code': '+241', 'flag': '🇬🇦', 'name': 'Gabon'},
    {'code': '+220', 'flag': '🇬🇲', 'name': 'Gambia'},
    {'code': '+995', 'flag': '🇬🇪', 'name': 'Georgia'},
    {'code': '+49', 'flag': '🇩🇪', 'name': 'Germany'},
    {'code': '+233', 'flag': '🇬🇭', 'name': 'Ghana'},
    {'code': '+30', 'flag': '🇬🇷', 'name': 'Greece'},
    {'code': '+502', 'flag': '🇬🇹', 'name': 'Guatemala'},
    {'code': '+224', 'flag': '🇬🇳', 'name': 'Guinea'},
    {'code': '+592', 'flag': '🇬🇾', 'name': 'Guyana'},
    {'code': '+509', 'flag': '🇭🇹', 'name': 'Haiti'},
    {'code': '+504', 'flag': '🇭🇳', 'name': 'Honduras'},
    {'code': '+36', 'flag': '🇭🇺', 'name': 'Hungary'},
    {'code': '+354', 'flag': '🇮🇸', 'name': 'Iceland'},
    {'code': '+91', 'flag': '🇮🇳', 'name': 'India'},
    {'code': '+62', 'flag': '🇮🇩', 'name': 'Indonesia'},
    {'code': '+98', 'flag': '🇮🇷', 'name': 'Iran'},
    {'code': '+964', 'flag': '🇮🇶', 'name': 'Iraq'},
    {'code': '+353', 'flag': '🇮🇪', 'name': 'Ireland'},
    {'code': '+972', 'flag': '🇮🇱', 'name': 'Israel'},
    {'code': '+39', 'flag': '🇮🇹', 'name': 'Italy'},
    {'code': '+225', 'flag': '🇨🇮', 'name': 'Ivory Coast'},
    {'code': '+81', 'flag': '🇯🇵', 'name': 'Japan'},
    {'code': '+962', 'flag': '🇯🇴', 'name': 'Jordan'},
    {'code': '+7', 'flag': '🇰🇿', 'name': 'Kazakhstan'},
    {'code': '+254', 'flag': '🇰🇪', 'name': 'Kenya'},
    {'code': '+686', 'flag': '🇰🇮', 'name': 'Kiribati'},
    {'code': '+965', 'flag': '🇰🇼', 'name': 'Kuwait'},
    {'code': '+996', 'flag': '🇰🇬', 'name': 'Kyrgyzstan'},
    {'code': '+856', 'flag': '🇱🇦', 'name': 'Laos'},
    {'code': '+371', 'flag': '🇱🇻', 'name': 'Latvia'},
    {'code': '+961', 'flag': '🇱🇧', 'name': 'Lebanon'},
    {'code': '+266', 'flag': '🇱🇸', 'name': 'Lesotho'},
    {'code': '+231', 'flag': '🇱🇷', 'name': 'Liberia'},
    {'code': '+218', 'flag': '🇱🇾', 'name': 'Libya'},
    {'code': '+423', 'flag': '🇱🇮', 'name': 'Liechtenstein'},
    {'code': '+370', 'flag': '🇱🇹', 'name': 'Lithuania'},
    {'code': '+352', 'flag': '🇱🇺', 'name': 'Luxembourg'},
    {'code': '+261', 'flag': '🇲🇬', 'name': 'Madagascar'},
    {'code': '+265', 'flag': '🇲🇼', 'name': 'Malawi'},
    {'code': '+60', 'flag': '🇲🇾', 'name': 'Malaysia'},
    {'code': '+960', 'flag': '🇲🇻', 'name': 'Maldives'},
    {'code': '+223', 'flag': '🇲🇱', 'name': 'Mali'},
    {'code': '+356', 'flag': '🇲🇹', 'name': 'Malta'},
    {'code': '+692', 'flag': '🇲🇭', 'name': 'Marshall Islands'},
    {'code': '+222', 'flag': '🇲🇷', 'name': 'Mauritania'},
    {'code': '+230', 'flag': '🇲🇺', 'name': 'Mauritius'},
    {'code': '+52', 'flag': '🇲🇽', 'name': 'Mexico'},
    {'code': '+691', 'flag': '🇫🇲', 'name': 'Micronesia'},
    {'code': '+373', 'flag': '🇲🇩', 'name': 'Moldova'},
    {'code': '+377', 'flag': '🇲🇨', 'name': 'Monaco'},
    {'code': '+976', 'flag': '🇲🇳', 'name': 'Mongolia'},
    {'code': '+382', 'flag': '🇲🇪', 'name': 'Montenegro'},
    {'code': '+212', 'flag': '🇲🇦', 'name': 'Morocco'},
    {'code': '+258', 'flag': '🇲🇿', 'name': 'Mozambique'},
    {'code': '+264', 'flag': '🇳🇦', 'name': 'Namibia'},
    {'code': '+674', 'flag': '🇳🇷', 'name': 'Nauru'},
    {'code': '+977', 'flag': '🇳🇵', 'name': 'Nepal'},
    {'code': '+31', 'flag': '🇳🇱', 'name': 'Netherlands'},
    {'code': '+64', 'flag': '🇳🇿', 'name': 'New Zealand'},
    {'code': '+505', 'flag': '🇳🇮', 'name': 'Nicaragua'},
    {'code': '+227', 'flag': '🇳🇪', 'name': 'Niger'},
    {'code': '+234', 'flag': '🇳🇬', 'name': 'Nigeria'},
    {'code': '+47', 'flag': '🇳🇴', 'name': 'Norway'},
    {'code': '+968', 'flag': '🇴🇲', 'name': 'Oman'},
    {'code': '+92', 'flag': '🇵🇰', 'name': 'Pakistan'},
    {'code': '+680', 'flag': '🇵🇼', 'name': 'Palau'},
    {'code': '+507', 'flag': '🇵🇦', 'name': 'Panama'},
    {'code': '+675', 'flag': '🇵🇬', 'name': 'Papua New Guinea'},
    {'code': '+595', 'flag': '🇵🇾', 'name': 'Paraguay'},
    {'code': '+51', 'flag': '🇵🇪', 'name': 'Peru'},
    {'code': '+63', 'flag': '🇵🇭', 'name': 'Philippines'},
    {'code': '+48', 'flag': '🇵🇱', 'name': 'Poland'},
    {'code': '+351', 'flag': '🇵🇹', 'name': 'Portugal'},
    {'code': '+974', 'flag': '🇶🇦', 'name': 'Qatar'},
    {'code': '+40', 'flag': '🇷🇴', 'name': 'Romania'},
    {'code': '+7', 'flag': '🇷🇺', 'name': 'Russia'},
    {'code': '+250', 'flag': '🇷🇼', 'name': 'Rwanda'},
    {'code': '+685', 'flag': '🇼🇸', 'name': 'Samoa'},
    {'code': '+378', 'flag': '🇸🇲', 'name': 'San Marino'},
    {'code': '+966', 'flag': '🇸🇦', 'name': 'Saudi Arabia'},
    {'code': '+221', 'flag': '🇸🇳', 'name': 'Senegal'},
    {'code': '+381', 'flag': '🇷🇸', 'name': 'Serbia'},
    {'code': '+248', 'flag': '🇸🇨', 'name': 'Seychelles'},
    {'code': '+232', 'flag': '🇸🇱', 'name': 'Sierra Leone'},
    {'code': '+65', 'flag': '🇸🇬', 'name': 'Singapore'},
    {'code': '+421', 'flag': '🇸🇰', 'name': 'Slovakia'},
    {'code': '+386', 'flag': '🇸🇮', 'name': 'Slovenia'},
    {'code': '+677', 'flag': '🇸🇧', 'name': 'Solomon Islands'},
    {'code': '+252', 'flag': '🇸🇴', 'name': 'Somalia'},
    {'code': '+27', 'flag': '🇿🇦', 'name': 'South Africa'},
    {'code': '+82', 'flag': '🇰🇷', 'name': 'South Korea'},
    {'code': '+34', 'flag': '🇪🇸', 'name': 'Spain'},
    {'code': '+94', 'flag': '🇱🇰', 'name': 'Sri Lanka'},
    {'code': '+249', 'flag': '🇸🇩', 'name': 'Sudan'},
    {'code': '+597', 'flag': '🇸🇷', 'name': 'Suriname'},
    {'code': '+268', 'flag': '🇸🇿', 'name': 'Eswatini'},
    {'code': '+46', 'flag': '🇸🇪', 'name': 'Sweden'},
    {'code': '+41', 'flag': '🇨🇭', 'name': 'Switzerland'},
    {'code': '+963', 'flag': '🇸🇾', 'name': 'Syria'},
    {'code': '+886', 'flag': '🇹🇼', 'name': 'Taiwan'},
    {'code': '+992', 'flag': '🇹🇯', 'name': 'Tajikistan'},
    {'code': '+255', 'flag': '🇹🇿', 'name': 'Tanzania'},
    {'code': '+66', 'flag': '🇹🇭', 'name': 'Thailand'},
    {'code': '+228', 'flag': '🇹🇬', 'name': 'Togo'},
    {'code': '+676', 'flag': '🇹🇴', 'name': 'Tonga'},
    {'code': '+1868', 'flag': '🇹🇹', 'name': 'Trinidad'},
    {'code': '+216', 'flag': '🇹🇳', 'name': 'Tunisia'},
    {'code': '+90', 'flag': '🇹🇷', 'name': 'Turkey'},
    {'code': '+993', 'flag': '🇹🇲', 'name': 'Turkmenistan'},
    {'code': '+688', 'flag': '🇹🇻', 'name': 'Tuvalu'},
    {'code': '+256', 'flag': '🇺🇬', 'name': 'Uganda'},
    {'code': '+380', 'flag': '🇺🇦', 'name': 'Ukraine'},
    {'code': '+971', 'flag': '🇦🇪', 'name': 'UAE'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'United Kingdom'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'USA'},
    {'code': '+598', 'flag': '🇺🇾', 'name': 'Uruguay'},
    {'code': '+998', 'flag': '🇺🇿', 'name': 'Uzbekistan'},
    {'code': '+678', 'flag': '🇻🇺', 'name': 'Vanuatu'},
    {'code': '+58', 'flag': '🇻🇪', 'name': 'Venezuela'},
    {'code': '+84', 'flag': '🇻🇳', 'name': 'Vietnam'},
    {'code': '+967', 'flag': '🇾🇪', 'name': 'Yemen'},
    {'code': '+260', 'flag': '🇿🇲', 'name': 'Zambia'},
    {'code': '+263', 'flag': '🇿🇼', 'name': 'Zimbabwe'},
  ];

  @override
  void initState() {
    super.initState();
    _detectCountry();
  }

  Future<void> _detectCountry() async {
    setState(() {
      _isDetectingCountry = true;
      _locationPermissionDenied = false;
    });

    try {
      String? detectedCountryCode;

      // ===== METHOD 1: Try Location Permission (GPS) =====
      try {
        bool hasPermission =
            await PermissionService.isLocationPermissionGranted();

        if (!hasPermission) {
          bool granted = await PermissionService.requestLocationPermission();
          if (!granted) {
            _locationPermissionDenied = true;
            await PermissionService.showLocationPermissionDialog(context);
          }
        }

        if (await PermissionService.isLocationPermissionGranted()) {
          try {
            print('📍 Location permission granted, using IP detection fallback');
          } catch (e) {
            print('Location detection failed: $e');
          }
        }
      } catch (e) {
        print('Location permission check failed: $e');
      }

      // ===== METHOD 2: Try IP Geolocation =====
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

      // ===== METHOD 3: Try Device Locale =====
      if (detectedCountryCode == null ||
          detectedCountryCode.isEmpty ||
          detectedCountryCode == 'US') {
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
          detectedCountryCode != 'US') {
        final countryName = _getCountryNameFromCode(detectedCountryCode);
        final matchingCountry = _countries.firstWhere(
          (country) => country['name'] == countryName,
          orElse: () => {'code': '+92', 'flag': '🇵🇰', 'name': 'Pakistan'},
        );

        setState(() {
          _selectedCountryCode = matchingCountry['code']!;
          _countryFlag = matchingCountry['flag']!;
          _countryName = matchingCountry['name']!;
          _isDetectingCountry = false;
        });
        print('✅ Country set to: $_countryName ($_selectedCountryCode)');
      } else {
        setState(() {
          _selectedCountryCode = '+92';
          _countryFlag = '🇵🇰';
          _countryName = 'Pakistan';
          _isDetectingCountry = false;
        });
        print('⚠️ Using default country: Pakistan (+92)');
      }
    } catch (e) {
      print('❌ Country detection error: $e');
      setState(() {
        _selectedCountryCode = '+92';
        _countryFlag = '🇵🇰';
        _countryName = 'Pakistan';
        _isDetectingCountry = false;
      });
    }
  }

  String _getCountryNameFromCode(String code) {
    final countryNames = {
      'AF': 'Afghanistan',
      'AL': 'Albania',
      'DZ': 'Algeria',
      'AD': 'Andorra',
      'AO': 'Angola',
      'AR': 'Argentina',
      'AM': 'Armenia',
      'AU': 'Australia',
      'AT': 'Austria',
      'AZ': 'Azerbaijan',
      'BS': 'Bahamas',
      'BH': 'Bahrain',
      'BD': 'Bangladesh',
      'BY': 'Belarus',
      'BE': 'Belgium',
      'BZ': 'Belize',
      'BJ': 'Benin',
      'BT': 'Bhutan',
      'BO': 'Bolivia',
      'BA': 'Bosnia',
      'BW': 'Botswana',
      'BR': 'Brazil',
      'BN': 'Brunei',
      'BG': 'Bulgaria',
      'BF': 'Burkina',
      'BI': 'Burundi',
      'KH': 'Cambodia',
      'CM': 'Cameroon',
      'CA': 'Canada',
      'CV': 'Cape Verde',
      'CF': 'CAR',
      'TD': 'Chad',
      'CL': 'Chile',
      'CN': 'China',
      'CO': 'Colombia',
      'KM': 'Comoros',
      'CG': 'Congo',
      'CR': 'Costa Rica',
      'HR': 'Croatia',
      'CU': 'Cuba',
      'CY': 'Cyprus',
      'CZ': 'Czech',
      'DK': 'Denmark',
      'DJ': 'Djibouti',
      'DO': 'Dominican',
      'EC': 'Ecuador',
      'EG': 'Egypt',
      'SV': 'El Salvador',
      'GQ': 'Equatorial Guinea',
      'ER': 'Eritrea',
      'EE': 'Estonia',
      'ET': 'Ethiopia',
      'FJ': 'Fiji',
      'FI': 'Finland',
      'FR': 'France',
      'GA': 'Gabon',
      'GM': 'Gambia',
      'GE': 'Georgia',
      'DE': 'Germany',
      'GH': 'Ghana',
      'GR': 'Greece',
      'GT': 'Guatemala',
      'GN': 'Guinea',
      'GY': 'Guyana',
      'HT': 'Haiti',
      'HN': 'Honduras',
      'HU': 'Hungary',
      'IS': 'Iceland',
      'IN': 'India',
      'ID': 'Indonesia',
      'IR': 'Iran',
      'IQ': 'Iraq',
      'IE': 'Ireland',
      'IL': 'Israel',
      'IT': 'Italy',
      'CI': 'Ivory Coast',
      'JP': 'Japan',
      'JO': 'Jordan',
      'KZ': 'Kazakhstan',
      'KE': 'Kenya',
      'KI': 'Kiribati',
      'KW': 'Kuwait',
      'KG': 'Kyrgyzstan',
      'LA': 'Laos',
      'LV': 'Latvia',
      'LB': 'Lebanon',
      'LS': 'Lesotho',
      'LR': 'Liberia',
      'LY': 'Libya',
      'LI': 'Liechtenstein',
      'LT': 'Lithuania',
      'LU': 'Luxembourg',
      'MG': 'Madagascar',
      'MW': 'Malawi',
      'MY': 'Malaysia',
      'MV': 'Maldives',
      'ML': 'Mali',
      'MT': 'Malta',
      'MH': 'Marshall Islands',
      'MR': 'Mauritania',
      'MU': 'Mauritius',
      'MX': 'Mexico',
      'FM': 'Micronesia',
      'MD': 'Moldova',
      'MC': 'Monaco',
      'MN': 'Mongolia',
      'ME': 'Montenegro',
      'MA': 'Morocco',
      'MZ': 'Mozambique',
      'MM': 'Myanmar',
      'NA': 'Namibia',
      'NR': 'Nauru',
      'NP': 'Nepal',
      'NL': 'Netherlands',
      'NZ': 'New Zealand',
      'NI': 'Nicaragua',
      'NE': 'Niger',
      'NG': 'Nigeria',
      'NO': 'Norway',
      'OM': 'Oman',
      'PK': 'Pakistan',
      'PW': 'Palau',
      'PA': 'Panama',
      'PG': 'Papua New Guinea',
      'PY': 'Paraguay',
      'PE': 'Peru',
      'PH': 'Philippines',
      'PL': 'Poland',
      'PT': 'Portugal',
      'QA': 'Qatar',
      'RO': 'Romania',
      'RU': 'Russia',
      'RW': 'Rwanda',
      'WS': 'Samoa',
      'SM': 'San Marino',
      'SA': 'Saudi Arabia',
      'SN': 'Senegal',
      'RS': 'Serbia',
      'SC': 'Seychelles',
      'SL': 'Sierra Leone',
      'SG': 'Singapore',
      'SK': 'Slovakia',
      'SI': 'Slovenia',
      'SB': 'Solomon Islands',
      'SO': 'Somalia',
      'ZA': 'South Africa',
      'KR': 'South Korea',
      'ES': 'Spain',
      'LK': 'Sri Lanka',
      'SD': 'Sudan',
      'SR': 'Suriname',
      'SE': 'Sweden',
      'CH': 'Switzerland',
      'SY': 'Syria',
      'TW': 'Taiwan',
      'TJ': 'Tajikistan',
      'TZ': 'Tanzania',
      'TH': 'Thailand',
      'TG': 'Togo',
      'TO': 'Tonga',
      'TT': 'Trinidad',
      'TN': 'Tunisia',
      'TR': 'Turkey',
      'TM': 'Turkmenistan',
      'TV': 'Tuvalu',
      'UG': 'Uganda',
      'UA': 'Ukraine',
      'AE': 'UAE',
      'GB': 'United Kingdom',
      'US': 'USA',
      'UY': 'Uruguay',
      'UZ': 'Uzbekistan',
      'VU': 'Vanuatu',
      'VE': 'Venezuela',
      'VN': 'Vietnam',
      'YE': 'Yemen',
      'ZM': 'Zambia',
      'ZW': 'Zimbabwe',
    };
    return countryNames[code] ?? 'Pakistan';
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
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.white,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade700,
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
                Icons.person_add,
                size: 40,
                color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Create your account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in the details to get started',
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
                    color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Currency: $currencySymbol',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
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
                        color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
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
                      color: isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location permission denied. Using default country.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700,
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
                          color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
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
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name *',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      hintText: 'Enter your full name',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      prefixIcon: Icon(
                        Icons.person,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
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
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      prefixIcon: Icon(
                        Icons.email,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
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
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      prefixIcon: Icon(
                        Icons.lock,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
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
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
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
                  // ===== IMPROVED PHONE NUMBER WITH COUNTRY CODE =====
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Country Code Dropdown
                      Container(
                        width: 180,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
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
                              fontSize: 13,
                            ),
                            items: _countries.map((country) {
                              return DropdownMenuItem(
                                value: country['code'],
                                child: Row(
                                  children: [
                                    Text(country['flag']!),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        country['name']!,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      country['code']!,
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                final selected = _countries.firstWhere(
                                  (c) => c['code'] == value,
                                );
                                setState(() {
                                  _selectedCountryCode = value;
                                  _countryFlag = selected['flag']!;
                                  _countryName = selected['name']!;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Phone Number Input with better placeholder
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number *',
                            labelStyle: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            hintText: '3XX XXX XXXX',
                            hintStyle: TextStyle(
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                            prefixIcon: Icon(
                              Icons.phone,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
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
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.length < 7) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  // Show formatted preview
                  if (_phoneController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 12),
                      child: Row(
                        children: [
                          Text(
                            'Full Number: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '$_selectedCountryCode ${_formatPhoneNumber(_phoneController.text)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!_isDetectingCountry)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 12),
                      child: Row(
                        children: [
                          Text(
                            'Default country: ',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '$_countryFlag $_countryName',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($_selectedCountryCode)',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  // ===== REST OF THE FORM =====
                  TextFormField(
                    controller: _storeNameController,
                    decoration: InputDecoration(
                      labelText: 'Store Name *',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      hintText: 'Enter your store name',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      prefixIcon: Icon(
                        Icons.store,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
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
                        return 'Please enter your store name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Role selection
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role *',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.admin_panel_settings),
                      ),
                      dropdownColor: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.white,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'owner',
                          child: Text('Store Owner'),
                        ),
                        DropdownMenuItem(
                          value: 'manager',
                          child: Text('Manager'),
                        ),
                        DropdownMenuItem(
                          value: 'worker',
                          child: Text('Worker'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
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
                          color: isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'First user will be the store owner. Additional users can be added later.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700,
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
                            color: isDarkMode ? Colors.red.shade400 : Colors.red.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authProvider.error!,
                              style: TextStyle(
                                color: isDarkMode ? Colors.red.shade400 : Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: isDarkMode ? Colors.red.shade400 : Colors.red.shade700,
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
                                bool success = await authProvider.signUp(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                  name: _nameController.text.trim(),
                                  role: _selectedRole,
                                  phone:
                                      _selectedCountryCode +
                                      _phoneController.text.trim(),
                                  storeName: _storeNameController.text.trim(),
                                );

                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Account created successfully! Please sign in.',
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black,
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
                              'Create Account',
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
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
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

  // ===== HELPER METHOD TO FORMAT PHONE NUMBER =====
  String _formatPhoneNumber(String phone) {
    // Remove any non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');
    
    if (cleaned.length <= 3) {
      return cleaned;
    } else if (cleaned.length <= 6) {
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3)}';
    } else if (cleaned.length <= 10) {
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    } else {
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6, 10)}';
    }
  }
}
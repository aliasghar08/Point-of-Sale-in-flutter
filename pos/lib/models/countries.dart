class Country {
  final String code;
  final String flag;
  final String name;
  final String iso;

  const Country({
    required this.code,
    required this.flag,
    required this.name,
    required this.iso,
  });

  factory Country.fromMap(Map<String, String> map) {
    return Country(
      code: map['code']!,
      flag: map['flag']!,
      name: map['name']!,
      iso: map['iso']!,
    );
  }

  Map<String, String> toMap() {
    return {
      'code': code,
      'flag': flag,
      'name': name,
      'iso': iso,
    };
  }
}

// All countries data
final List<Country> countries = [
  Country(code: '+93', flag: '🇦🇫', name: 'Afghanistan', iso: 'AF'),
  Country(code: '+355', flag: '🇦🇱', name: 'Albania', iso: 'AL'),
  Country(code: '+213', flag: '🇩🇿', name: 'Algeria', iso: 'DZ'),
  Country(code: '+376', flag: '🇦🇩', name: 'Andorra', iso: 'AD'),
  Country(code: '+244', flag: '🇦🇴', name: 'Angola', iso: 'AO'),
  Country(code: '+54', flag: '🇦🇷', name: 'Argentina', iso: 'AR'),
  Country(code: '+61', flag: '🇦🇺', name: 'Australia', iso: 'AU'),
  Country(code: '+43', flag: '🇦🇹', name: 'Austria', iso: 'AT'),
  Country(code: '+994', flag: '🇦🇿', name: 'Azerbaijan', iso: 'AZ'),
  Country(code: '+1242', flag: '🇧🇸', name: 'Bahamas', iso: 'BS'),
  Country(code: '+973', flag: '🇧🇭', name: 'Bahrain', iso: 'BH'),
  Country(code: '+880', flag: '🇧🇩', name: 'Bangladesh', iso: 'BD'),
  Country(code: '+375', flag: '🇧🇾', name: 'Belarus', iso: 'BY'),
  Country(code: '+32', flag: '🇧🇪', name: 'Belgium', iso: 'BE'),
  Country(code: '+501', flag: '🇧🇿', name: 'Belize', iso: 'BZ'),
  Country(code: '+229', flag: '🇧🇯', name: 'Benin', iso: 'BJ'),
  Country(code: '+975', flag: '🇧🇹', name: 'Bhutan', iso: 'BT'),
  Country(code: '+591', flag: '🇧🇴', name: 'Bolivia', iso: 'BO'),
  Country(code: '+387', flag: '🇧🇦', name: 'Bosnia', iso: 'BA'),
  Country(code: '+267', flag: '🇧🇼', name: 'Botswana', iso: 'BW'),
  Country(code: '+55', flag: '🇧🇷', name: 'Brazil', iso: 'BR'),
  Country(code: '+673', flag: '🇧🇳', name: 'Brunei', iso: 'BN'),
  Country(code: '+359', flag: '🇧🇬', name: 'Bulgaria', iso: 'BG'),
  Country(code: '+226', flag: '🇧🇫', name: 'Burkina Faso', iso: 'BF'),
  Country(code: '+95', flag: '🇲🇲', name: 'Myanmar', iso: 'MM'),
  Country(code: '+257', flag: '🇧🇮', name: 'Burundi', iso: 'BI'),
  Country(code: '+855', flag: '🇰🇭', name: 'Cambodia', iso: 'KH'),
  Country(code: '+237', flag: '🇨🇲', name: 'Cameroon', iso: 'CM'),
  Country(code: '+1', flag: '🇨🇦', name: 'Canada', iso: 'CA'),
  Country(code: '+238', flag: '🇨🇻', name: 'Cape Verde', iso: 'CV'),
  Country(code: '+236', flag: '🇨🇫', name: 'Central African Republic', iso: 'CF'),
  Country(code: '+235', flag: '🇹🇩', name: 'Chad', iso: 'TD'),
  Country(code: '+56', flag: '🇨🇱', name: 'Chile', iso: 'CL'),
  Country(code: '+86', flag: '🇨🇳', name: 'China', iso: 'CN'),
  Country(code: '+57', flag: '🇨🇴', name: 'Colombia', iso: 'CO'),
  Country(code: '+269', flag: '🇰🇲', name: 'Comoros', iso: 'KM'),
  Country(code: '+242', flag: '🇨🇬', name: 'Congo', iso: 'CG'),
  Country(code: '+506', flag: '🇨🇷', name: 'Costa Rica', iso: 'CR'),
  Country(code: '+385', flag: '🇭🇷', name: 'Croatia', iso: 'HR'),
  Country(code: '+53', flag: '🇨🇺', name: 'Cuba', iso: 'CU'),
  Country(code: '+357', flag: '🇨🇾', name: 'Cyprus', iso: 'CY'),
  Country(code: '+420', flag: '🇨🇿', name: 'Czech Republic', iso: 'CZ'),
  Country(code: '+45', flag: '🇩🇰', name: 'Denmark', iso: 'DK'),
  Country(code: '+253', flag: '🇩🇯', name: 'Djibouti', iso: 'DJ'),
  Country(code: '+1809', flag: '🇩🇴', name: 'Dominican Republic', iso: 'DO'),
  Country(code: '+593', flag: '🇪🇨', name: 'Ecuador', iso: 'EC'),
  Country(code: '+20', flag: '🇪🇬', name: 'Egypt', iso: 'EG'),
  Country(code: '+503', flag: '🇸🇻', name: 'El Salvador', iso: 'SV'),
  Country(code: '+240', flag: '🇬🇶', name: 'Equatorial Guinea', iso: 'GQ'),
  Country(code: '+291', flag: '🇪🇷', name: 'Eritrea', iso: 'ER'),
  Country(code: '+372', flag: '🇪🇪', name: 'Estonia', iso: 'EE'),
  Country(code: '+251', flag: '🇪🇹', name: 'Ethiopia', iso: 'ET'),
  Country(code: '+679', flag: '🇫🇯', name: 'Fiji', iso: 'FJ'),
  Country(code: '+358', flag: '🇫🇮', name: 'Finland', iso: 'FI'),
  Country(code: '+33', flag: '🇫🇷', name: 'France', iso: 'FR'),
  Country(code: '+241', flag: '🇬🇦', name: 'Gabon', iso: 'GA'),
  Country(code: '+220', flag: '🇬🇲', name: 'Gambia', iso: 'GM'),
  Country(code: '+995', flag: '🇬🇪', name: 'Georgia', iso: 'GE'),
  Country(code: '+49', flag: '🇩🇪', name: 'Germany', iso: 'DE'),
  Country(code: '+233', flag: '🇬🇭', name: 'Ghana', iso: 'GH'),
  Country(code: '+30', flag: '🇬🇷', name: 'Greece', iso: 'GR'),
  Country(code: '+502', flag: '🇬🇹', name: 'Guatemala', iso: 'GT'),
  Country(code: '+224', flag: '🇬🇳', name: 'Guinea', iso: 'GN'),
  Country(code: '+592', flag: '🇬🇾', name: 'Guyana', iso: 'GY'),
  Country(code: '+509', flag: '🇭🇹', name: 'Haiti', iso: 'HT'),
  Country(code: '+504', flag: '🇭🇳', name: 'Honduras', iso: 'HN'),
  Country(code: '+36', flag: '🇭🇺', name: 'Hungary', iso: 'HU'),
  Country(code: '+354', flag: '🇮🇸', name: 'Iceland', iso: 'IS'),
  Country(code: '+91', flag: '🇮🇳', name: 'India', iso: 'IN'),
  Country(code: '+62', flag: '🇮🇩', name: 'Indonesia', iso: 'ID'),
  Country(code: '+98', flag: '🇮🇷', name: 'Iran', iso: 'IR'),
  Country(code: '+964', flag: '🇮🇶', name: 'Iraq', iso: 'IQ'),
  Country(code: '+353', flag: '🇮🇪', name: 'Ireland', iso: 'IE'),
  Country(code: '+972', flag: '🇮🇱', name: 'Israel', iso: 'IL'),
  Country(code: '+39', flag: '🇮🇹', name: 'Italy', iso: 'IT'),
  Country(code: '+225', flag: '🇨🇮', name: 'Ivory Coast', iso: 'CI'),
  Country(code: '+81', flag: '🇯🇵', name: 'Japan', iso: 'JP'),
  Country(code: '+962', flag: '🇯🇴', name: 'Jordan', iso: 'JO'),
  Country(code: '+7', flag: '🇰🇿', name: 'Kazakhstan', iso: 'KZ'),
  Country(code: '+254', flag: '🇰🇪', name: 'Kenya', iso: 'KE'),
  Country(code: '+686', flag: '🇰🇮', name: 'Kiribati', iso: 'KI'),
  Country(code: '+965', flag: '🇰🇼', name: 'Kuwait', iso: 'KW'),
  Country(code: '+996', flag: '🇰🇬', name: 'Kyrgyzstan', iso: 'KG'),
  Country(code: '+856', flag: '🇱🇦', name: 'Laos', iso: 'LA'),
  Country(code: '+371', flag: '🇱🇻', name: 'Latvia', iso: 'LV'),
  Country(code: '+961', flag: '🇱🇧', name: 'Lebanon', iso: 'LB'),
  Country(code: '+266', flag: '🇱🇸', name: 'Lesotho', iso: 'LS'),
  Country(code: '+231', flag: '🇱🇷', name: 'Liberia', iso: 'LR'),
  Country(code: '+218', flag: '🇱🇾', name: 'Libya', iso: 'LY'),
  Country(code: '+423', flag: '🇱🇮', name: 'Liechtenstein', iso: 'LI'),
  Country(code: '+370', flag: '🇱🇹', name: 'Lithuania', iso: 'LT'),
  Country(code: '+352', flag: '🇱🇺', name: 'Luxembourg', iso: 'LU'),
  Country(code: '+261', flag: '🇲🇬', name: 'Madagascar', iso: 'MG'),
  Country(code: '+265', flag: '🇲🇼', name: 'Malawi', iso: 'MW'),
  Country(code: '+60', flag: '🇲🇾', name: 'Malaysia', iso: 'MY'),
  Country(code: '+960', flag: '🇲🇻', name: 'Maldives', iso: 'MV'),
  Country(code: '+223', flag: '🇲🇱', name: 'Mali', iso: 'ML'),
  Country(code: '+356', flag: '🇲🇹', name: 'Malta', iso: 'MT'),
  Country(code: '+692', flag: '🇲🇭', name: 'Marshall Islands', iso: 'MH'),
  Country(code: '+222', flag: '🇲🇷', name: 'Mauritania', iso: 'MR'),
  Country(code: '+230', flag: '🇲🇺', name: 'Mauritius', iso: 'MU'),
  Country(code: '+52', flag: '🇲🇽', name: 'Mexico', iso: 'MX'),
  Country(code: '+691', flag: '🇫🇲', name: 'Micronesia', iso: 'FM'),
  Country(code: '+373', flag: '🇲🇩', name: 'Moldova', iso: 'MD'),
  Country(code: '+377', flag: '🇲🇨', name: 'Monaco', iso: 'MC'),
  Country(code: '+976', flag: '🇲🇳', name: 'Mongolia', iso: 'MN'),
  Country(code: '+382', flag: '🇲🇪', name: 'Montenegro', iso: 'ME'),
  Country(code: '+212', flag: '🇲🇦', name: 'Morocco', iso: 'MA'),
  Country(code: '+258', flag: '🇲🇿', name: 'Mozambique', iso: 'MZ'),
  Country(code: '+264', flag: '🇳🇦', name: 'Namibia', iso: 'NA'),
  Country(code: '+674', flag: '🇳🇷', name: 'Nauru', iso: 'NR'),
  Country(code: '+977', flag: '🇳🇵', name: 'Nepal', iso: 'NP'),
  Country(code: '+31', flag: '🇳🇱', name: 'Netherlands', iso: 'NL'),
  Country(code: '+64', flag: '🇳🇿', name: 'New Zealand', iso: 'NZ'),
  Country(code: '+505', flag: '🇳🇮', name: 'Nicaragua', iso: 'NI'),
  Country(code: '+227', flag: '🇳🇪', name: 'Niger', iso: 'NE'),
  Country(code: '+234', flag: '🇳🇬', name: 'Nigeria', iso: 'NG'),
  Country(code: '+47', flag: '🇳🇴', name: 'Norway', iso: 'NO'),
  Country(code: '+968', flag: '🇴🇲', name: 'Oman', iso: 'OM'),
  Country(code: '+92', flag: '🇵🇰', name: 'Pakistan', iso: 'PK'),
  Country(code: '+680', flag: '🇵🇼', name: 'Palau', iso: 'PW'),
  Country(code: '+507', flag: '🇵🇦', name: 'Panama', iso: 'PA'),
  Country(code: '+675', flag: '🇵🇬', name: 'Papua New Guinea', iso: 'PG'),
  Country(code: '+595', flag: '🇵🇾', name: 'Paraguay', iso: 'PY'),
  Country(code: '+51', flag: '🇵🇪', name: 'Peru', iso: 'PE'),
  Country(code: '+63', flag: '🇵🇭', name: 'Philippines', iso: 'PH'),
  Country(code: '+48', flag: '🇵🇱', name: 'Poland', iso: 'PL'),
  Country(code: '+351', flag: '🇵🇹', name: 'Portugal', iso: 'PT'),
  Country(code: '+974', flag: '🇶🇦', name: 'Qatar', iso: 'QA'),
  Country(code: '+40', flag: '🇷🇴', name: 'Romania', iso: 'RO'),
  Country(code: '+7', flag: '🇷🇺', name: 'Russia', iso: 'RU'),
  Country(code: '+250', flag: '🇷🇼', name: 'Rwanda', iso: 'RW'),
  Country(code: '+685', flag: '🇼🇸', name: 'Samoa', iso: 'WS'),
  Country(code: '+378', flag: '🇸🇲', name: 'San Marino', iso: 'SM'),
  Country(code: '+966', flag: '🇸🇦', name: 'Saudi Arabia', iso: 'SA'),
  Country(code: '+221', flag: '🇸🇳', name: 'Senegal', iso: 'SN'),
  Country(code: '+381', flag: '🇷🇸', name: 'Serbia', iso: 'RS'),
  Country(code: '+248', flag: '🇸🇨', name: 'Seychelles', iso: 'SC'),
  Country(code: '+232', flag: '🇸🇱', name: 'Sierra Leone', iso: 'SL'),
  Country(code: '+65', flag: '🇸🇬', name: 'Singapore', iso: 'SG'),
  Country(code: '+421', flag: '🇸🇰', name: 'Slovakia', iso: 'SK'),
  Country(code: '+386', flag: '🇸🇮', name: 'Slovenia', iso: 'SI'),
  Country(code: '+677', flag: '🇸🇧', name: 'Solomon Islands', iso: 'SB'),
  Country(code: '+252', flag: '🇸🇴', name: 'Somalia', iso: 'SO'),
  Country(code: '+27', flag: '🇿🇦', name: 'South Africa', iso: 'ZA'),
  Country(code: '+82', flag: '🇰🇷', name: 'South Korea', iso: 'KR'),
  Country(code: '+34', flag: '🇪🇸', name: 'Spain', iso: 'ES'),
  Country(code: '+94', flag: '🇱🇰', name: 'Sri Lanka', iso: 'LK'),
  Country(code: '+249', flag: '🇸🇩', name: 'Sudan', iso: 'SD'),
  Country(code: '+597', flag: '🇸🇷', name: 'Suriname', iso: 'SR'),
  Country(code: '+268', flag: '🇸🇿', name: 'Eswatini', iso: 'SZ'),
  Country(code: '+46', flag: '🇸🇪', name: 'Sweden', iso: 'SE'),
  Country(code: '+41', flag: '🇨🇭', name: 'Switzerland', iso: 'CH'),
  Country(code: '+963', flag: '🇸🇾', name: 'Syria', iso: 'SY'),
  Country(code: '+886', flag: '🇹🇼', name: 'Taiwan', iso: 'TW'),
  Country(code: '+992', flag: '🇹🇯', name: 'Tajikistan', iso: 'TJ'),
  Country(code: '+255', flag: '🇹🇿', name: 'Tanzania', iso: 'TZ'),
  Country(code: '+66', flag: '🇹🇭', name: 'Thailand', iso: 'TH'),
  Country(code: '+228', flag: '🇹🇬', name: 'Togo', iso: 'TG'),
  Country(code: '+676', flag: '🇹🇴', name: 'Tonga', iso: 'TO'),
  Country(code: '+1868', flag: '🇹🇹', name: 'Trinidad', iso: 'TT'),
  Country(code: '+216', flag: '🇹🇳', name: 'Tunisia', iso: 'TN'),
  Country(code: '+90', flag: '🇹🇷', name: 'Turkey', iso: 'TR'),
  Country(code: '+993', flag: '🇹🇲', name: 'Turkmenistan', iso: 'TM'),
  Country(code: '+688', flag: '🇹🇻', name: 'Tuvalu', iso: 'TV'),
  Country(code: '+256', flag: '🇺🇬', name: 'Uganda', iso: 'UG'),
  Country(code: '+380', flag: '🇺🇦', name: 'Ukraine', iso: 'UA'),
  Country(code: '+971', flag: '🇦🇪', name: 'UAE', iso: 'AE'),
  Country(code: '+44', flag: '🇬🇧', name: 'United Kingdom', iso: 'GB'),
  Country(code: '+1', flag: '🇺🇸', name: 'USA', iso: 'US'),
  Country(code: '+598', flag: '🇺🇾', name: 'Uruguay', iso: 'UY'),
  Country(code: '+998', flag: '🇺🇿', name: 'Uzbekistan', iso: 'UZ'),
  Country(code: '+678', flag: '🇻🇺', name: 'Vanuatu', iso: 'VU'),
  Country(code: '+58', flag: '🇻🇪', name: 'Venezuela', iso: 'VE'),
  Country(code: '+84', flag: '🇻🇳', name: 'Vietnam', iso: 'VN'),
  Country(code: '+967', flag: '🇾🇪', name: 'Yemen', iso: 'YE'),
  Country(code: '+260', flag: '🇿🇲', name: 'Zambia', iso: 'ZM'),
  Country(code: '+263', flag: '🇿🇼', name: 'Zimbabwe', iso: 'ZW'),
];

// Helper methods
class CountryHelper {
  static Country? getCountryByCode(String code) {
    try {
      return countries.firstWhere((country) => country.code == code);
    } catch (e) {
      return null;
    }
  }

  static Country? getCountryByIso(String iso) {
    try {
      return countries.firstWhere((country) => country.iso == iso);
    } catch (e) {
      return null;
    }
  }

  static Country? getCountryByName(String name) {
    try {
      return countries.firstWhere((country) => country.name == name);
    } catch (e) {
      return null;
    }
  }

  static List<Country> searchCountries(String query) {
    final lowerQuery = query.toLowerCase();
    return countries.where((country) {
      return country.name.toLowerCase().contains(lowerQuery) ||
          country.iso.toLowerCase().contains(lowerQuery) ||
          country.code.contains(query);
    }).toList();
  }
}
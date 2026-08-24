/// Domain enumerations mirrored from the backend.
///
/// Values are stored as the exact strings the API uses; the UI only ever
/// renders the label.
class LeadStatus {
  static const String newLead = 'NEW';
  static const String contacted = 'CONTACTED';
  static const String qualified = 'QUALIFIED';
  static const String propertySent = 'PROPERTY_SENT';
  static const String siteVisit = 'SITE_VISIT';
  static const String negotiation = 'NEGOTIATION';
  static const String booking = 'BOOKING';
  static const String closed = 'CLOSED';
  static const String lost = 'LOST';
  static const String wrongNumber = 'WRONG_NUMBER';
  static const String duplicate = 'DUPLICATE';
  static const String notInterested = 'NOT_INTERESTED';

  static const List<String> all = <String>[
    newLead,
    contacted,
    qualified,
    propertySent,
    siteVisit,
    negotiation,
    booking,
    closed,
    lost,
    wrongNumber,
    duplicate,
    notInterested,
  ];
}

class LeadPriority {
  static const String hot = 'HOT';
  static const String warm = 'WARM';
  static const String cold = 'COLD';

  static const List<String> all = <String>[hot, warm, cold];
}

class LeadSource {
  static const List<String> all = <String>[
    'META_ADS',
    'WEBSITE',
    'WHATSAPP',
    'GOOGLE',
    'REFERRAL',
    'WALK_IN',
    'MANUAL',
    'OTHER',
  ];
}

class PropertyType {
  static const List<String> all = <String>[
    'APARTMENT',
    'VILLA',
    'TOWNHOUSE',
    'PENTHOUSE',
    'OFFICE',
    'RETAIL',
    'PLOT',
    'WAREHOUSE',
  ];
}

class LeadPurpose {
  static const List<String> all = <String>['BUY', 'RENT', 'INVESTMENT', 'SELL'];
}

class ActivityType {
  static const String leadCreated = 'LEAD_CREATED';
  static const String leadUpdated = 'LEAD_UPDATED';
  static const String statusChanged = 'STATUS_CHANGED';
  static const String assigned = 'ASSIGNED';
  static const String noteAdded = 'NOTE_ADDED';
}

class AppRole {
  static const String superAdmin = 'SUPER_ADMIN';
  static const String admin = 'ADMIN';
  static const String salesManager = 'SALES_MANAGER';
  static const String agent = 'AGENT';
  static const String hr = 'HR';
}

/// Turns MY_ENUM_VALUE into "My Enum Value" for display.
String humanizeEnum(String? value) {
  if (value == null || value.isEmpty) {
    return '-';
  }
  return value
      .split('_')
      .map((String part) => part.isEmpty
          ? part
          : part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

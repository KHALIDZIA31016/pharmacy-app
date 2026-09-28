class AppConstants {
  static const appName = 'Pharmacy Unit';
  static const currency = 'Rs ';

  /// Any account that signs in with one of these emails is routed to the
  /// admin panel. Create the account once in Firebase Console > Authentication.
  static const adminEmails = ['admin@gmail.com'];

  /// Used once to create the admin's Firebase account on first login.
  static const adminBootstrapPassword = 'admin1122';

  static const prefsOnboardingSeen = 'onboarding_seen';
}

class UserRole {
  static const user = 'user';
  static const supplier = 'supplier';
  static const admin = 'admin';
}

class Profession {
  static const doctor = 'doctor';
  static const pharmacist = 'pharmacist';
  static const all = [doctor, pharmacist];
}

class OrderStatus {
  static const placed = 'placed';
  static const confirmed = 'confirmed';
  static const delivered = 'delivered';
  static const cancelled = 'cancelled';
}

class RequestStatus {
  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';
}

class ChangeAction {
  static const add = 'add';
  static const update = 'update';
  static const delete = 'delete';
}

/// Choices offered on the registration form.
class Professional {
  static const doctorSpecialties = [
    'General Physician',
    'Pediatrician',
    'Cardiologist',
    'Dermatologist',
    'Gynecologist',
    'Orthopedic',
    'ENT',
    'Dentist',
    'Surgeon',
    'Other',
  ];
  static const doctorSettings = ['Private clinic', 'Hospital', 'Both'];

  static const pharmacistQualifications = [
    'Pharm-D',
    'B.Pharm',
    'D.Pharm',
    'Other',
  ];
  static const pharmacySettings = ['Retail', 'Hospital', 'Wholesale'];
}

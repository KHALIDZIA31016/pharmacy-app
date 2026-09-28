import '../../core/constants/app_constants.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? profession;
  final String organization;
  final String address;
  final String about;
  final String? photoPath;

  /// Supplier's saved signature image, printed at the end of invoices.
  final String? signaturePath;

  // Professional details (doctor / pharmacist)
  /// Doctor: specialization. Pharmacist: qualification.
  final String specialty;

  /// Doctor: practice setting. Pharmacist: pharmacy type.
  final String practiceType;

  /// Medical council / pharmacy license number.
  final String licenseNo;
  final int? experience; // years

  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = UserRole.user,
    this.profession,
    this.organization = '',
    this.address = '',
    this.about = '',
    this.photoPath,
    this.signaturePath,
    this.specialty = '',
    this.practiceType = '',
    this.licenseNo = '',
    this.experience,
    required this.createdAt,
  });

  bool get isSupplier => role == UserRole.supplier;
  bool get isAdmin => role == UserRole.admin;
  bool get isPharmacist => profession == Profession.pharmacist;

  /// e.g. "Doctor" / "Pharmacist" / "Supplier" / "Admin".
  String get roleLabel {
    if (isSupplier) return 'Supplier';
    if (isAdmin) return 'Admin';
    return isPharmacist ? 'Pharmacist' : 'Doctor';
  }

  // Wording differs between the two professions.
  String get specialtyLabel =>
      isPharmacist ? 'Qualification' : 'Specialization';
  String get licenseLabel =>
      isPharmacist ? 'License no. (DRAP)' : 'Registration no. (PMDC)';
  String get practiceLabel =>
      isPharmacist ? 'Pharmacy type' : 'Practice setting';

  /// Short line for cards, e.g. "Cardiologist · 8 yrs".
  String get credentialLine {
    final parts = [
      if (specialty.isNotEmpty) specialty,
      if (experience != null) '$experience yr${experience == 1 ? '' : 's'}',
    ];
    return parts.join(' · ');
  }

  String get firstName => name.trim().split(' ').first;

  AppUser copyWith({
    String? name,
    String? phone,
    String? profession,
    String? organization,
    String? address,
    String? about,
    String? photoPath,
    bool removePhoto = false,
    String? signaturePath,
    bool removeSignature = false,
  }) => AppUser(
    uid: uid,
    name: name ?? this.name,
    email: email,
    phone: phone ?? this.phone,
    role: role,
    profession: profession ?? this.profession,
    organization: organization ?? this.organization,
    address: address ?? this.address,
    about: about ?? this.about,
    photoPath: removePhoto ? null : (photoPath ?? this.photoPath),
    signaturePath: removeSignature
        ? null
        : (signaturePath ?? this.signaturePath),
    specialty: specialty,
    practiceType: practiceType,
    licenseNo: licenseNo,
    experience: experience,
    createdAt: createdAt,
  );

  Map<String, Object?> toMap() => {
    'uid': uid,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'profession': profession,
    'organization': organization,
    'address': address,
    'about': about,
    'photo_path': photoPath,
    'signature_path': signaturePath,
    'specialty': specialty,
    'practice_type': practiceType,
    'license_no': licenseNo,
    'experience': experience,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory AppUser.fromMap(Map<String, Object?> m) => AppUser(
    uid: m['uid'] as String,
    name: m['name'] as String,
    email: m['email'] as String? ?? '',
    phone: m['phone'] as String? ?? '',
    role: m['role'] as String? ?? UserRole.user,
    profession: m['profession'] as String?,
    organization: m['organization'] as String? ?? '',
    address: m['address'] as String? ?? '',
    about: m['about'] as String? ?? '',
    photoPath: m['photo_path'] as String?,
    signaturePath: m['signature_path'] as String?,
    specialty: m['specialty'] as String? ?? '',
    practiceType: m['practice_type'] as String? ?? '',
    licenseNo: m['license_no'] as String? ?? '',
    experience: m['experience'] as int?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
  );
}

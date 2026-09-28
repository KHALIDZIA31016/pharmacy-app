import '../../core/constants/app_constants.dart';

class SupplyRequest {
  final int? id;
  final String userId;
  final String userName;
  final String name;
  final String details;
  final String status;
  final DateTime createdAt;

  const SupplyRequest({
    this.id,
    required this.userId,
    required this.userName,
    required this.name,
    this.details = '',
    this.status = RequestStatus.pending,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'user_name': userName,
    'name': name,
    'details': details,
    'status': status,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory SupplyRequest.fromMap(Map<String, Object?> m) => SupplyRequest(
    id: m['id'] as int,
    userId: m['user_id'] as String,
    userName: m['user_name'] as String,
    name: m['name'] as String,
    details: m['details'] as String? ?? '',
    status: m['status'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
  );
}

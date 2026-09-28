class AppNotification {
  final int? id;
  final String userId;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'title': title,
    'body': body,
    'is_read': isRead ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory AppNotification.fromMap(Map<String, Object?> m) => AppNotification(
    id: m['id'] as int,
    userId: m['user_id'] as String,
    title: m['title'] as String,
    body: m['body'] as String,
    isRead: (m['is_read'] as int) == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
  );
}

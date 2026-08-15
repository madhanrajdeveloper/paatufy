enum NotificationType { release, playlist, system }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final String? imageUrl;
  final NotificationType type;
  final String? targetId;
  final String? targetTitle;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    this.imageUrl,
    required this.type,
    this.targetId,
    this.targetTitle,
    this.isRead = false,
  });
}
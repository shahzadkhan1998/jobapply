import 'package:hive/hive.dart';

part 'email_tracking.g.dart';

@HiveType(typeId: 2)
enum EmailStatus {
  @HiveField(0)
  sent,
  @HiveField(1)
  delivered,
  @HiveField(2)
  read,
  @HiveField(3)
  replied,
  @HiveField(4)
  failed
}

@HiveType(typeId: 3)
class EmailTracking extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String recipient;

  @HiveField(2)
  final String subject;

  @HiveField(3)
  final DateTime sentAt;

  @HiveField(4)
  EmailStatus status;

  @HiveField(5)
  DateTime? repliedAt;

  @HiveField(6)
  String? replyContent;

  EmailTracking({
    required this.id,
    required this.recipient,
    required this.subject,
    required this.sentAt,
    required this.status,
    this.repliedAt,
    this.replyContent,
  });
} 
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/email_tracking.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final String defaultChannelKey = 'email_tracking_channel';
  final String defaultChannelName = 'Email Tracking';
  final String defaultChannelDescription = 'Notifications for email tracking';

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // no icon for now, you can add your app icon later
      [
        NotificationChannel(
          channelKey: defaultChannelKey,
          channelName: defaultChannelName,
          channelDescription: defaultChannelDescription,
          defaultColor: const Color(0xFF9D50DD),
          ledColor: const Color(0xFF9D50DD),
          importance: NotificationImportance.High,
          channelShowBadge: true,
        )
      ],
      debug: true,
    );

    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) async {
      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> setListeners() async {
    // Listen for email responses using ValueListenableBuilder
    final box = await Hive.openBox<EmailTracking>('emailTracking');
    box.listenable().addListener(() {
      _checkForResponses();
    });
  }

  Future<void> _checkForResponses() async {
    final box = await Hive.openBox<EmailTracking>('emailTracking');
    final now = DateTime.now();
    
    for (var tracking in box.values) {
      // Check for responses older than 24 hours
      if (tracking.status == EmailStatus.sent && 
          now.difference(tracking.sentAt).inHours >= 24) {
        // Update status to failed if no response
        tracking.status = EmailStatus.failed;
        await tracking.save();
        
        // Show notification
        await showNotification(
          title: 'No Response Received',
          body: 'Your email to ${tracking.recipient} has not received a response.',
        );
      }
    }
  }

  Future<void> scheduleEmailResponseCheck({
    required String trackingId,
    required String recipient,
  }) async {
    // Schedule a check for 24 hours later
    final box = await Hive.openBox<EmailTracking>('emailTracking');
    final tracking = box.get(trackingId);
    
    if (tracking != null) {
      // Show initial notification
      await showNotification(
        title: 'Email Sent',
        body: 'Your email to $recipient has been sent. We\'ll notify you when you receive a response.',
      );
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: defaultChannelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
        ),
      );
    } catch (e) {
      print('Error showing notification: $e');
      rethrow;
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await AwesomeNotifications().cancel(id);
    } catch (e) {
      print('Error canceling notification: $e');
      rethrow;
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await AwesomeNotifications().cancelAll();
    } catch (e) {
      print('Error canceling all notifications: $e');
      rethrow;
    }
  }
}
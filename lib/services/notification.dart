import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize(GlobalKey<NavigatorState> navKey) async {
    // NotificationSettings settings = await _messaging.requestPermission(
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(initSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'watchdog_alerts',
      'Watchdog Alerty',
      description: 'Powiadomienia o zdarzeniach w systemie Watchdog',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showBannerNotification(message);
    });
  }

  Future<void> _showBannerNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'watchdog_alerts',
            'Watchdog Alerty',
            // channelDescription: 'Powiadomienia o zdarzeniach w systemie Watchdog',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            enableVibration: true,
            playSound: true,
            showWhen: true,
            ticker: notification.title,
            autoCancel: true,
            ongoing: false,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}

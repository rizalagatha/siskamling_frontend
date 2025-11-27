// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Pengaturan untuk Android
    // 'ic_stat_notification' harus sama dengan nama file ikon Anda di folder res/drawable
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_stat_notification');

    // Pengaturan untuk iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Inisialisasi plugin
    await _plugin.initialize(settings);

    // Minta izin notifikasi di Android 13+
    _requestNotificationPermission();
  }

  void _requestNotificationPermission() {
    _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Menampilkan notifikasi sederhana
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'siskamling_channel_1', // ID channel
      'Notifikasi Patroli', // Nama channel
      channelDescription: 'Notifikasi untuk pengingat patroli dan APAR',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentBadge: true),
    );

    await _plugin.show(id, title, body, details);
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../testlogin/test_login_page.dart';

// 全ユーザーに一括で通知を送るためのトピック名。
// サーバー側(Python)もこの名前宛てに送信する。
const String dailyNewsTopic = 'daily_news';

const _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  '通知',
  description: 'ニュース・フレンド申請・いいね・コメントの通知',
  importance: Importance.high,
);

final _localNotifications = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('バックグラウンドで通知を受信: ${message.notification?.title}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('通知許可の状態: ${settings.authorizationStatus}');

    await _messaging.subscribeToTopic(dailyNewsTopic);
    debugPrint('トピック "$dailyNewsTopic" を購読しました');

    await saveTokenForCurrentUser();
    _messaging.onTokenRefresh.listen((_) => saveTokenForCurrentUser());

    // フォアグラウンド受信時は自動で通知バーに出ないため、明示的に表示する
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        'フォアグラウンドで通知を受信: '
        '${message.notification?.title} / ${message.notification?.body}',
      );
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('通知をタップしてアプリを開きました: ${message.notification?.title}');
    });
  }

  /// 現在ログイン中のユーザーのFCMトークンをSupabaseに保存する。
  /// ログイン成功直後や、トークンが更新されたタイミングで呼び出す。
  static Future<void> saveTokenForCurrentUser() async {
    final currentUserId =
        TestSession.currentUserId ??
        Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    try {
      await Supabase.instance.client.from('device_tokens').upsert({
        'user_id': currentUserId,
        'token': token,
      }, onConflict: 'user_id,token');
      debugPrint('FCMトークンを保存しました: $token');
    } catch (e) {
      debugPrint('FCMトークンの保存に失敗しました: $e');
    }
  }
}

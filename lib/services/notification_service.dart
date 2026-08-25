// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';

// // 全ユーザーに一括で通知を送るためのトピック名。
// // サーバー側(Python)もこの名前宛てに送信する。
// const String dailyNewsTopic = 'daily_news';

// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   debugPrint('バックグラウンドで通知を受信: ${message.notification?.title}');
// }

// class NotificationService {
//   static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

//   static Future<void> initialize() async {
//     FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

//     final settings = await _messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     debugPrint('通知許可の状態: ${settings.authorizationStatus}');

//     final token = await _messaging.getToken();
//     debugPrint('FCMトークン: $token');

//     await _messaging.subscribeToTopic(dailyNewsTopic);
//     debugPrint('トピック "$dailyNewsTopic" を購読しました');

//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       debugPrint(
//         'フォアグラウンドで通知を受信: '
//         '${message.notification?.title} / ${message.notification?.body}',
//       );
//     });

//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       debugPrint('通知をタップしてアプリを開きました: ${message.notification?.title}');
//     });
//   }
// }

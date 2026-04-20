import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_globals.dart';

/// Handles all push + in-app notification logic for the FuelDirect driver app.
///
/// Architecture:
///   Flutter → Supabase Edge Function (send-notification)
///             → Google OAuth2 (service account JWT)
///             → FCM HTTP v1 API
///             → Target device
class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  // ── Initialization ──────────────────────────────────────────────────────

  static Future<void> initialize() async {
    // 1. Request permission (Android 13+ / iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[Notif] Permission status: ${settings.authorizationStatus}');

    // 2. Create high-priority Android notification channel
    const channel = AndroidNotificationChannel(
      'order_updates',
      'Order Updates',
      description: 'Fuel delivery order status and chat notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await _localPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Init flutter_local_notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localPlugin.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // 4. Save FCM token and listen for refreshes
    await updateFcmToken();
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[Notif] FCM token refreshed — updating DB');
      updateFcmToken();
    });

    // 5. Foreground messages → show in-app SnackBar + local notification
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. App in background → user tapped notification banner
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 7. App was terminated → user tapped notification to open
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('[Notif] App opened from terminated via notification');
      _handleNotificationTap(initial);
    }

    debugPrint('[Notif] NotificationService initialized ✓');
  }

  // ── FCM Token ───────────────────────────────────────────────────────────

  /// Saves (or refreshes) the FCM token into the `drivers` table.
  /// Uses upsert so it works even if the driver row doesn't exist yet.
  static Future<void> updateFcmToken() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('[Notif] updateFcmToken: no authenticated user — skipping');
        return;
      }

      debugPrint('[Notif] Forcing Firebase to generate a fresh FCM token...');
      try {
        await _messaging.deleteToken();
      } catch (e) {
        debugPrint('[Notif] deleteToken ignored: $e');
      }

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[Notif] updateFcmToken: FCM token is NULL — check Firebase setup');
        return;
      }

      debugPrint('[Notif] FCM token obtained: ${token.substring(0, 20)}...');

      // Use update (driver row already exists from registration flow)
      // upsert would create a new partial row — use update + check affected rows
      final res = await Supabase.instance.client
          .from('drivers')
          .update({'fcm_token': token})
          .eq('id', user.id)
          .select('id');

      if (res.isEmpty) {
        // Driver row not found — try upsert as fallback
        debugPrint('[Notif] Driver row not found for ${user.id} — trying upsert');
        await Supabase.instance.client.from('drivers').upsert(
          {'id': user.id, 'fcm_token': token},
          onConflict: 'id',
        );
      }

      debugPrint('[Notif] FCM token saved to drivers table ✓');
    } catch (e) {
      debugPrint('[Notif] Token update error (non-fatal): $e');
    }
  }

  // ── Core Send via Edge Function ─────────────────────────────────────────

  /// Sends a push notification via the Supabase Edge Function.
  /// Returns true if the notification was sent, false if skipped/failed.
  static Future<bool> _sendNotification({
    required String targetType,
    required String targetId,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    try {
      debugPrint('[Notif] ▶ Calling Edge Function: "$title" → $targetType/$targetId');

      final response = await Supabase.instance.client.functions.invoke(
        'send-notification',
        body: {
          'target_type': targetType,
          'target_id': targetId,
          'title': title,
          'body': body,
          'data': data,
        },
      );

      final responseData = response.data;
      debugPrint('[Notif] ◀ Edge Function response: $responseData');

      if (responseData is Map) {
        if (responseData['success'] == true) {
          if (responseData['skipped'] == true) {
            debugPrint('[Notif] ⚠ Skipped — no FCM token for $targetType $targetId');
            return false;
          }
          debugPrint('[Notif] ✓ Notification sent successfully');
          return true;
        } else if (responseData['error'] != null) {
          debugPrint('[Notif] ✗ Edge function returned error: ${responseData['error']}');
          return false;
        }
      }
      return true;
    } catch (e) {
      // Non-fatal: log but don't crash the app
      debugPrint('[Notif] ✗ Edge function exception (non-fatal): $e');
      return false;
    }
  }

  // ── Driver Notification Bell ────────────────────────────────────────────

  /// Persists a notification row for the current driver
  /// (shown in the in-app Notifications screen / bell).
  static Future<void> saveDriverNotification({
    required String title,
    required String message,
    required String type,
    String? orderId,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final row = <String, dynamic>{
        'driver_id': user.id,
        'title': title,
        'message': message,
        'type': type,
        'is_read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (orderId != null) row['order_id'] = orderId;

      await Supabase.instance.client.from('notifications').insert(row);
      debugPrint('[Notif] Driver notification saved to DB: "$title"');
    } catch (e) {
      debugPrint('[Notif] saveDriverNotification error (non-fatal): $e');
    }
  }

  // ── Convenience Event Methods ───────────────────────────────────────────

  /// Driver accepts an order → notify the customer user.
  static void notifyUserOrderAccepted(String userId, String orderId) {
    debugPrint('[Notif] EVENT: Order Accepted → notifying user $userId');
    // User notification is now handled by SQL Trigger fn_notify_order_status_change
    /*
    unawaited(_sendNotification(
      targetType: 'user',
      targetId: userId,
      title: 'Order Accepted 🚗',
      body: 'A driver has accepted your order and is on the way!',
      data: {'type': 'order_update', 'order_id': orderId},
    ));
    */
    unawaited(saveDriverNotification(
      title: 'Order Accepted',
      message: 'You accepted order #${orderId.substring(0, 4).toUpperCase()}',
      type: 'order',
      orderId: orderId,
    ));
  }

  /// Driver starts delivery → notify the customer user.
  static void notifyUserDeliveryStarted(String userId, String orderId) {
    debugPrint('[Notif] EVENT: Delivery Started → notifying user $userId');
    // User notification is now handled by SQL Trigger
    /*
    unawaited(_sendNotification(
      targetType: 'user',
      targetId: userId,
      title: 'Delivery On The Way 🚛',
      body: 'Your fuel delivery is on its way to you!',
      data: {'type': 'order_update', 'order_id': orderId},
    ));
    */
  }

  /// Driver arrives → notify the customer user.
  static void notifyUserDriverArrived(String userId, String orderId) {
    debugPrint('[Notif] EVENT: Driver Arrived → notifying user $userId');
    // User notification is now handled by SQL Trigger
    /*
    unawaited(_sendNotification(
      targetType: 'user',
      targetId: userId,
      title: 'Driver Arrived 📍',
      body: 'Your driver has arrived at your location!',
      data: {'type': 'order_update', 'order_id': orderId},
    ));
    */
  }

  /// Driver triggers emergency → notify the customer user.
  static void notifyUserEmergency(String userId, String orderId) {
    debugPrint('[Notif] EVENT: Emergency Triggered → notifying user $userId');
    unawaited(_sendNotification(
      targetType: 'user',
      targetId: userId,
      title: 'Emergency Action Required 🚨',
      body: 'Your driver has triggered an emergency alert for your order.',
      data: {'type': 'order_update', 'order_id': orderId},
    ));
  }

  /// Order completed → notify the customer user.
  static void notifyUserOrderCompleted(String userId, String orderId) {
    debugPrint('[Notif] EVENT: Order Completed → notifying user $userId');
    // User notification is now handled by SQL Trigger
    /*
    unawaited(_sendNotification(
      targetType: 'user',
      targetId: userId,
      title: 'Order Completed ✅',
      body: 'Your fuel delivery has been completed. Thank you!',
      data: {'type': 'order_completed', 'order_id': orderId},
    ));
    */
    unawaited(saveDriverNotification(
      title: 'Delivery Completed',
      message:
          'Order #${orderId.substring(0, 4).toUpperCase()} completed successfully',
      type: 'order',
      orderId: orderId,
    ));
  }

  /// New chat message → notify the receiver.
  static void notifyChatMessage({
    required String receiverId,
    required String receiverType,
    required String messageText,
    required String orderId,
  }) {
    debugPrint('[Notif] EVENT: Chat Message → notifying $receiverType $receiverId');
    final preview =
        messageText.length > 60 ? '${messageText.substring(0, 60)}…' : messageText;
    unawaited(_sendNotification(
      targetType: receiverType,
      targetId: receiverId,
      title: 'New Message 💬',
      body: preview,
      data: {
        'type': 'chat',
        'order_id': orderId,
        'receiver_id': receiverId,
      },
    ));
  }

  // ── Foreground / Background Handlers ───────────────────────────────────

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[Notif] Foreground message received: ${message.notification?.title}');
    debugPrint('[Notif]   data: ${message.data}');

    final notification = message.notification;
    if (notification == null) {
      debugPrint('[Notif] ⚠ Foreground message has no notification block — data-only message');
      return;
    }

    // Fallback: Save to DB locally if received in foreground
    final type = message.data['type'] ?? 'system';
    saveDriverNotification(
      title: notification.title ?? 'New Update',
      message: notification.body ?? '',
      type: type,
    );

    // Show local notification (appears in system tray even while app is open)
    _localPlugin.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'order_updates',
          'Order Updates',
          channelDescription:
              'Fuel delivery order status and chat notifications',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFFFF4D00),
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );

    // Show in-app SnackBar banner
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    if (notification.body != null)
                      Text(
                        notification.body!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFF4D00),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      debugPrint('[Notif] ⚠ Cannot show SnackBar — navigatorKey has no context');
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[Notif] Notification tapped: ${message.data}');
    _navigateFromData(message.data);
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('[Notif] Local notification tapped, payload: ${response.payload}');
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _navigateFromData(data);
    } catch (e) {
      debugPrint('[Notif] Failed to parse notification payload: $e');
    }
  }

  // ── Navigation on Tap ───────────────────────────────────────────────────

  static void _navigateFromData(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final orderId = data['order_id']?.toString();
    final receiverId = data['receiver_id']?.toString();

    debugPrint('[Notif] Navigating from notification: type=$type, orderId=$orderId');

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('[Notif] ⚠ Navigator not ready yet — cannot navigate');
      return;
    }

    if (type == 'chat' && orderId != null) {
      navigator.pushNamed(
        '/chat',
        arguments: {
          'orderId': orderId,
          'customerId': receiverId ?? '',
          'customerName': 'Customer',
        },
      );
    } else if (type == 'order_update' || type == 'order_completed') {
      navigator.pushNamed('/assigned-orders');
    }
  }
}

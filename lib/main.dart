import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage_pro/get_storage_pro.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:bubble_burst/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStoragePro.init();
  await MobileAds.instance.initialize();
  await Firebase.initializeApp();

  // Terminated state (App bilkul band ho) mein link handle karne ke liye
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null && message.data['link'] != null) {
      String link = message.data['link'];
      if (link.startsWith('http')) {
        Future.delayed(const Duration(seconds: 1), () async {
          try {
            await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
          } catch (e) {
            debugPrint('Error launching url: $e');
          }
        });
      }
    }
  });

  const AndroidInitializationSettings initializationSettingsAndroid = 
      AndroidInitializationSettings('@mipmap/ic_launcher');
      
  const InitializationSettings initializationSettings = 
      InitializationSettings(android: initializationSettingsAndroid);
  
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null && response.payload!.startsWith('http')) {
        try {
          launchUrl(Uri.parse(response.payload!), mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('Error launching url: $e');
        }
      }
    },
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await _requestConsent();
  await _setupFirebaseMessaging(channel);

  runApp(
    GetMaterialApp(
      title: 'Bubble Shooter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const SplashScreen(),
    ),
  );
}

Future<void> _setupFirebaseMessaging(AndroidNotificationChannel channel) async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true, badge: true, sound: true,
  );

  // App Background mein ho aur click ho
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    String? link = message.data['link'];
    if (link != null && link.startsWith('http')) {
      try {
        await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Error launching url: $e');
      }
    }
  });

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    await FirebaseMessaging.instance.subscribeToTopic('PushNotificationsApi');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      String type = message.data['type'] ?? 'push_notification';
      String? link = message.data['link'];
      String? imageUrl = message.data['image'];
      String title = message.data['title'] ?? message.notification?.title ?? "Notification";
      String body = message.data['body'] ?? message.notification?.body ?? "";

      if (type == 'app_update' && link != null) {
        Get.defaultDialog(
          title: title,
          middleText: body,
          textConfirm: "Update",
          onConfirm: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
        );
      }

      String? localImagePath;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(imageUrl));
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/notif_img.png');
          await file.writeAsBytes(response.bodyBytes);
          localImagePath = file.path;
        } catch (e) {
          debugPrint("Error downloading image: $e");
        }
      }

      flutterLocalNotificationsPlugin.show(
        id: message.notification?.hashCode ?? 0,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: localImagePath != null 
                ? BigPictureStyleInformation(FilePathAndroidBitmap(localImagePath)) 
                : null,
          ),
        ),
        payload: link,
      );
    });
  }
}

Future<void> _requestConsent() async {
  final debugSettings = ConsentDebugSettings(
    debugGeography: DebugGeography.debugGeographyEea,
    testIdentifiers: ["TEST-DEVICE-HASHED-ID"],
  );

  final params = ConsentRequestParameters(consentDebugSettings: debugSettings);

  ConsentInformation.instance.requestConsentInfoUpdate(
    params,
    () {
      ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) async {
        if (error != null) debugPrint("Consent error: ${error.message}");
        await _requestAdsIfAllowed();
      });
    },
    (FormError error) async {
      debugPrint("Consent update failed: ${error.message}");
      await _requestAdsIfAllowed();
    },
  );
}

Future<void> _requestAdsIfAllowed() async {
  if (await ConsentInformation.instance.canRequestAds()) {
    await MobileAds.instance.initialize();
  }
}
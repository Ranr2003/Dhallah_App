import 'package:dhallah_app/screens/chat_list_page.dart';
import 'package:dhallah_app/screens/messages_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 1. أضفنا هذا
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

// استيراد الشاشات
import 'screens/start_page.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/home_page.dart';

// 2. دالة التعامل مع الإشعارات في الخلفية (يجب أن تكون خارج أي كلاس)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("إشعار في الخلفية: ${message.messageId}");

}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ar', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. إعداد معالج الخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 4. طلب إذن الإشعارات للمستخدم
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 5. استماع للإشعارات والتطبيق مفتوح (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print('وصل إشعار والتطبيق مفتوح: ${message.notification!.title}');
        // يمكنك هنا إظهار SnackBar بسيط إذا أردتِ
      }
    });

    return MaterialApp(
      title: 'Dhallah App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB293CD)),
        useMaterial3: true,
        fontFamily: 'Cairo',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const StartPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/chatList': (context) => const ChatListPage(),
        //'/messages': (context) => const MessagesPage(receiverId: '', userName: '', chatRoomId: '',),
      },
    );
  }
}
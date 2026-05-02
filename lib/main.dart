import 'package:dhallah_app/screens/chat_list_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import '../services/notification_serv.dart';

// استيراد الشاشات
import 'screens/start_page.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/home_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ar', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 1. إعداد خدمة الإشعارات
  NotificationService notificationService = NotificationService();

  // 2. طلب الإذن (مرة واحدة فقط)
  await notificationService.requestPermissions();

  // 3. إعداد القنوات للاستقبال والتطبيق مفتوح (Foreground)
  notificationService.setupForegroundNotifications();

  // 4. ✅ إضافة مراقب تحديث التوكن لضمان المزامنة دائماً مع السيرفر
  notificationService.setupTokenListeners();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart'; // 1. أضيفي هذا الاستيراد للغة
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'screens/admin_dashboard.dart';
// استيراد الشاشات
import 'screens/start_page.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 2. تهيئة بيانات اللغة العربية قبل تشغيل التطبيق
  await initializeDateFormatting('ar', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        fontFamily: 'Cairo', // تأكدي من تعريف الخط في pubspec.yaml
      ),

      // 1. تحديد الصفحة التي يبدأ منها التطبيق (البداية)
      initialRoute: '/admin_test',

      // 2. تعريف جدول المسارات
      routes: {
        '/': (context) => const StartPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/admin_test': (context) => AdminDashboard(
          admin: Admin(
            userId: "test_123",
            name: "ليلى",
            email: "admin@dallah.com",
            adminLevel: "Super",
          ),
        ),
      },

    );
  }
}
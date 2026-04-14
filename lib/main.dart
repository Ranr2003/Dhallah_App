import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// استيراد الشاشات
import 'screens/messages_page.dart';
import 'screens/start_page.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/home_page.dart';
import 'screens/chat_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      initialRoute: '/',

      // 2. تعريف جدول المسارات
      routes: {
        '/': (context) => const StartPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/chatList': (context) => const ChatListPage(),
        '/messages': (context) => const MessagesPage(receiverId: '', userName: '', chatRoomId: '',),
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// استيراد ملف صفحة تسجيل الدخول - تأكد أن المسار صحيح حسب مجلداتك
import 'screens/login_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // هذا الجزء هو "الربط" وهو الأهم، لن نلمسه
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
      debugShowCheckedModeBanner: false, // لإخفاء شريط DEBUG المزعج
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // هنا التعديل السحري: استبدلنا MyHomePage بـ LoginPage
      home: const LoginPage(),
    );
  }
}

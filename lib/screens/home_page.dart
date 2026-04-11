import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/item_serv.dart';
import '../services/authentication_serv.dart';
import '../models/report_model.dart';
import '../widgets/login_signup_background.dart';
import 'account_info_page.dart';
import 'login_page.dart';
import 'lost_report_page.dart';
import 'found_report_page.dart';
import '../services/database_serv.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // تهيئة الخدمات
  final ItemService _itemService = ItemService();
  final AuthenticationService _authService = AuthenticationService();

  String userName = "زائر";
  String currentUid = "";

  static const Color dustyPurple = Color(0xFF9681A8);
  static const Color dustyPurpleLight = Color(0xFFDED6E6);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  final DatabaseService _dbService = DatabaseService();
  Future<void> _loadUserData() async {
    // 1. نتأكد من وجود يوزر مسجل دخول
    final user = _authService.getCurrentUser();
    if (user != null) {
      setState(() => currentUid = user.uid);
      RegularUser? userData = await _dbService.getUserById(user.uid);

      if (userData != null && mounted) {
        setState(() {
          // نأخذ الاسم من الموديل مباشرة
          userName = userData.name;
        });
      }
    }
  }

  void _navigateToProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedMethod = prefs.getString('loginMethod');

    // ✅ الصح: نطلب المستخدم من السيرفس وليس من الفايربيس مباشرة
    fb.User? user = _authService.getCurrentUser();

    // نحدد طريقة الدخول (قوقل أو إيميل)
    String finalProvider = savedMethod ??
        (user?.providerData.any((p) => p.providerId == 'password') == true ? 'email' : 'google');

    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(
        userEmail: user?.email ?? user?.phoneNumber ?? "",
        loginProvider: finalProvider,
        canEditPassword: false,
        initialName: userName, // نمرر الاسم اللي جبناه أصلاً من الـ DatabaseService
      )));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildSideMenu(context),
      body: LoginSignupBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 20),
                    _buildTopBar(),
                    const SizedBox(height: 30),
                    Text("مرحباً $userName،", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF5A4A75), fontFamily: 'Cairo')),
                    const Text("!جاهزين نساعدك بأي مفقود", style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500, fontFamily: 'Cairo')),
                    const SizedBox(height: 35),
                    _buildActionHeader(context),
                    const SizedBox(height: 20),
                    Expanded(
                      child: (currentUid.isEmpty)
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFB293CD)))
                          : StreamBuilder<List<Report>>(
                        // الآن الـ Stream ما يفتح إلا والـ ID جاهز
                        stream: _itemService.getMyReportsStream(currentUid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFFB293CD)));
                          }

                          // إذا السناب شوت فيه خطأ (مثلاً مشكلة في الصلاحيات)
                          if (snapshot.hasError) {
                            return Center(child: Text("حدث خطأ في تحميل البيانات", style: TextStyle(fontFamily: 'Cairo')));
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return _buildEmptyState();
                          }

                          final myReports = snapshot.data!;
                          return ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: myReports.length,
                            itemBuilder: (context, index) => _buildDismissibleReport(myReports[index]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildFloatingNavBar(context),
          ],
        ),
      ),
    );
  }

  // --- دوال بناء الواجهة (نفس ستايلك القديم تماماً) ---

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(icon: const Icon(Icons.notifications_none_rounded, size: 30, color: Color(0xFF5A4A75)), onPressed: () {}),
        Image.asset('resourses/DallahAppLogo2.png', height: 45, errorBuilder: (context, error, stackTrace) => const Icon(Icons.apps)),
        IconButton(icon: const Icon(Icons.menu_rounded, size: 30, color: Color(0xFF5A4A75)), onPressed: () => _scaffoldKey.currentState?.openEndDrawer()),
      ],
    );
  }

  Widget _buildActionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          decoration: BoxDecoration(color: const Color(0xFFB293CD).withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
          child: TextButton.icon(
            onPressed: () => _openReportSheet(context),
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF5A4A75)),
            label: const Text("بلاغ جديد", style: TextStyle(color: Color(0xFF5A4A75), fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          ),
        ),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("متابعة البلاغات", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333), fontFamily: 'Cairo')),
            Text("تحديث مباشر من السيرفر", style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo')),
          ],
        ),
      ],
    );
  }

  Widget _buildDismissibleReport(Report report) {
    return Dismissible(
      key: Key(report.reportId ?? ""),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _showDeleteConfirmation(context),
      onDismissed: (direction) => _itemService.deleteReport(report.reportId!, report.item.imageURL),
      background: Container(
        alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
      ),
      child: InkWell(
        onTap: () => _showReportDetails(context, report),
        child: _buildReportCard(
          report.item.category,
          report.item.description,
          report.type == 'lost' ? "بلاغ مفقود" : "بلاغ معثور",
          report.item.color,
          report.type == 'lost' ? Icons.location_on_outlined : Icons.check_circle_outline,
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String subtitle, String status, String colorInfo, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFD2B4EC).withOpacity(0.2))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(status, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFB293CD), fontFamily: 'Cairo')),
            Text(colorInfo, style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'Cairo')),
          ]),
          Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333), fontFamily: 'Cairo'), overflow: TextOverflow.ellipsis),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo'), overflow: TextOverflow.ellipsis),
            ])),
            const SizedBox(width: 12),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFB293CD).withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 22, color: const Color(0xFF5A4A75))),
          ])),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context) {
    return Positioned(
      left: 25, right: 25, bottom: 25,
      child: Container(
        height: 65, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: const Color(0xFFD2B4EC).withOpacity(0.3), blurRadius: 20)]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFB293CD), size: 26),
            Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFB293CD).withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.home_rounded, color: Color(0xFF5A4A75), size: 26)),
            InkWell(onTap: _navigateToProfile, child: const Icon(Icons.person_outline_rounded, color: Color(0xFFB293CD), size: 28)),
          ],
        ),
      ),
    );
  }

  Widget _buildSideMenu(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // الهيدر: يعرض شعار التطبيق واسم المستخدم
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            color: dustyPurple.withOpacity(0.05),
            child: Column(
              children: [
                const Icon(Icons.blur_on_rounded, color: dustyPurple, size: 60),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF5A4A75)),
                ),
              ],
            ),
          ),

          // قائمة الخيارات
          _buildMenuTile(Icons.support_agent, "الدعم الفني", () => Navigator.pop(context)),
          _buildMenuTile(Icons.privacy_tip_outlined, "سياسة الخصوصية", () => Navigator.pop(context)),

          const Spacer(), // لدفع زر تسجيل الخروج للأسفل
          const Divider(indent: 20, endIndent: 20),

          // زر تسجيل الخروج (مربوط بالسيرفس)
          _buildMenuTile(
            Icons.logout,
            "تسجيل الخروج",
                () async {
              await _authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false
                );
              }
            },
            color: Colors.redAccent,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

// دالة مساعدة لاختصار الكود وتكرار الأزرار
  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {Color color = dustyPurple}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(fontFamily: 'Cairo', color: color == Colors.redAccent ? color : Colors.black87)),
      onTap: onTap,
    );
  }
  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
      const Text("لا توجد بلاغات حالياً", style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
    ]));
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text("تأكيد الحذف", textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("إلغاء")),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("حذف", style: TextStyle(color: Colors.red))),
      ],
    ));
  }

  void _showReportDetails(BuildContext context, Report report) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // عشان الكلام يترتب لليمين
            children: [
              Center(
                child: Text(
                    report.type == 'lost' ? "تفاصيل المفقود" : "تفاصيل المعثور عليه",
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)
                ),
              ),
              const Divider(),
              _buildDetailRow("الفئة", report.item.category),
              _buildDetailRow("اللون", report.item.color),
              _buildDetailRow("الوصف", report.item.description),

              // --- الإضافة هنا (الموقع بالتفصيل) ---
              _buildDetailRow("الموقع", report.locationName),
              // ------------------------------------

              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                    onPressed: () {
                      // هنا مستقبلاً تربطينها بخوارزمية الذكاء الاصطناعي
                    },
                    child: const Text("عرض التطابق الذكي", style: TextStyle(fontFamily: 'Cairo'))
                ),
              ),
            ],
          ),
        )
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text(value, style: const TextStyle(fontFamily: 'Cairo')),
      Text(" :$label", style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
    ]));
  }

  void _openReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => DefaultTabController(
        length: 2, initialIndex: 1,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: const Column(children: [
            TabBar(indicatorColor: Color(0xFFB293CD), tabs: [Tab(text: "لقيت شي؟"), Tab(text: "ضيعت شي؟")]),
            Expanded(child: TabBarView(children: [FoundReportPage(), LostReportPage()])),
          ]),
        ),
      ),
    );
  }
}
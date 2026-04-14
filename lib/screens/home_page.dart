import 'package:flutter/material.dart';
import '../services/item_serv.dart';
import '../services/authentication_serv.dart';
import '../models/report_model.dart';
import '../widgets/Wavy_Background.dart';
import 'login_page.dart';
import 'lost_report_page.dart';
import 'found_report_page.dart';
import '../services/database_serv.dart';
import '../models/user_model.dart';
import '../widgets/custom_widgets.dart';
import '../utils/app_theme.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildSideMenu(context),
      body: WavyBackground(
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
                    Text("مرحباً $userName،", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontFamily: 'Tajawal')),
                    const Text("!جاهزين نساعدك بأي مفقود", style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontFamily: 'Tajawal')),
                    const SizedBox(height: 35),
                    _buildActionHeader(context),
                    const SizedBox(height: 20),
                    Expanded(
                      child: (currentUid.isEmpty)
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : StreamBuilder<List<Report>>(
                        // الآن الـ Stream ما يفتح إلا والـ ID جاهز
                        stream: _itemService.getMyReportsStream(currentUid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                          }

                          // إذا السناب شوت فيه خطأ (مثلاً مشكلة في الصلاحيات)
                          if (snapshot.hasError) {
                            return Center(child: Text("حدث خطأ في تحميل البيانات", style: TextStyle(fontFamily: 'Tajawal')));
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
            // استدعاء الودجت الموحد الجديد
            // استدعاء الودجت الموحد الجديد في الهوم
            CustomFloatingNavBar(
              currentIndex: 1, // رقم 1 يمثل الهوم
            ),
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
        IconButton(icon: const Icon(Icons.notifications_none_rounded, size: 30, color: AppColors.primaryDark), onPressed: () {}),
        Image.asset('resourses/DallahAppLogo2.png', height: 45, errorBuilder: (context, error, stackTrace) => const Icon(Icons.apps)),
        IconButton(icon: const Icon(Icons.menu_rounded, size: 30, color: AppColors.primaryDark), onPressed: () => _scaffoldKey.currentState?.openEndDrawer()),
      ],
    );
  }

  Widget _buildActionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
          child: TextButton.icon(
            onPressed: () => _openReportSheet(context),
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryDark),
            label: const Text("بلاغ جديد", style: TextStyle(color:AppColors.primaryDark, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
          ),
        ),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("متابعة البلاغات", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontFamily: 'Tajawal')),
            Text("تحديث مباشر من السيرفر", style: TextStyle(fontSize: 11, color:AppColors.textSecondary, fontFamily: 'Tajawal')),
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
        child: const Icon(Icons.delete_outline, color: AppColors.white, size: 30),
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
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color:AppColors.purble.withOpacity(0.2))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(status, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary, fontFamily: 'Tajawal')),
            Text(colorInfo, style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'Tajawal')),
          ]),
          Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color:AppColors.darkgray, fontFamily: 'Tajawal'), overflow: TextOverflow.ellipsis),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Tajawal'), overflow: TextOverflow.ellipsis),
            ])),
            const SizedBox(width: 12),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 22, color: AppColors.darkpurble)),
          ])),
        ],
      ),
    );
  }


  Widget _buildSideMenu(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          // الهيدر: يعرض شعار التطبيق واسم المستخدم
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            color:AppColors.dustyPurple.withOpacity(0.05),
            child: Column(
              children: [
                const Icon(Icons.blur_on_rounded, color: AppColors.dustyPurple, size: 60),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.darkpurble),
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
            color: AppColors.logouticon,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

// دالة مساعدة لاختصار الكود وتكرار الأزرار
  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {Color color = AppColors.dustyPurple}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(fontFamily: 'Tajawal', color: color == Colors.redAccent ? color : Colors.black87)),
      onTap: onTap,
    );
  }
  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
      const Text("لا توجد بلاغات حالياً", style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
    ]));
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text("تأكيد الحذف", textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Tajawal')),
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
                    style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)
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
                    child: const Text("عرض التطابق الذكي", style: TextStyle(fontFamily: 'Tajawal'))
                ),
              ),
            ],
          ),
        )
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text(value, style: const TextStyle(fontFamily: 'Tajawal')),
      Text(" :$label", style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
    ]));
  }

  void _openReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => DefaultTabController(
        length: 2, initialIndex: 1,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: const Column(children: [
            TabBar(indicatorColor: AppColors.primary, tabs: [Tab(text: "لقيت شي؟"), Tab(text: "ضيعت شي؟")]),
            Expanded(child: TabBarView(children: [FoundReportPage(), LostReportPage()])),
          ]),
        ),
      ),
    );
  }
}
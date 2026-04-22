import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Imports (تأكدي من مطابقة المسارات لمجلدات مشروعك)
import '../services/item_serv.dart';
import '../services/authentication_serv.dart';
import '../services/database_serv.dart';
import '../services/notification_serv.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../widgets/Wavy_Background.dart';
import '../widgets/custom_widgets.dart';
import '../utils/app_theme.dart';
import 'login_page.dart';
import 'lost_report_page.dart';
import 'found_report_page.dart';
import 'notifications_page.dart';
import 'matches_page.dart';

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
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  String userName = "زائر";
  String currentUid = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      if (mounted) setState(() => currentUid = user.uid);
      RegularUser? userData = await _dbService.getUserById(user.uid);

      if (userData != null && mounted) {
        setState(() {
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
                    _buildTopBar(), // شريط الأدوات العلوي المحدث
                    const SizedBox(height: 30),
                    Text(
                      "مرحباً $userName،",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const Text(
                      "!جاهزين نساعدك بأي مفقود",
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 35),
                    _buildActionHeader(context),
                    const SizedBox(height: 20),
                    Expanded(
                      child: (currentUid.isEmpty)
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : StreamBuilder<List<Report>>(
                        stream: _itemService.getMyReportsStream(currentUid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                          }
                          if (snapshot.hasError) {
                            return const Center(child: Text("حدث خطأ في تحميل البيانات", style: TextStyle(fontFamily: 'Tajawal')));
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
            const CustomFloatingNavBar(currentIndex: 1),
          ],
        ),
      ),
    );
  }

  // --- شريط الأدوات العلوي (الجرس يسار، اللوجو وسط، المنيو يمين) ---
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // جرس الإشعارات مع النقطة الحمراء التلقائية
        StreamBuilder<List<NotificationModel>>(
          stream: _notificationService.getNotifications(currentUid),
          builder: (context, snapshot) {
            bool hasUnread = false;
            if (snapshot.hasData) {
              hasUnread = snapshot.data!.any((n) => !n.isRead);
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, size: 30, color: AppColors.primaryDark),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationsPage()),
                    );
                  },
                ),
                if (hasUnread)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

        // شعار التطبيق في المنتصف
        Image.asset(
          'resourses/DallahAppLogo2.png',
          height: 45,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.apps),
        ),

        // زر القائمة الجانبية في اليمين
        IconButton(
          icon: const Icon(Icons.menu_rounded, size: 30, color: AppColors.primaryDark),
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
      ],
    );
  }

  Widget _buildActionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextButton.icon(
            onPressed: () => _openReportSheet(context),
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryDark),
            label: const Text(
              "بلاغ جديد",
              style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
            ),
          ),
        ),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("متابعة البلاغات", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontFamily: 'Tajawal')),
            Text("تحديث مباشر من السيرفر", style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Tajawal')),
          ],
        ),
      ],
    );
  }

  Widget _buildSideMenu(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            color: AppColors.dustyPurple.withOpacity(0.05),
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
          _buildMenuTile(Icons.support_agent, "الدعم الفني", () => Navigator.pop(context)),
          _buildMenuTile(Icons.privacy_tip_outlined, "سياسة الخصوصية", () => Navigator.pop(context)),
          const Spacer(),
          const Divider(indent: 20, endIndent: 20),
          _buildMenuTile(
            Icons.logout,
            "تسجيل الخروج",
                () async {
              await _authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
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

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {Color color = AppColors.dustyPurple}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(fontFamily: 'Tajawal', color: color == Colors.redAccent ? color : Colors.black87)),
      onTap: onTap,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
          const Text(
            "لا توجد بلاغات حالياً",
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
          ),
        ],
      ),
    );
  }

  void _openReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DefaultTabController(
        length: 2,
        initialIndex: 1,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: const Column(
            children: [
              TabBar(indicatorColor: AppColors.primary, tabs: [Tab(text: "لقيت شي؟"), Tab(text: "ضيعت شي؟")]),
              Expanded(child: TabBarView(children: [FoundReportPage(), LostReportPage()])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDismissibleReport(Report report) {
    return Dismissible(
      key: Key(report.reportId ?? ''),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) => _showDeleteConfirmation(context),
      onDismissed: (_) {
        _itemService.deleteReport(report.reportId!, report.item.imageURL);
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.purble.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 28),
            trailing: CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 18,
              child: Icon(
                report.type == 'lost' ? Icons.search_rounded : Icons.person_search_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              report.item.category,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: AppDimens.fontXl, fontWeight: FontWeight.bold),
            ),
            subtitle: _buildCompactSubtitle(report),
            children: [_buildExpandedDetails(report)],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSubtitle(Report report) {
    String location = report.locationName.split('—').first.trim();
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          DateFormat('d MMM', 'ar').format(report.createdAt),
          style: const TextStyle(fontSize: AppDimens.fontSm, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.access_time, size: AppDimens.fontSm, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            location,
            textAlign: TextAlign.right,
            maxLines: 1,
            style: const TextStyle(fontSize: AppDimens.fontSm, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.place_outlined, size: AppDimens.fontSm, color: AppColors.textSecondary),
      ],
    );
  }

  Widget _buildExpandedDetails(Report report) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Divider(height: 20, thickness: 0.5),
          if (report.item.imageURL.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 15),
              constraints: const BoxConstraints(maxHeight: 250),
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.grey[50]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  report.item.imageURL,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.grey);
                  },
                ),
              ),
            ),
          InfoRow(
            text: DateFormat('yyyy/MM/dd   hh:mm a', 'ar').format(report.createdAt),
            icon: Icons.calendar_today_outlined,
            isRtl: true,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          InfoRow(text: report.locationName, icon: Icons.place_outlined, isRtl: true, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          InfoRow(text: report.item.color, icon: Icons.palette_outlined, isRtl: true, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          InfoRow(
            text: " ${report.item.description} - ${report.item.uniqueFeatures}",
            icon: Icons.description_outlined,
            isRtl: true,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 25),
          WaterRippleButton(
            text: 'عرض التطابق الذكي',
            icon: Icons.psychology,
            onTap: () => _onMatchButtonTapped(report),
          ),
        ],
      ),
    );
  }

  void _onMatchButtonTapped(Report report) {
    if (report.ai_status == 'completed') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MatchesPage(matches: report.matches, currentUid: currentUid)),
      );
    } else {
      String message = report.ai_status == 'error' ? 'حدث خطأ في المعالجة' : '... جاري تحليل الصور والنصوص للمطابقة ';
      Color snackColor = report.ai_status == 'error' ? Colors.red : Colors.orange;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Tajawal')),
          backgroundColor: snackColor,
        ),
      );
    }
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف", textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Tajawal')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("إلغاء")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("حذف", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/item_serv.dart';
import '../services/authentication_serv.dart';
import '../services/database_serv.dart';
import '../services/notification_serv.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import '../widgets/Wavy_Background.dart';
import '../widgets/custom_widgets.dart';
import '../utils/app_theme.dart';
import 'login_page.dart';
import 'lost_report_page.dart';
import 'found_report_page.dart';
import 'notifications_page.dart';
import 'matches_page.dart';
import 'dart:async';



class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ItemService _itemService = ItemService();
  final AuthenticationService _authService = AuthenticationService();
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  String userName = "زائر";
  String currentUid = "";


  @override  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      if (mounted) setState(() => currentUid = user.uid);

      // 1. تحديث التوكن لضمان المزامنة (شبكة أمان)
      await _notificationService.saveDeviceToken();

      // 2. تفعيل مستمعات الإشعارات الخاصة بهذا المستخدم
      _monitorReportsForMatches(user.uid);
      _notificationService.setupChatNotifications(user.uid);

      // 3. جلب بيانات الاسم
      RegularUser? userData = await _dbService.getUserById(user.uid);
      if (userData != null && mounted) {
        setState(() => userName = userData.name);
      }
    }
  }



  void _monitorReportsForMatches(String userId) {
    FirebaseFirestore.instance
        .collection('reports')
        .where('userId', isEqualTo: userId)
        .where('ai_status', isEqualTo: 'completed')
        .where('status', isEqualTo: 'open') // ✅ أضيفي هذا السطر هنا
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {

        var reportData = change.doc.data() as Map<String, dynamic>;

        String status = reportData['status'] ?? '';
        String aiStatus = reportData['ai_status'] ?? '';

        // 🚨 أهم شرط يمنع الإشعارات عند الإغلاق
        if (status != 'open') {
          print("🚫 البلاغ مغلق - تم تجاهله: ${change.doc.id}");
          continue;
        }

        if (aiStatus != 'completed') {
          continue;
        }

        List matches = reportData['matches'] ?? [];
        String reportId = change.doc.id;
        String category = reportData['item']['category'] ?? 'عنصر';

        if (matches.isNotEmpty) {
          List<String> matchIds = matches.map((m) {
            if (m is Map) {
              return (m['matched_report_id'] ?? m['reportId'] ?? m['id'] ?? "").toString();
            }
            return m.toString();
          }).where((id) => id.isNotEmpty && id != "null").toList();

          if (matchIds.isNotEmpty) {
            await _notificationService.sendMatchNotification(
              userId: userId,
              reportId: reportId,
              category: category,
              currentMatchIds: matchIds,
            );
          }
        }
      }
    });
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
                    Text("مرحباً $userName،",
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                            fontFamily: 'Tajawal'
                        )
                    ),
                    const Text("!جاهزين نساعدك بأي مفقود",
                        style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Tajawal'
                        )
                    ),
                    const SizedBox(height: 35),
                    _buildActionHeader(context),
                    const SizedBox(height: 20),
                    Expanded(
                      child: (currentUid.isEmpty) ? _buildGuestEmptyState()
                          : StreamBuilder<List<Report>>(
                        stream: _itemService.getUserReportsStream(currentUid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                          if (snapshot.hasError) return const Center(child: Text("حدث خطأ في تحميل البيانات"));
                          if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState();
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

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        currentUid.isNotEmpty ? StreamBuilder<int>(
          stream: _notificationService.getUnreadCount(currentUid),
          builder: (context, snapshot) {
            int unreadCount = snapshot.data ?? 0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded,
                      size: 30,
                      color: AppColors.primaryDark
                  ),
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const NotificationsPage()
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(unreadCount > 9 ? '+9' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        )
        : IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                size: 30,
                color: AppColors.primaryDark
            ),
            onPressed: () => _showGuestWarning(context, message: "سجل دخولك لمشاهدة التنبيهات"),
        ),
        Image.asset('resourses/DallahAppLogo2.png',
            height: 45,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.apps)
        ),
        IconButton(icon: const Icon(Icons.menu_rounded,
            size: 30,
            color: AppColors.primaryDark
            ),
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
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20)
          ),
          child: TextButton.icon(icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.primaryDark
              ),
              label: const Text("بلاغ جديد",
                  style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal'
                  )
              ),
              onPressed: () => currentUid.isEmpty ? _showGuestWarning(context) : _openReportSheet(context),
          ),
        ),
        const Column(crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("متابعة البلاغات",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Tajawal'
                  )
              ),
              Text("تحديث مباشر من السيرفر", style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Tajawal')),
        ]),
      ],
    );
  }


  Widget _buildDismissibleReport(Report report) {
    return Dismissible(
      key: Key(report.reportId ?? ''),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) => _showDeleteConfirmation(context),
      onDismissed: (_) => _itemService.deleteReport(report.reportId!, report.item.imageURL),
      background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(20)
          ),
          child: const Icon(Icons.delete_outline,
              color: Colors.white,
              size: 30
          )
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.purble.withValues(alpha: 0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.primary,
                size: 28
            ),
            trailing: CircleAvatar(
                backgroundColor: AppColors.primary,
                radius: 18,
                child: Icon(report.type == 'lost' ? Icons.search_rounded : Icons.person_search_outlined,
                    color: Colors.white,
                    size: 20
                )
            ),
            title: Text(report.item.category,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                )
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
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text(DateFormat('d MMM', 'ar').format(report.createdAt),
          style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary
          )
      ),
      const SizedBox(width: 4),
      const Icon(Icons.access_time,
          size: 12,
          color: AppColors.textSecondary
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(location,
          textAlign: TextAlign.right,
          maxLines: 1,
          style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary
          )
        )
      ),
      const SizedBox(width: 4),
      const Icon(Icons.place_outlined,
          size: 12,
          color: AppColors.textSecondary
      ),
    ]);
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
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.grey[50]
                ),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(report.item.imageURL,
                        fit: BoxFit.contain
                    )
                )
            ),
          InfoRow(text: DateFormat('yyyy/MM/dd hh:mm a', 'ar').format(report.createdAt),
              icon: Icons.calendar_today_outlined,
              isRtl: true,
              color: AppColors.textSecondary
          ),
          const SizedBox(height: 12),
          InfoRow(text: report.locationName,
              icon: Icons.place_outlined,
              isRtl: true,
              color: AppColors.textSecondary
          ),
          const SizedBox(height: 12),
          InfoRow(text: report.item.color,
              icon: Icons.palette_outlined,
              isRtl: true,
              color: AppColors.textSecondary
          ),
          const SizedBox(height: 12),
          InfoRow(text: "${report.item.description} - ${report.item.uniqueFeatures}",
              icon: Icons.description_outlined,
              isRtl: true, color: AppColors.textSecondary
          ),
          const SizedBox(height: 25),
          _buildAIStatusWidget(report),
        ],
      ),
    );
  }


  Widget _buildAIStatusWidget(Report report) {

    if (report.status == 'closed') {
      return const SizedBox.shrink();
    }

    if (report.ai_status == 'completed' && report.matches.isNotEmpty) {
      return WaterRippleButton(
        text: 'عرض التطابقات',
        icon: Icons.auto_awesome,
        onTap: () => _onMatchButtonTapped(report),
      );
    }

    else if (report.ai_status == 'processing') {
      return WaterRippleButton(
        text: 'جارِ المطابقة... 🔍',
        icon: Icons.hourglass_empty_rounded,
        onTap: () => _onMatchButtonTapped(report),
      );
    }

    else if (report.ai_status == 'pending') {
      return const Center(
        child: Text("لم تتم معالجة البلاغ بعد",
          style: TextStyle(
              fontFamily:
              'Tajawal',
              color: Colors.grey,
              fontSize: 14
          ),
        ),
      );
    }

    else if (report.ai_status == 'completed' && report.matches.isEmpty) {
      return const Center(
        child: Text("لا توجد نتائج مطابقة حالياً، سنخبرك عند العثور على تطابق",
          style: TextStyle(
              fontFamily:
              'Tajawal',
              color: Colors.grey,
              fontSize: 14
          ),
        ),
      );
    }

    else {
      return const SizedBox.shrink();
    }
  }


  void _onMatchButtonTapped(Report report) {
    if (report.ai_status == 'completed' ) {
      if (report.matches.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchesPage(
              matches: report.matches,
              currentUid: currentUid,
              reportId: report.reportId ?? "",
            ),
          ),
        );
      }
    } else if (report.ai_status == 'processing') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("جاري تحليل الصور والنصوص للمطابقة... يرجى الانتظار",
            textAlign: TextAlign.right,
            style: TextStyle(
                fontFamily: 'Tajawal'
            )
         ),
         backgroundColor: Colors.orange,
        ),
      );
    } else if (report.ai_status == 'error') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("حدث خطأ في معالجة البيانات بالسيرفر",
            textAlign: TextAlign.right,
            style: TextStyle(
                fontFamily: 'Tajawal')
        ),
        backgroundColor: Colors.red,
        ),
      );
    }
  }


  Widget _buildGuestEmptyState() {
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_circle_outlined,
                  size: 80,
                  color: Colors.grey[300]
              ),
              const SizedBox(height: 16),
              const Text("سجل دخولك لتتمكن من\nإضافة ومتابعة بلاغاتك",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Tajawal'
                  )
              ),
              const SizedBox(height: 20),
              TextButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false),
                      child: const Text("تسجيل الدخول الآن",
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              fontFamily: 'Tajawal'
                          )
                      )
              ),
            ]
        )
    );
  }


  Widget _buildSideMenu(BuildContext context) {
    bool isGuest = currentUid.isEmpty;
    return Drawer(
        backgroundColor: AppColors.white,
        child: Column(
            children: [
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 60, bottom: 30),
                  color: AppColors.dustyPurple.withValues(alpha:0.05),
                  child: Column(
                      children: [
                        const Icon(Icons.blur_on_rounded,
                            color: AppColors.dustyPurple,
                            size: 60),
                        const SizedBox(height: 12),
                        Text(userName,
                            style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.darkpurble)
                        )
                      ]
                  )
              ),
              _buildMenuTile(Icons.support_agent,
                  "الدعم الفني", () => Navigator.pop(context)),
              _buildMenuTile(Icons.privacy_tip_outlined,
                  "سياسة الخصوصية", () => Navigator.pop(context)),
              const Spacer(),
              const Divider(indent: 20, endIndent: 20),
              _buildMenuTile(isGuest ? Icons.login : Icons.logout, isGuest ? "تسجيل الدخول" : "تسجيل الخروج", () async {
                if (isGuest) {
                  Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()
                      ), (route) => false
                  );
                } else {
                  await _authService.logout();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                  );
                }
              }, color: isGuest ? AppColors.primary : AppColors.logouticon
              ),
              const SizedBox(height: 20),
            ]
        )
    );
  }


  void _showGuestWarning(BuildContext context, {String message = "هذه الميزة متاحة للأعضاء فقط، سجل دخولك الآن!"}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(15)),
            child: Row(
                children: [
                  const Icon(Icons.lock_outline,
                      color: Colors.white
                  ),
                  const SizedBox(width: 12),
                  Expanded(child:
                    Text(message,
                      textAlign:
                      TextAlign.right,
                      style: const TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.white
                      )
                   )
                  )
                ]
            )
        )
    )
    );
  }


  Widget _buildMenuTile(IconData icon,
      String title,
      VoidCallback onTap,
      {Color color = AppColors.dustyPurple}
      ){
         return ListTile(leading:
         Icon(icon,
             color: color
         ), title:
         Text(title,
             style: TextStyle(
                 fontFamily: 'Tajawal',
                 color: color == AppColors.logouticon || color == AppColors.primary ? color : Colors.black87)), onTap: onTap);
      }


  void _openReportSheet(BuildContext context) {
    showModalBottomSheet(context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DefaultTabController(
            length: 2,
            initialIndex: 1,
            child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30))
                ),
                child: const Column(
                    children: [
                      TabBar(
                          indicatorColor: AppColors.primary,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: Colors.grey,
                          tabs: [Tab(text: "لقيت شي؟"), Tab(text: "ضيعت شي؟")]
                      ),
                      Expanded(
                          child: TabBarView(
                              children: [
                                FoundReportPage(),
                                LostReportPage()
                              ]
                          )
                      )
                    ]
                )
            )
        )
    );
  }


  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text("تأكيد الحذف",
        textAlign: TextAlign.right,
        style: TextStyle(
            fontFamily: 'Tajawal')
        ),
        content: const Text("هل أنت متأكد من رغبتك في حذف هذا البلاغ؟",
            textAlign: TextAlign.right,
            style: TextStyle(
                fontFamily: 'Tajawal')
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("إلغاء")), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("حذف", style: TextStyle(color: Colors.red)))]));
  }


  Widget _buildEmptyState() {
    return Center(child:
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 80,
              color: Colors.grey.withValues(alpha:0.5)
          ),
          const Text("لا توجد بلاغات حالياً",
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal')
          )
        ]
     )
    );
  }
}
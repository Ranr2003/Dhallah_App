import 'package:flutter/material.dart';
import '../services/admin_serv.dart';
import '../services/item_serv.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';

class AdminDashboard extends StatefulWidget {
  final Admin admin;
  const AdminDashboard({super.key, required this.admin});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();
  final ItemService _itemService = ItemService();
  static const Color dustyPurple = Color(0xFF9681A8);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(130),
          child: AppBar(
            elevation: 0,
            backgroundColor: dustyPurple,
            leading: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              onPressed: () => _showLogoutDialog(context),
            ),
            title: Column(
              children: [
                const Text(
                  "لوحة التحكم",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "أهلاً بكِ، ${widget.admin.name} ✨",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            centerTitle: true,
            bottom: const TabBar(
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              tabs: [
                Tab(icon: Icon(Icons.people_outline_rounded), text: "المستخدمين"),
                Tab(icon: Icon(Icons.analytics_outlined), text: "البلاغات"),
              ],
            ),
          ),
        ),
        // --- هذا هو الجزء الناقص الذي سيعيد البيانات للظهور ---
        body: TabBarView(
          children: [
            _buildUsersTab(),    // الصفحة الأولى: المستخدمين
            _buildReportsTab(),  // الصفحة الثانية: البلاغات
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(child: _buildStatsGrid()),

        // --- 1. قائمة المستخدمين النشطين ---
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Text("قائمة الأعضاء", style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        _buildUsersListStream(onlyBanned: false), // نرسل متغير يحدد النوع

        // --- 2. قائمة المحظورين (هذا القسم اللي كان ناقصك) ---
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
            child: Text("قائمة الحظر 🚫", style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
          ),
        ),
        _buildUsersListStream(onlyBanned: true), // نرسل true لعرض المحظورين فقط

        const SliverToBoxAdapter(child: SizedBox(height: 50)),
      ],
    );
  }
  Widget _buildReportsTab() {
    return _buildReportsManagement();
  }

  Widget _buildStatsGrid() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _adminService.getDashboardStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final stats = snapshot.data!;

        return Column(
          children: [
            // الكروت العلوية
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Row(
                children: [
                  _buildStatCardExpanded("المستخدمين", stats['totalUsers'].toString(), Icons.people, Colors.blue),
                  const SizedBox(width: 10),
                  _buildStatCardExpanded("المفقودات", stats['lostReports'].toString(), Icons.search, Colors.orange),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Row(
                children: [
                  _buildStatCardExpanded("المعثورات", stats['foundReports'].toString(), Icons.check_circle, Colors.green),
                  const SizedBox(width: 10),
                  _buildStatCardExpanded("المطابقات", stats['matchedCount'].toString(), Icons.auto_awesome, Colors.purple),
                ],
              ),
            ),

            // قسم الرسومات البيانية الثلاثي
            _buildChartsSection(stats),
          ],
        );
      },
    );
  }

  Widget _buildStatCardExpanded(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
// 1. قسم الرسومات في لوحة التحكم
  Widget _buildChartsSection(Map<String, dynamic> stats) {
    // استخدام الاختصارات الإنجليزية لضمان عدم التداخل ودقة التوزيع
    final List<String> yearMonths = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    List<double> rawData = List<double>.from(stats['monthlyStats'] ?? []);
    List<double> fullYearData = List.generate(12, (index) => index < rawData.length ? rawData[index] : 0.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Text("Annual Activity Analysis",
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. نشاط البلاغات (اليمين)
              Expanded(
                child: _buildChartBox(
                  title: "Report Activity",
                  child: SizedBox(
                    height: 180,
                    child: Column(
                      children: [
                        Expanded(
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: LineChartPainter(data: fullYearData),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // توزيع الاختصارات الإنجليزية بدقة تحت كل نقطة
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: yearMonths.map((m) => Text(
                            m,
                            style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w600, color: Colors.grey),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. حالة البلاغات (اليسار)
              Expanded(
                child: _buildChartBox(
                  title: "Report Status",
                  child: Container(
                    height: 180,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatusProgress("Open", stats['openReports'] ?? 0, stats['totalReports'] ?? 1, Colors.blue),
                        const SizedBox(height: 25),
                        _buildStatusProgress("Completed", stats['completedReports'] ?? 0, stats['totalReports'] ?? 1, Colors.green),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }  Widget _buildChartBox({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF555555))),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }


  // --- بقية الدوال (Users List, Reports Management) كما هي في كودك الأصلي ---
  Widget _buildUsersListStream({required bool onlyBanned}) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminService.getUsersWithDataStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));

        final allUsers = snapshot.data!;
        // الفلترة: إذا طلبنا المحظورين نأخذ isBanned == true، وإذا لا نأخذ الباقي
        final filteredUsers = allUsers.where((u) => (u['isBanned'] == true) == onlyBanned).toList();

        if (filteredUsers.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Text(
                onlyBanned ? "لا يوجد مستخدمين محظورين" : "لا يوجد أعضاء نشطين",
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 12),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final user = filteredUsers[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: onlyBanned ? Colors.red.withOpacity(0.02) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: onlyBanned ? Border.all(color: Colors.red.withOpacity(0.1)) : null,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: onlyBanned ? Colors.red.withOpacity(0.1) : dustyPurple.withOpacity(0.1),
                    child: Text(user['name']?[0] ?? "?", style: TextStyle(color: onlyBanned ? Colors.red : dustyPurple)),
                  ),
                  title: Text(user['name'] ?? "", style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                  subtitle: Text(user['email'] ?? "", style: const TextStyle(fontSize: 11)),
                  trailing: TextButton(
                    onPressed: () => _showBanConfirmation(context, user['userId'], user['name'] ?? "", onlyBanned),
                    child: Text(
                      onlyBanned ? "فك الحظر" : "حظر",
                      style: TextStyle(color: onlyBanned ? Colors.green : Colors.red, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
            childCount: filteredUsers.length,
          ),
        );
      },
    );
  }  Widget _buildReportsManagement() {
    return StreamBuilder<List<Report>>(
      stream: _itemService.getAllReportsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final reports = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                // عند الضغط على أي مكان في الكرت تظهر التفاصيل
                onTap: () => _showReportDetails(context, report),
                leading: CircleAvatar(
                  backgroundColor: report.type == 'lost' ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  child: Icon(
                    report.type == 'lost' ? Icons.search : Icons.check_circle_outline,
                    color: report.type == 'lost' ? Colors.orange : Colors.green,
                    size: 20,
                  ),
                ),
                title: Text(
                  report.item.category,
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "الموقع: ${report.locationName}",
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }
  void _showBanConfirmation(BuildContext context, String userId, String userName, bool isBanned) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(isBanned ? "فك الحظر" : "حظر مستخدم", style: const TextStyle(fontFamily: 'Cairo')),
          content: Text("هل أنتِ متأكدة من ${isBanned ? 'فك حظر' : 'حظر'} $userName؟", style: const TextStyle(fontFamily: 'Cairo')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء", style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isBanned ? Colors.green : Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(context); // إغلاق النافذة
                await _adminService.toggleUserBan(userId, isBanned);

                // إظهار رسالة النجاح
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isBanned ? 'تم فك الحظر بنجاح' : 'تم حظر المستخدم بنجاح'),
                      backgroundColor: isBanned ? Colors.green : Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(isBanned ? "نعم، فك الحظر" : "نعم، حظر", style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }
  void _showReportDetails(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl, // لضمان الاتجاه العربي من اليمين
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: 400, // تحديد عرض ثابت لمنع النافذة من التمدد الزائد
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. قسم الصورة: تم استخدام BoxFit.cover وتحديد الارتفاع لضمان التمركز والملء
                  if (report.item.imageURL.isNotEmpty)
// 1. قسم الصورة المعدل (بدون زوم - يظهر الصورة كاملة)
                    if (report.item.imageURL.isNotEmpty)
                      Container(
                        width: double.infinity,
                        height: 250,
                        decoration: BoxDecoration(
                          color: Colors.grey[50], // خلفية فاتحة جداً تملأ الفراغات حول الصورة
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.network(
                            report.item.imageURL.trim(),
                            width: double.infinity,
                            height: 250,

                            // التغيير هنا: contain يظهر الصورة كاملة بدون قص (بدون زوم)
                            fit: BoxFit.contain,

                            alignment: Alignment.center, // يضمن بقاء الصورة في منتصف المربع تماماً
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                            },
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            ),
                          ),
                        ),
                      )
                  else
                    Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[50],
                      child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                    ),

                  // 2. قسم البيانات
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              report.item.category,
                              style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18
                              ),
                            ),
                            const Spacer(),
                            _buildBadge(report.type),
                          ],
                        ),
                        const Divider(height: 25, thickness: 0.5),
                        _detailItem("اللون:", report.item.color),
                        _detailItem("الموقع:", report.locationName),
                        _detailItem("الميزات:", report.item.uniqueFeatures),
                        _detailItem("الوصف:", report.item.description),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إغلاق", style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                // 1. نقبض على الـ Messenger قبل إغلاق النافذة
                final messenger = ScaffoldMessenger.of(context);

                // 2. إغلاق الـ Dialog
                Navigator.pop(context);

                try {
                  // 3. تنفيذ الحذف في الخلفية
                  await _adminService.deleteReport(report.reportId!);

                  // 4. إظهار الرسالة باستخدام الـ messenger الذي حفظناه
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text(
                        'تم حذف البلاغ بنجاح ✨',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(20),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('حدث خطأ أثناء الحذف'), backgroundColor: Colors.red),
                  );
                }
              },
              icon: const Icon(Icons.delete, size: 16, color: Colors.white),
              label: const Text("حذف البلاغ", style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }  Widget _buildBadge(String type) {
    bool isLost = type == 'lost';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLost ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isLost ? "مفقود" : "معثور",
        style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: isLost ? Colors.orange : Colors.green, fontWeight: FontWeight.bold),
      ),
    );
  }// ويدجت صغير لتنسيق أسطر التفاصيل
  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label ", style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: dustyPurple)),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
          ),
        ],
      ),
    );
  }
  Widget _buildStatusProgress(String label, int count, int total, Color color) {
    double percentage = total == 0 ? 0 : (count / total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 8, color: Colors.black54)),
            Text(count.toString(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6, // ارتفاع الشريط
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تسجيل الخروج", style: TextStyle(fontFamily: 'Cairo')),
        content: const Text("هل أنت متأكد من رغبتك في تسجيل الخروج؟", style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () {
              // العودة لصفحة تسجيل الدخول وحذف كل الصفحات السابقة من الـ Stack
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text("تسجيل الخروج", style: TextStyle(color: Colors.red, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}

// --- كلاس الرسام (LineChartPainter) كما هو مع تعديل بسيط للمساحة ---
// 2. كلاس الرسام المحدث لتجنب أي خطأ برمجياً
class LineChartPainter extends CustomPainter {
  final List<double> data;
  LineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.length < 2) return; // تأكد من وجود نقطتين على الأقل للرسم

    final paint = Paint()
      ..color = const Color(0xFF9681A8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // الحصول على أعلى قيمة لتحديد مقياس الرسم
    double maxVal = data.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 1;

    final path = Path();
    double stepX = size.width / (data.length - 1); // توزيع النقاط بناءً على عدد البيانات (12)

    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      double x = stepX * i;
      double y = size.height - (data[i] / maxVal * size.height * 0.8);
      points.add(Offset(x, y));
    }

    // رسم المنحنى
    path.moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      var cp1 = Offset(points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 2, points[i - 1].dy);
      var cp2 = Offset(points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 2, points[i].dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);

    // رسم الدوائر الصغيرة عند كل شهر
    for (var point in points) {
      canvas.drawCircle(point, 2.5, Paint()..color = const Color(0xFF9681A8));
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) => oldDelegate.data != data;
}
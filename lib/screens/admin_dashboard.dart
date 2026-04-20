import 'package:dhallah_app/utils/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.fieldBg,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(130),
          child: AppBar(
            elevation: 0,
            // تم استبدال dustyPurple بـ primary من الثيم
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.white),
              onPressed: () => _showLogoutDialog(context),
            ),
            title: Column(
              children: [
                const Text(
                  "لوحة التحكم",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w900,
                    fontSize: AppDimens.fontAppBar + 4,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "✨أهلاً بكِ، ${widget.admin.name}",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: AppDimens.fontSm,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            centerTitle: true,
            bottom: const TabBar(
              indicatorColor: AppColors.white,
              indicatorWeight: 3,
              labelStyle: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: AppDimens.fontMd,
              ),
              unselectedLabelColor: AppColors.secondary,
              tabs: [
                Tab(icon: Icon(Icons.people_outline_rounded), text: "المستخدمين"),
                Tab(icon: Icon(Icons.analytics_outlined), text: "البلاغات"),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildUsersTab(),
            _buildReportsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: AppDimens.spaceLg)),
        SliverToBoxAdapter(child: _buildStatsGrid()),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimens.paddingH, vertical: 10),
            child: Text(
                "قائمة الأعضاء",
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: AppDimens.fontXl)
            ),
          ),
        ),
        _buildUsersListStream(onlyBanned: false),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimens.paddingH, vertical: 20),
            child: Text(
                "قائمة الحظر 🚫",
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: AppDimens.fontXl, color: AppColors.error)
            ),
          ),
        ),
        _buildUsersListStream(onlyBanned: true),
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
                  _buildStatCardExpanded("المعثورات", stats['foundReports'].toString(), Icons.check_circle, AppColors.success),
                  const SizedBox(width: 10),
                  _buildStatCardExpanded("المطابقات", stats['matchedCount'].toString(), Icons.auto_awesome, AppColors.primary),
                ],
              ),
            ),
            _buildChartsSection(stats),
          ],
        );
      },
    );
  }

  Widget _buildStatCardExpanded(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimens.spaceMd),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 10)],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: AppDimens.fontXl, fontWeight: FontWeight.bold)),
                Text(title, style: const TextStyle(fontFamily: 'Tajawal', fontSize: AppDimens.fontSm, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(Map<String, dynamic> stats) {
    final List<String> yearMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    List<double> rawData = List<double>.from(stats['monthlyStats'] ?? []);
    List<double> fullYearData = List.generate(12, (index) => index < rawData.length ? rawData[index] : 0.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Text("تحليل النشاط السنوي",
              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: AppDimens.fontLg)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildChartBox(
                  title: "نشاط البلاغات",
                  child: SizedBox(
                    height: 180,
                    child: Column(
                      children: [
                        Expanded(
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: LineChartPainter(data: fullYearData, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: yearMonths.map((m) => Text(
                            m,
                            style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildChartBox(
                  title: "حالة البلاغات",
                  child: Container(
                    height: 180,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatusProgress("مفتوحة", stats['openReports'] ?? 0, stats['totalReports'] ?? 1, Colors.blue),
                        const SizedBox(height: 25),
                        _buildStatusProgress("مكتملة", stats['completedReports'] ?? 0, stats['totalReports'] ?? 1, AppColors.success),
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
  }

  Widget _buildChartBox({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: AppDimens.fontSm, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildUsersListStream({required bool onlyBanned}) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminService.getUsersWithDataStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));

        final allUsers = snapshot.data!;
        final filteredUsers = allUsers.where((u) => (u['isBanned'] == true) == onlyBanned).toList();

        if (filteredUsers.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Text(
                onlyBanned ? "لا يوجد مستخدمين محظورين" : "لا يوجد أعضاء نشطين",
                style: const TextStyle(fontFamily: 'Tajawal', color: AppColors.textHint, fontSize: AppDimens.fontMd),
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
                  color: onlyBanned ? AppColors.error.withOpacity(0.05) : AppColors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  border: onlyBanned ? Border.all(color: AppColors.error.withOpacity(0.1)) : null,
                  boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 4)],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: onlyBanned ? AppColors.error.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                    child: Text(user['name']?[0] ?? "?", style: TextStyle(color: onlyBanned ? AppColors.error : AppColors.primary)),
                  ),
                  title: Text(user['name'] ?? "", style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w600)),
                  subtitle: Text(user['email'] ?? "", style: const TextStyle(fontSize: AppDimens.fontSm, color: AppColors.textSecondary)),
                  trailing: TextButton(
                    onPressed: () => _showBanConfirmation(context, user['userId'], user['name'] ?? "", user['isBanned'] ?? false),
                    child: Text(
                      (user['isBanned'] ?? false) ? "فك الحظر" : "حظر",
                      style: TextStyle(
                          color: (user['isBanned'] ?? false) ? AppColors.success : AppColors.error,
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold
                      ),
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
  }

  Widget _buildReportsManagement() {
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
              elevation: 0,
              color: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                side: BorderSide(color: AppColors.primary.withOpacity(0.1)),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () => _showReportDetails(context, report),
                leading: CircleAvatar(
                  backgroundColor: report.type == 'lost' ? Colors.orange.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                  child: Icon(
                    report.type == 'lost' ? Icons.search : Icons.check_circle_outline,
                    color: report.type == 'lost' ? Colors.orange : AppColors.success,
                    size: 20,
                  ),
                ),
                title: Text(
                  report.item.category,
                  style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "الموقع: ${report.locationName}",
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: AppDimens.fontSm, color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textHint),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMedium)),
          title: Text(isBanned ? "فك الحظر" : "حظر مستخدم", style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          content: Text("هل أنتِ متأكدة من ${isBanned ? 'فك حظر' : 'حظر'} $userName؟", style: const TextStyle(fontFamily: 'Tajawal')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء", style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Tajawal')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isBanned ? AppColors.success : AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSmall)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _adminService.toggleUserBan(userId, isBanned);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isBanned ? 'تم فك الحظر بنجاح' : 'تم حظر المستخدم بنجاح', style: const TextStyle(fontFamily: 'Tajawal')),
                      backgroundColor: isBanned ? AppColors.success : Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(isBanned ? "نعم، فك الحظر" : "نعم، حظر", style: const TextStyle(color: AppColors.white, fontFamily: 'Tajawal')),
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
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusLarge)),
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (report.item.imageURL.isNotEmpty)
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: const BoxDecoration(
                        color: AppColors.fieldBg,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLarge)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLarge)),
                        child: Image.network(
                          report.item.imageURL.trim(),
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                          },
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: AppColors.textHint),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(report.item.category, style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: AppDimens.fontAppBar)),
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
              child: const Text("إغلاق", style: TextStyle(fontFamily: 'Tajawal', color: AppColors.textSecondary)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSmall)),
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                try {
                  await _adminService.deleteReport(report.reportId!);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف البلاغ بنجاح ✨', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الحذف'), backgroundColor: AppColors.error));
                }
              },
              icon: const Icon(Icons.delete, size: 16, color: AppColors.white),
              label: const Text("حذف البلاغ", style: TextStyle(fontFamily: 'Tajawal', color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String type) {
    bool isLost = type == 'lost';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLost ? Colors.orange.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      ),
      child: Text(
        isLost ? "مفقود" : "معثور",
        style: TextStyle(fontFamily: 'Tajawal', fontSize: AppDimens.fontSm, color: isLost ? Colors.orange : AppColors.success, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label ", style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: AppDimens.fontMd, color: AppColors.primaryDark)),
          Expanded(child: Text(value, style: const TextStyle(fontFamily: 'Tajawal', fontSize: AppDimens.fontMd))),
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
            Text(label, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: AppColors.textSecondary)),
            Text(count.toString(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
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
        title: const Text("تسجيل الخروج", style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        content: const Text("هل أنتِ متأكدة من رغبتك في تسجيل الخروج؟", style: TextStyle(fontFamily: 'Tajawal')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء", style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Tajawal')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false),
            child: const Text("تسجيل الخروج", style: TextStyle(color: AppColors.error, fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  LineChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    double maxVal = data.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 1;

    final path = Path();
    double stepX = size.width / (data.length - 1);

    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      double x = stepX * i;
      double y = size.height - (data[i] / maxVal * size.height * 0.8);
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      var cp1 = Offset(points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 2, points[i - 1].dy);
      var cp2 = Offset(points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 2, points[i].dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
    for (var point in points) {
      canvas.drawCircle(point, 2.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) => oldDelegate.data != data;
}
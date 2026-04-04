import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../widgets/login_signup_background.dart';
import 'lost_report_page.dart';
import 'account_info_page.dart';
import 'found_report_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String userName = "زائر";

  // تعريف الألوان كـ static لضمان وصول الدوال إليها بدون أخطاء undefined
  static const Color dustyPurple = Color(0xFF9681A8);
  static const Color dustyPurpleLight = Color(0xFFDED6E6);

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          setState(() {
            userName = userDoc['name'] ?? "مستخدم";
          });
        }
      }
    } catch (e) {
      debugPrint("خطأ في جلب اسم المستخدم: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

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
                    Text("مرحباً $userName،",
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF5A4A75), fontFamily: 'Cairo')),
                    const Text("!جاهزين نساعدك بأي مفقود",
                        style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500, fontFamily: 'Cairo')),
                    const SizedBox(height: 35),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNewReportButton(context),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("متابعة البلاغات", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                            Text("تحديث مباشر من السيرفر", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Expanded(
                      child: StreamBuilder<List<DocumentSnapshot>>(
                        stream: CombineLatestStream.list([
                          FirebaseFirestore.instance
                              .collection('lost_reports')
                              .where('userId', isEqualTo: currentUid)
                              .snapshots()
                              .map((snap) => snap.docs),
                          FirebaseFirestore.instance
                              .collection('found_reports')
                              .where('userId', isEqualTo: currentUid)
                              .snapshots()
                              .map((snap) => snap.docs),
                        ]).map((lists) => lists.expand((x) => x).toList()),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFFB293CD)));
                          }

                          final allReports = snapshot.data ?? [];

                          if (allReports.isEmpty) {
                            return _buildEmptyState();
                          }

                          allReports.sort((a, b) {
                            var dataA = a.data() as Map<String, dynamic>;
                            var dataB = b.data() as Map<String, dynamic>;
                            var dateA = dataA['date'] as Timestamp?;
                            var dateB = dataB['date'] as Timestamp?;
                            return (dateB ?? Timestamp.now()).compareTo(dateA ?? Timestamp.now());
                          });

                          return ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: allReports.length,
                            itemBuilder: (context, index) {
                              var doc = allReports[index];
                              var data = doc.data() as Map<String, dynamic>;
                              bool isLost = doc.reference.parent.id == 'lost_reports';

                              return Dismissible(
                                key: Key(doc.id),
                                direction: DismissDirection.endToStart, // السحب من اليمين لليسار
                                confirmDismiss: (direction) async {
                                  // رسالة تأكيد الحذف
                                  return await _showDeleteConfirmation(context);
                                },
                                onDismissed: (direction) {
                                  // الحذف الفعلي من الداتابيس
                                  doc.reference.delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("تم حذف البلاغ بنجاح", style: TextStyle(fontFamily: 'Cairo'))),
                                  );
                                },
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  margin: const EdgeInsets.only(bottom: 15),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
                                ),
                                child: InkWell(
                                  onTap: () => _showReportDetails(context, data, isLost), // عند الضغط يعرض التفاصيل
                                  child: _buildReportCard(
                                    data['category'] ?? 'غرض',
                                    data['description'] ?? 'لا يوجد وصف',
                                    isLost ? "بلاغ مفقود" : "بلاغ معثور",
                                    data['color'] ?? '',
                                    isLost ? Icons.location_on_outlined : Icons.check_circle_outline,
                                  ),
                                ),
                              );
                            },
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

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, size: 30, color: Color(0xFF5A4A75)),
              onPressed: () {},
            ),
            Positioned(
              right: 12, top: 12,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
              ),
            )
          ],
        ),

        Image.asset('resourses/DallahAppLogo2.png', height: 45,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.apps)),

        IconButton(
          icon: const Icon(Icons.menu_rounded, size: 30, color: Color(0xFF5A4A75)),
          onPressed: () {
            _scaffoldKey.currentState?.openEndDrawer();
          },
        ),
      ],
    );
  }

  Widget _buildSideMenu(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // الهيدر الإبداعي الجديد بالتدرج البنفسجي الباهت
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  dustyPurple.withOpacity(0.2),
                  Colors.white.withOpacity(0.0),
                ],
              ),
            ),
            child: const SafeArea(
              child: Center(
                child: Icon(Icons.blur_on_rounded, color: dustyPurple, size: 50),
              ),
            ),
          ),

          const SizedBox(height: 10),

          _buildDrawerItem(Icons.support_agent_rounded, 'الدعم الفني', dustyPurple, () {
            Navigator.pop(context);
          }),

          _buildDrawerItem(Icons.privacy_tip_outlined, 'سياسة الخصوصية', dustyPurple, () {
            Navigator.pop(context);
          }),

          const Spacer(),
          const Divider(indent: 20, endIndent: 20, color: Color(0xFFEEEEEE)),

          _buildDrawerItem(
            Icons.logout_rounded,
            'تسجيل الخروج',
            Colors.redAccent,
                () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Color itemColor, VoidCallback onTap) {
    return ListTile(
      splashColor: dustyPurpleLight.withOpacity(0.3),
      leading: Icon(icon, color: itemColor, size: 24),
      title: Text(
          title,
          style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w600,
              color: itemColor == Colors.redAccent ? Colors.redAccent : Colors.black87,
              fontSize: 16
          )
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.withOpacity(0.5)),
      onTap: onTap,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 15),
          const Text("لا توجد بلاغات حالياً", style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  Widget _buildNewReportButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFB293CD).withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: TextButton.icon(
        onPressed: () => _showReportOptions(context),
        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF5A4A75), size: 20),
        label: const Text("بلاغ جديد", style: TextStyle(color: Color(0xFF5A4A75), fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
      ),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context) {
    return Positioned(
      left: 25, right: 25, bottom: 25,
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: const Color(0xFFD2B4EC).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFB293CD), size: 26),
            _buildActiveHomeIcon(),
            InkWell(
              onTap: () {
                User? user = FirebaseAuth.instance.currentUser;
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(
                  userEmail: user?.email ?? "",
                  loginProvider: user?.providerData.isNotEmpty == true && user?.providerData.first.providerId == 'password' ? 'email' : 'google',
                  canEditPassword: user?.providerData.isNotEmpty == true && user?.providerData.first.providerId == 'password',
                )));
              },
              child: const Icon(Icons.person_outline_rounded, color: Color(0xFFB293CD), size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveHomeIcon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFB293CD).withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
      child: const Icon(Icons.home_rounded, color: Color(0xFF5A4A75), size: 26),
    );
  }

  Widget _buildReportCard(String title, String subtitle, String status, String colorInfo, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD2B4EC).withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(status, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFB293CD))),
              Text(colorInfo, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)), overflow: TextOverflow.ellipsis, maxLines: 1),
                      Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFB293CD).withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, size: 22, color: const Color(0xFF5A4A75)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReportOptions(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return DefaultTabController(
          length: 2,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 15),
                  // مقبض علوي بسيط
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),

                  const SizedBox(height: 10),

                  // التبويبات (Menu)
                  const TabBar(
                    indicatorColor: Color(0xFFB293CD),
                    indicatorWeight: 3,
                    labelColor: Color(0xFF5A4A75),
                    unselectedLabelColor: Colors.grey,
                    labelStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
                    tabs: [
                      Tab(text: "ضيعت شي؟"),
                      Tab(text: "لقيت شي؟"),
                    ],
                  ),

                  const Divider(height: 1, color: Color(0xFFEEEEEE)),

                  // محتوى التبويبات
                  Flexible(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.75, // طول النافذة
                      child: const TabBarView(
                        children: [
                          LostReportPage(),
                          FoundReportPage(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("تأكيد الحذف", textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: const Text("هل أنت متأكد من رغبتك في حذف هذا البلاغ نهائياً؟", textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("إلغاء", style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("حذف", style: TextStyle(fontFamily: 'Cairo', color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
  void _showReportDetails(BuildContext context, Map<String, dynamic> data, bool isLost) {
    // استخراج بيانات الـ item
    final itemData = data['item'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        contentPadding: const EdgeInsets.all(25),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // خط علوي بسيط للتزيين
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),

            Text(
              isLost ? "تفاصيل المفقود" : "تفاصيل المعثور عليه",
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF5A4A75)),
            ),
            const Divider(height: 30),

            // عرض البيانات بتنسيق (العنوان : القيمة)
            _buildDetailRow("النوع", itemData['category'] ?? "غير محدد"),
            _buildDetailRow("اللون", itemData['color'] ?? "غير محدد"),
            _buildDetailRow("علامات فارقة", itemData['uniqueFeatures'] ?? "لا توجد"),
            _buildDetailRow("الوصف", itemData['description'] ?? "لا يوجد وصف"),

            const SizedBox(height: 30),

            // زر عرض التطابق
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB293CD),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  // هنا يتم الربط مع صفحة نتائج الذكاء الاصطناعي لاحقاً
                },
                child: const Text(
                  "عرض التطابق الذكي",
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ودجت مساعد يعرض (العنوان : القيمة) من اليمين لليسار بشكل موحد
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // القيمة تظهر على اليسار
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 5),
          // العنوان يظهر على اليمين مع النقطتين
          Text(
            "$label :",
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Color(0xFF5A4A75), fontSize: 14),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
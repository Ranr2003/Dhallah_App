import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../services/notification_serv.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService notificationService = NotificationService();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  // @override
  // void initState() {
  //   super.initState();
  //   // الفحص يصير هنا فقط! ليس في الهوم بيج وليس في الـ build
  //   NotificationService().runManualRefresh(currentUserId);
  // }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    final NotificationService notificationService = NotificationService();

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFF),
      appBar: AppBar(
        // 1. جعل النقاط الثلاث على اليسار (إلى الـ Leading)
        leading: IconButton(
          icon: const Icon(Icons.more_vert, color: Color(0xFF5A4A75)),
          onPressed: () => _showOptionsSheet(context, currentUserId),
        ),
        title: const Text(
          "إشعارات",
          style: TextStyle(
            color: Color(0xFF5A4A75),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        // 2. جعل سهم الرجوع على اليمين (إلى الـ Actions)
        actions: [
          IconButton(
            icon: const Icon(
                Icons.arrow_forward_ios, size: 20, color: Color(0xFF5A4A75)),
            // استخدمت arrow_forward لأن الاتجاه يمين
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notificationService.getNotifications(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFB293CD)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("لا توجد إشعارات حالياً"),
            );
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notify = notifications[index];

              // منطق إظهار التاريخ كعنوان فوق الإشعارات
              bool showDateLabel = false;
              if (index == 0) {
                showDateLabel = true;
              } else {
                DateTime currentRecord = notify.createdAt;
                DateTime previousRecord = notifications[index - 1].createdAt;
                if (DateFormat('yyyy/MM/dd').format(currentRecord) !=
                    DateFormat('yyyy/MM/dd').format(previousRecord)) {
                  showDateLabel = true;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showDateLabel) _buildDateLabel(notify.createdAt),
                  // هنا كان التكرار، الآن استدعاء واحد فقط والـ UI سليم
                  _buildNotificationCard(notify, notificationService),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // نافذة الخيارات (تحديد الكل كمقروء)
// نافذة الخيارات (تحديد الكل كمقروء + مسح الكل)
  void _showOptionsSheet(BuildContext context, String userId) {
    final notificationService = NotificationService();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              // الخيار الأول: تحديد الكل كمقروء
              ListTile(
                leading: const Icon(
                    Icons.check_circle_outline, color: Colors.green),
                title: const Text("تحديد الكل كمقروء",
                    style: TextStyle(fontFamily: 'Tajawal')),
                onTap: () async {
                  await notificationService.markAllAsRead(userId);
                  Navigator.pop(context);
                },
              ),

              // الخيار الثاني الجديد: مسح الكل
              ListTile(
                leading: const Icon(
                    Icons.delete_sweep_outlined, color: Colors.redAccent),
                title: const Text("مسح جميع الإشعارات", style: TextStyle(
                    color: Colors.redAccent, fontFamily: 'Tajawal')),
                onTap: () async {
                  // استدعاء الدالة التي أضفناها في السيرفس
                  await notificationService.clearAllNotifications(userId);
                  Navigator.pop(context);

                  // إظهار تأكيد بسيط
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          "تم مسح الإشعارات بنجاح", textAlign: TextAlign.right),
                      backgroundColor: Colors.black87,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateLabel(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      child: Text(
        DateFormat('d/MM/yyyy').format(date),
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notify,
      NotificationService service) {
    return InkWell(
      onTap: () {
        if (!notify.isRead) {
          service.markAsRead(notify.id);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD2B4EC).withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // 1. محتوى الإشعار أصبح على اليسار
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    // محاذاة النص لليمين باتجاه الأيقونة
                    children: [
                      Text(
                        notify.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notify.body,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('hh:mm a').format(notify.createdAt),
                        style: const TextStyle(
                          color: Color(0xFFB293CD),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                // 2. الدائرة البنفسجية أصبحت على اليمين
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF5A4A75), // اللون البنفسجي الجديد
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),

            // النقطة الحمراء (تعديل موقعها ليكون فوق الدائرة البنفسجية)
            if (!notify.isRead)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
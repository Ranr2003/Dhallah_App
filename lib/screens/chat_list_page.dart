import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart'; // تأكدي أن MessageTile موجود هنا
import '../widgets/Wavy_Background.dart';
import 'messages_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. الحصول على الـ UID الخاص بكِ للفلترة
    final String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      body: WavyBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'الرسائل',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A4A75),
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      // جلب الغرف التي تشاركين فيها مرتبة حسب وقت آخر رسالة
                      stream: FirebaseFirestore.instance
                          .collection('chat_rooms')
                          .where('participants', arrayContains: myUid)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: Color(0xFFB293CD)),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              "لا توجد محادثات حالياً",
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          );
                        }

                        final rooms = snapshot.data!.docs;

                        return ListView.builder(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
                          itemCount: rooms.length,
                          itemBuilder: (context, index) {
                            var room = rooms[index].data() as Map<String, dynamic>;
                            String chatRoomId = rooms[index].id;

                            // استخراج بيانات الرسالة الأخيرة
                            String lastMsg = room['lastMessage'] ?? "";
                            String lastSenderId = room['lastSenderId'] ?? "";

                            // تحديد الـ ID والاسم للطرف الآخر ديناميكياً
                            List participants = room['participants'] ?? [];
                            String otherUserId = participants.firstWhere(
                                    (id) => id != myUid,
                                orElse: () => ""
                            );

                            String displayUsername;
                            if (myUid == room['receiverId']) {
                              displayUsername = room['senderName'] ?? "مستخدم";
                            } else {
                              displayUsername = room['receiverName'] ?? "مستخدم";
                            }

                            // معالجة عداد الرسائل (التأكد من أنه رقم صحيح)
                            int unreadCount = 0;
                            if (room['unreadCount'] != null) {
                              unreadCount = (room['unreadCount'] as num).toInt();
                            }

                            // منطق ظهور النقطة البنفسجية
                            // تظهر فقط إذا كان العداد > 0 وأنتِ لستِ من أرسل الرسالة الأخيرة
                            String? countString = (unreadCount > 0 && lastSenderId != myUid)
                                ? unreadCount.toString()
                                : null;

                            return MessageTile(
                              name: displayUsername,
                              message: lastMsg,
                              count: countString,
                              onTap: () async {
                                // 1. تصفير العداد فوراً عند النقر للدخول
                                await FirebaseFirestore.instance
                                    .collection('chat_rooms')
                                    .doc(chatRoomId)
                                    .update({'unreadCount': 0});

                                if (!context.mounted) return;

                                // 2. الانتقال لصفحة المحادثة
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MessagesPage(
                                      userName: displayUsername,
                                      receiverId: otherUserId,
                                      chatRoomId: chatRoomId,
                                      senderId: myUid,
                                      reportId: (myUid == room['senderId'] ? room['senderreportId'] : room['receiverreportId']) ?? "",
                                      receiverReportId: (myUid == room['senderId'] ? room['receiverreportId'] : room['senderreportId']) ?? "",
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // شريط التنقل العائم
            _buildFloatingNavBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context) {
    return Positioned(
      left: 25,
      right: 25,
      bottom: 25,
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD2B4EC).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActiveChatIcon(),
            InkWell(
              onTap: () => Navigator.pushReplacementNamed(context, '/home'),
              child: const Icon(Icons.home_outlined, color: Color(0xFFB293CD), size: 28),
            ),
            const Icon(Icons.person_outline_rounded, color: Color(0xFFB293CD), size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveChatIcon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFB293CD).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.chat_bubble_rounded,
        color: Color(0xFF5A4A75),
        size: 26,
      ),
    );
  }
}
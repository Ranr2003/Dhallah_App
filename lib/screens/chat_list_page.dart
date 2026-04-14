import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/login_signup_background.dart';
import 'account_info_page.dart';
import 'messages_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    // 1. الحصول على الـ UID الخاص بكِ من الفايربيس للفلترة
    final String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      // تغليف الصفحة بالخلفية الموحدة
      body: LoginSignupBackground(
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

                            String lastMsg = room['lastMessage'] ?? "";
                            String senderId = room['senderId'] ?? "";
                            String receiverId = room['receiverId'] ?? "";
                            String senderName = room['senderName'] ?? "مستخدم";
                            String receiverName = room['receiverName'] ?? "مستخدم";
                            String lastSenderId = room['lastSenderId'] ?? "";

                            // منطق تحديد الاسم المراد عرضه
                            String displayUsername;
                            if (myUid == receiverId) {
                              displayUsername = senderName;
                            } else {
                              displayUsername = receiverName;
                            }

                            // معالجة عداد الرسائل غير المقروءة
                            int unreadCount = room['unreadCount'] ?? 0;
                            String? countString = (unreadCount > 0 && lastSenderId != myUid)
                                ? unreadCount.toString()
                                : null;

                            return MessageTile(
                              name: displayUsername,
                              message: lastMsg,
                              count: countString,
                              onTap: () async {
                                // تصفير العداد عند الدخول للمحادثة
                                await FirebaseFirestore.instance
                                    .collection('chat_rooms')
                                    .doc(chatRoomId)
                                    .update({'unreadCount': 0});

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MessagesPage(
                                      userName: displayUsername,
                                      receiverId: (myUid == receiverId) ? senderId : receiverId,
                                      chatRoomId: chatRoomId,
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

            // شريط التنقل العائم (يظهر فوق الـ SafeArea)
            _buildFloatingNavBar(context),
          ],
        ),
      ),
    );
  }

  // دالة بناء شريط التنقل بنفس تصميم الصفحة الرئيسية
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
            // 1. أيقونة الرسائل - أصبحت هي النشطة الآن
            _buildActiveChatIcon(),

            // 2. أيقونة الهوم - أصبحت عادية وتنقلك للرئيسية
            InkWell(
              onTap: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Icon(
                Icons.home_outlined,
                color: Color(0xFFB293CD),
                size: 28,
              ),
            ),

            // 3. أيقونة البروفايل
            InkWell(
              //onTap: _navigateToProfile,
              child: const Icon(
                Icons.person_outline_rounded,
                color: Color(0xFFB293CD),
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

// دالة بناء أيقونة الرسائل النشطة (بنفس ستايل الهوم في الرئيسية)
  Widget _buildActiveChatIcon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFB293CD).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.chat_bubble_rounded, // أيقونة ممتلئة (نشطة)
        color: Color(0xFF5A4A75),   // اللون الغامق
        size: 26,
      ),
    );
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/Wavy_Background.dart';
import '../widgets/custom_widgets.dart';
import 'messages_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                      stream: FirebaseFirestore.instance
                          .collection('chat_rooms')
                          .where('participants', arrayContains: myUid)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFFB293CD)));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text("لا توجد محادثات حالياً", style: TextStyle(fontFamily: 'Cairo')),
                          );
                        }

                        final rooms = snapshot.data!.docs;

                        return ListView.builder(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
                          itemCount: rooms.length,
                          itemBuilder: (context, index) {
                            var room = rooms[index].data() as Map<String, dynamic>;
                            String chatRoomId = rooms[index].id;

                            // --- التعديلات الجديدة في جلب البيانات ---
                            String lastMsg = room['lastMessage'] ?? "";
                            String senderId = room['senderId'] ?? "";
                            String receiverId = room['receiverId'] ?? "";
                            String sName = room['senderName'] ?? "مستخدم";
                            String rName = room['receiverName'] ?? "مستخدم";

                            // تحديد الطرف الآخر والاسم المعروض
                            String displayUsername = (myUid == receiverId) ? sName : rName;
                            String otherUserId = (myUid == receiverId) ? senderId : receiverId;

                            // منطق التنبيهات (الجديد: تصفير العداد عند الدخول)
                            int unreadCount = room['unreadCount'] ?? 0;
                            String? countString = (unreadCount > 0) ? unreadCount.toString() : null;

                            return MessageTile(
                              name: displayUsername,
                              message: lastMsg,
                              count: countString,
                              onTap: () async {
                                // التعديل: تصفير العداد في الفايربيس فور الضغط على المحادثة
                                await FirebaseFirestore.instance
                                    .collection('chat_rooms')
                                    .doc(chatRoomId)
                                    .update({'unreadCount': 0});

                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MessagesPage(
                                        userName: displayUsername,
                                        receiverId: otherUserId,
                                        chatRoomId: chatRoomId,
                                      ),
                                    ),
                                  );
                                }
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
            _buildFloatingNavBar(context),
          ],
        ),
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
          boxShadow: [
            BoxShadow(color: const Color(0xFFD2B4EC).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5)),
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
            const InkWell(
              child: Icon(Icons.person_outline_rounded, color: Color(0xFFB293CD), size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveChatIcon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFB293CD).withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
      child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF5A4A75), size: 26),
    );
  }
}
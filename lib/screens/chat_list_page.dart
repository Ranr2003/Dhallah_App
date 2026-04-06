import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_widgets.dart';
import 'messages_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDFBFF), Color(0xFFF2E7FE)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'الرسائل',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                // --- استبدال القائمة اليدوية بـ StreamBuilder للقراءة من الفايربيس ---
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chat_rooms')
                      .orderBy('timestamp', descending: true) // ترتيب حسب أحدث رسالة
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("لا توجد محادثات حالياً"));
                    }

                    final rooms = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        var room = rooms[index].data() as Map<String, dynamic>;
                        String chatRoomId = rooms[index].id;
                        String lastSenderId = room['lastSenderId'] ?? "";
                        String myId = "02";

                        // استخراج البيانات من الفايربيس
                        String lastMsg = room['lastMessage'] ?? "";
                        String receiverName = room['receiverName'] ?? "مستخدم";
                        String receiverId = room['receiverId'] ?? "";

                        // معالجة العداد (Count)
                        // إذا كان العداد 0 أو غير موجود، نرسل null ليختفي الإشعار
                        int unreadCount = room['unreadCount'] ?? 0;
                        String? countString;
                        if (unreadCount > 0 && lastSenderId != myId) {
                          countString = unreadCount.toString();
                        } else {
                          countString = null; // سيخفي النقطة البنفسجية إذا كنتِ أنتِ من أرسل
                        }

                        return MessageTile(
                          name: receiverName,
                          message: lastMsg,
                          count: countString,
                          onTap: () async {
                            await FirebaseFirestore.instance
                                .collection('chat_rooms')
                                .doc(chatRoomId)
                                .update({'unreadCount': 0});

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MessagesPage(
                                  userName: receiverName,
                                  receiverId: receiverId,
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
              const CustomBottomBar(),
            ],
          ),
        ),
      ),
    );
  }
}
class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Icon(Icons.person_outline, color: AppColors.textHint),
          const Icon(Icons.home_outlined, color: AppColors.textHint),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.fieldBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
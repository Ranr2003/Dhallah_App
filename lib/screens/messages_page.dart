import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_widgets.dart';
import '../services/message_serv.dart';
import 'package:dhallah_app/services/chat_service.dart';

class MessagesPage extends StatefulWidget {
  final String userName;
  final String receiverId;
  final String chatRoomId;

  const MessagesPage({
    super.key,
    required this.userName,
    required this.receiverId,
    required this.chatRoomId
  });

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _messageController = TextEditingController();
  final MessageService _messageService = MessageService();
  final ChatService _chatService = ChatService();

  void _sendChatMessage() async {
    String msg = _messageController.text.trim();
    if (msg.isNotEmpty) {
      await _chatService.sendMessage(widget.receiverId, widget.userName, msg);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFDFBFF), Color(0xFFF2E7FE)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            widget.userName,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
        ),
          body: Column(
            children: [
              const SizedBox(height: 10),
              Center(child: ChatAvatar(imageUrl: 'https://via.placeholder.com/150')),
              const SizedBox(height: 10),
              Text(
                widget.userName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 20),

              // --- هنا يبدأ الربط التلقائي بالفايربيس ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  // نستخدم معرف الغرفة (chatRoomId) لجلب رسائل هذه المحادثة فقط
                  stream: FirebaseFirestore.instance
                      .collection('chat_rooms')
                      .doc(widget.chatRoomId) // تأكدي من تمرير هذا المعرف للصفحة
                      .collection('messages')
                      .orderBy('timestamp', descending: false) // ترتيب زمني تلقائي
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("لا توجد رسائل بعد.. ابدأ الدردشة!"));
                    }

                    final messages = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        var data = messages[index].data() as Map<String, dynamic>;

                        // تحديد هل أنا المرسل أم الطرف الآخر تلقائياً
                        bool isMe = data['senderId'] == "02"; // استبدلي 02 بـ ID المستخدم الحالي الحقيقي

                        // استخراج الوقت التلقائي من الفايربيس وتنسيقه
                        DateTime? date = (data['timestamp'] as Timestamp?)?.toDate();
                        String timeString = date != null ? "${date.hour}:${date.minute}" : "..";

                        return ChatBubble(
                          message: data['messageText'] ?? "",
                          isSender: data['senderId'] == "02",
                          time: timeString, // الوقت الآن يظهر تلقائياً
                        );
                      },
                    );
                  },
                ),
              ),
              // --- نهاية الربط ---

              ChatInputField(
                controller: _messageController,
                onSend: _sendChatMessage, // تأكدي أن هذه الدالة ترسل للفايربيس كما شرحنا سابقاً
              ),
              const SizedBox(height: 10),
              const CustomBottomBar(),
            ],
          )
        ),
    );
  }
} // نهاية كلاس الـ State

// ══════════════════════════════════════════════
// هذا الكلاس يجب أن يكون خارج الكلاس السابق (Top-level)
// ══════════════════════════════════════════════
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
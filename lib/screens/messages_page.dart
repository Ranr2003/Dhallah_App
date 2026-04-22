import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final ChatService _chatService = ChatService();
  final TextEditingController messageController = TextEditingController();

  late String currentUserId;

  @override
  void initState() {
    super.initState();
    print("Current User UID: ${_chatService.currentUserId}");
    currentUserId = _chatService.currentUserId ?? "unknown";
  }

  void sendMessage() async {
    if (messageController.text.trim().isEmpty) return;
    final String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    List<String> ids = [myUid, widget.receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");


    await FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId).set({
      'participants': FieldValue.arrayUnion([myUid, widget.receiverId]),
      'lastMessage': messageController.text,
      'lastSenderId': myUid,
      'timestamp': FieldValue.serverTimestamp(),
      // أزيلي أسطر receiverName و senderName من هنا
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': myUid,
      'message': messageController.text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    messageController.clear();
  }

  @override
  @override
  Widget build(BuildContext context) {
    // 1. الحصول على الـ IDs للطرفين
    final String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    final String otherUserId = widget.receiverId;

    // 2. تكوين الـ ID الموحد (نفس الطريقة المستخدمة في sendMessage)
    // هذا يضمن أن ريم ورسيل يفتحون نفس الغرفة دائماً
    List<String> ids = [myUid, otherUserId];
    ids.sort();
    String unifiedChatRoomId = ids.join("_");

    Widget _buildAppBarTitle() {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users') // نفترض أن معلومات المستخدمين هنا
            .doc(widget.receiverId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            var userData = snapshot.data!.data() as Map<String, dynamic>;
            return Text(
              userData['name'] ?? "مستخدم",
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            );
          }
          // اسم احتياطي من الويجت أثناء التحميل
          return Text(widget.userName, style: const TextStyle(color: AppColors.textPrimary));
        },
      );
    }

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
            onPressed: () => Navigator.pop(context),
          ),
          title: _buildAppBarTitle(),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            // --- تعديل الصورة والاسم تحتها أيضاً ---
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('chat_rooms').doc(unifiedChatRoomId).snapshots(),
              builder: (context, roomSnapshot) {
                String name = widget.userName;
                if (roomSnapshot.hasData && roomSnapshot.data!.exists) {
                  var roomData = roomSnapshot.data!.data() as Map<String, dynamic>;
                  name = (myUid == roomData['receiverId'])
                      ? (roomData['senderName'] ?? "مستخدم")
                      : (roomData['receiverName'] ?? "مستخدم");
                }
                return Column(
                  children: [
                    Center(child: ChatAvatar(imageUrl: 'https://via.placeholder.com/150')),
                    const SizedBox(height: 10),
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // نستخدم unifiedChatRoomId لضمان قراءة الرسائل من الغرفة الصحيحة
                stream: FirebaseFirestore.instance
                    .collection('chat_rooms')
                    .doc(unifiedChatRoomId)
                    .collection('messages')
                    .orderBy('timestamp', descending: false)
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

                      // مقارنة الـ senderId بـ UID المستخدم الحالي
                      bool isMe = data['senderId'] == myUid;

                      // استخراج الوقت بشكل صحيح
                      DateTime? date = (data['timestamp'] as Timestamp?)?.toDate();
                      String timeString = "";
                      if (date != null) {
                        // تنسيق الوقت (ساعة:دقيقة)
                        timeString = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
                      }

                      return ChatBubble(
                        // تأكدي أن الحقل في الفايربيس اسمه 'message' كما في دالة الإرسال
                        message: data['message'] ?? "",
                        isSender: isMe,
                        time: timeString,
                      );
                    },
                  );
                },
              ),
            ),

            ChatInputField(
              // تأكدي أن اسم الكنترولر هنا يطابق المعرف فوق (_messageController)
              controller: messageController,
              onSend: sendMessage,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

}
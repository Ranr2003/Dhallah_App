import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_widgets.dart';
import 'package:dhallah_app/services/chat_service.dart';
import 'package:http/http.dart' as http; // لا تنسي هذا الاستيراد في الأعلى
import 'dart:convert';

class MessagesPage extends StatefulWidget {
  final String userName;
  final String receiverId;
  final String chatRoomId; // سنعتمد هذا الـ ID بشكل أساسي

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
  final String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    _markAsRead(); // تصفير عند الدخول لأول مرة
  }

  void _markAsRead() async {
    try {
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .update({'unreadCount': 0});
      print("✅ تم تصفير العداد بنجاح");
    } catch (e) {
      print("⚠️ تنبيه تصفير العداد: $e");
    }
  }

  void sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    String messageText = messageController.text.trim();
    final String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    try {
      // 1. إرسال الرسالة وتحديث العداد (كودك الحالي)
      await FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId).update({
        'lastMessage': messageText,
        'lastSenderId': myUid,
        'timestamp': FieldValue.serverTimestamp(),
        'unreadCount': FieldValue.increment(1),
      });

      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add({
        'senderId': myUid,
        'receiverId': widget.receiverId,
        'message': messageText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. إرسال الإشعار للطرف الآخر
      _sendPushNotification(widget.receiverId, messageText);

      messageController.clear();
    } catch (e) {
      print("خطأ في الإرسال: $e");
      // ... كود الـ set في حال فشل الـ update
    }
  }

// دالة إرسال الإشعار للطرف الآخر
  Future<void> _sendPushNotification(String receiverId, String msg) async {
    try {
      // جلب توكن الشخص "المستقبل"
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .get();

      if (userDoc.exists) {
        String? receiverToken = userDoc.get('fcmToken');

        if (receiverToken != null) {
          // إرسال الإشعار عبر API الفايربيس
          // ملاحظة: ستحتاجين لـ Server Key من إعدادات الفايربيس (Cloud Messaging)
          final response = await http.post(
            Uri.parse('https://fcm.googleapis.com/fcm/send'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'key=YOUR_SERVER_KEY_HERE', // استبدليه بمفتاحك
            },
            body: jsonEncode(<String, dynamic>{
              'notification': <String, dynamic>{
                'title': 'رسالة جديدة من ${widget.userName}',
                'body': msg,
                'sound': 'default',
              },
              'priority': 'high',
              'to': receiverToken,
            }),
          );
          print('Notification Response: ${response.statusCode}');
        }
      }
    } catch (e) {
      print("خطأ في إرسال الإشعار الفعلي: $e");
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
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.exists) {
                var roomData = snapshot.data!.data() as Map<String, dynamic>;
                int unreadCount = (roomData['unreadCount'] as num? ?? 0).toInt();
                String lastSenderId = roomData['lastSenderId'] ?? "";

                // التصفير الذكي: فقط إذا جاءت رسالة جديدة من الطرف الآخر وأنتِ تشاهدينها
                if (unreadCount > 0 && lastSenderId != myUid) {
                  _markAsRead();
                }
              }
              return Text(
                widget.userName,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
              );
            },
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            // الجزء العلوي (الصورة والاسم)
            Column(
              children: [
                const Center(child: ChatAvatar(imageUrl: 'https://via.placeholder.com/150')),
                const SizedBox(height: 10),
                Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Cairo')),
              ],
            ),
            const SizedBox(height: 20),

            // قائمة الرسائل
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chat_rooms')
                    .doc(widget.chatRoomId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFB293CD)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("ابدأ الدردشة الآن..", style: TextStyle(fontFamily: 'Cairo')));
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true, // لتبدأ القائمة من الأسفل
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var data = messages[index].data() as Map<String, dynamic>;
                      bool isMe = data['senderId'] == myUid;

                      DateTime? date = (data['timestamp'] as Timestamp?)?.toDate();
                      String timeString = date != null ? "${date.hour}:${date.minute.toString().padLeft(2, '0')}" : "";

                      return ChatBubble(
                        message: data['message'] ?? "",
                        isSender: isMe,
                        time: timeString,
                      );
                    },
                  );
                },
              ),
            ),

            // حقل الإدخال
            ChatInputField(
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
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_widgets.dart';

class MessagesPage extends StatefulWidget {
  final String userName;
  final String receiverId;
  final String chatRoomId;

  const MessagesPage({
    super.key,
    required this.userName,
    required this.receiverId,
    required this.chatRoomId,
  });

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController messageController = TextEditingController();
  late String currentUserId;
  StreamSubscription<DocumentSnapshot>? _roomListener;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "unknown";
    _startRoomListener();
  }

  // مستمع لإغلاق الصفحة فوراً إذا قام الطرف الآخر بحذف الغرفة
  void _startRoomListener() {
    _roomListener = FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.chatRoomId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم إنهاء هذه المحادثة")),
        );
      }
    });
  }

  @override
  void dispose() {
    _roomListener?.cancel();
    messageController.dispose();
    super.dispose();
  }

  void sendMessage() async {
    String msgText = messageController.text.trim();
    if (msgText.isEmpty) return;

    final chatRef = FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId);

    // تحديث بيانات الغرفة والعداد
    await chatRef.update({
      'lastMessage': msgText,
      'timestamp': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1),
      'lastSenderId': currentUserId,
    });

    // إضافة الرسالة في الـ sub-collection
    await chatRef.collection('messages').add({
      'senderId': currentUserId,
      'message': msgText,
      'timestamp': FieldValue.serverTimestamp(),
    });

    messageController.clear();
  }

  void _showOptionsMenu() async {
    // جلب بيانات الغرفة لمعرفة الـ reportIds
    DocumentSnapshot roomDoc = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.chatRoomId)
        .get();

    if (!roomDoc.exists) return;
    var roomData = roomDoc.data() as Map<String, dynamic>;

    String? myReportId = (currentUserId == roomData['senderId'])
        ? roomData['senderreportId'] : roomData['receiverreportId'];
    String? otherReportId = (currentUserId == roomData['senderId'])
        ? roomData['receiverreportId'] : roomData['senderreportId'];

    String questionText = "";

    // تحديد نص السؤال بناءً على نوع البلاغ (مفقود/موجود)
    if (myReportId != null && myReportId.isNotEmpty) {
      DocumentSnapshot reportDoc = await FirebaseFirestore.instance.collection('reports').doc(myReportId).get();
      if (reportDoc.exists) {
        String type = reportDoc['type'] ?? '';
        if (type == 'lost') {questionText = "هل وجدت غرضك المفقود؟";}
        else if (type == 'found') {questionText = "هل وجدت صاحب الغرض؟";}
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(questionText, textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5A4A75))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200]),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("ليس بعد", style: TextStyle(color: Colors.black54)))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor:  AppColors.primary),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _terminateConversation(myReportId, otherReportId);
                  },
                  child: const Text("نعم", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ الدالة المسؤولة عن الحذف الكامل وتنظيف الفايربيس
  void _terminateConversation(String? myReportId, String? otherReportId) async {
    try {
      final chatRef = FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId);

      // جلب كافة الرسائل لحذفها (تنظيف الـ Sub-collection)
      var messagesSnapshot = await chatRef.collection('messages').get();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      // إضافة حذف الرسائل للـ Batch
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // إغلاق البلاغات في الفايربيس
      if (myReportId != null) {
        batch.update(FirebaseFirestore.instance.collection('reports').doc(myReportId), {'status': 'closed'});
      }
      if (otherReportId != null) {
        batch.update(FirebaseFirestore.instance.collection('reports').doc(otherReportId), {'status': 'closed'});
      }

      // حذف وثيقة الغرفة نهائياً
      batch.delete(chatRef);

      // تنفيذ العمليات دفعة واحدة
      await batch.commit();

    } catch (e) {
      debugPrint("Error terminating chat: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // التنسيق القديم: خلفية متدرجة
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
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5A4A75)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.userName,
              style: const TextStyle(color: Color(0xFF5A4A75), fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.more_vert, color: Color(0xFF5A4A75)), onPressed: _showOptionsMenu),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            Center(child: ChatAvatar(imageUrl: 'https://via.placeholder.com/150')),
            const SizedBox(height: 10),
            Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF5A4A75))),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chat_rooms')
                    .doc(widget.chatRoomId)
                    .collection('messages')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final messages = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var data = messages[index].data() as Map<String, dynamic>;
                      DateTime? date = (data['timestamp'] as Timestamp?)?.toDate();
                      String time = date != null ? "${date.hour}:${date.minute.toString().padLeft(2, '0')}" : "";

                      return ChatBubble(
                        message: data['message'] ?? "",
                        isSender: data['senderId'] == currentUserId,
                        time: time,
                      );
                    },
                  );
                },
              ),
            ),
            ChatInputField(controller: messageController, onSend: sendMessage),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
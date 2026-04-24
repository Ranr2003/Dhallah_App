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

  // مستمع لإغلاق الصفحة فوراً إذا قام أحد الطرفين بحذف الغرفة
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

    final chatRef = FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.chatRoomId);

    await chatRef.update({
      'lastMessage': msgText,
      'timestamp': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1),
      'lastSenderId': currentUserId,
    });

    await chatRef.collection('messages').add({
      'senderId': currentUserId,
      'message': msgText,
      'timestamp': FieldValue.serverTimestamp(),
    });

    messageController.clear();
  }

  void _showOptionsMenu() async {
    DocumentSnapshot roomDoc = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.chatRoomId)
        .get();

    if (!roomDoc.exists) return;
    var roomData = roomDoc.data() as Map<String, dynamic>;

    String? myReportId = (currentUserId == roomData['senderId'])
        ? roomData['senderreportId']
        : roomData['receiverreportId'];
    String? otherReportId = (currentUserId == roomData['senderId'])
        ? roomData['receiverreportId']
        : roomData['senderreportId'];

    String questionText = "هل تم حل المشكلة؟";

    if (myReportId != null && myReportId.isNotEmpty) {
      DocumentSnapshot reportDoc = await FirebaseFirestore.instance
          .collection('reports')
          .doc(myReportId)
          .get();
      if (reportDoc.exists) {
        String type = reportDoc['type'] ?? '';
        if (type == 'lost') {
          questionText = "هل عثرت على غرضك؟";
        } else if (type == 'found') {
          questionText = "هل وجدت صاحب الغرض؟";
        }
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              questionText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:Color(0xFF5A4A75),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200]),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _terminateConversation(myReportId, otherReportId,
                          shouldCloseStatus: false);
                    },
                    child: const Text("لا",
                        style: TextStyle(color: Colors.black54)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF5A4A75)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showCloseConfirmationDialog(myReportId, otherReportId);
                    },
                    child: const Text("نعم",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // رسالة تنبيهية تأكيدية قبل إغلاق البلاغ وإنهاء المحادثة
  void _showCloseConfirmationDialog(
      String? myReportId, String? otherReportId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        icon: const Icon(
          Icons.check_circle_outline,
          color: Color(0xFF5A4A75),
          size: 52,
        ),
        title: const Text(
          "تأكيد الإغلاق",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF5A4A75),
          ),
        ),
        content: const Text(
          "سيتم إغلاق البلاغ وإنهاء المحادثة نهائياً.\nهل أنت متأكد من المتابعة؟",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 15,
            color: Colors.black54,
            height: 1.6,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              // زر إلغاء
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF5A4A75)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text(
                    "إلغاء",
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Color(0xFF5A4A75),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // زر تأكيد الإغلاق
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A4A75),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    _terminateConversation(myReportId, otherReportId,
                        shouldCloseStatus: true);
                  },
                  child: const Text(
                    "تأكيد",
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // الدالة المسؤولة عن التنفيذ بناءً على قرار المستخدم
  void _terminateConversation(String? myReportId, String? otherReportId,
      {required bool shouldCloseStatus}) async {
    try {
      final chatRef = FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomId);

      // 1. جلب الرسائل لحذفها
      var messagesSnapshot = await chatRef.collection('messages').get();
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 2. إذا اختار "تأكيد" (إغلاق الحالة)
      if (shouldCloseStatus) {
        if (myReportId != null) {
          batch.update(
              FirebaseFirestore.instance
                  .collection('reports')
                  .doc(myReportId),
              {'status': 'closed'});
        }
        if (otherReportId != null) {
          batch.update(
              FirebaseFirestore.instance
                  .collection('reports')
                  .doc(otherReportId),
              {'status': 'closed'});
        }
      }

      // 3. حذف غرفة المحادثة نهائياً (تحدث في الحالتين)
      batch.delete(chatRef);

      await batch.commit();

      // ملاحظة: الـ Listener سيقوم بإخراج المستخدم من الصفحة تلقائياً
    } catch (e) {
      debugPrint("Error terminating chat: $e");
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
            icon:
            const Icon(Icons.arrow_back_ios, color: Color(0xFF5A4A75)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.userName,
              style: const TextStyle(
                  color: Color(0xFF5A4A75),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal')),
          centerTitle: true,
          actions: [
            IconButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFF5A4A75)),
                onPressed: _showOptionsMenu),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            Center(
                child: ChatAvatar(
                    imageUrl: 'https://via.placeholder.com/150')),
            const SizedBox(height: 10),
            Text(widget.userName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF5A4A75))),
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("لا توجد رسائل"));
                  }

                  final messages = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var data =
                      messages[index].data() as Map<String, dynamic>;
                      DateTime? date =
                      (data['timestamp'] as Timestamp?)?.toDate();
                      String time = date != null
                          ? "${date.hour}:${date.minute.toString().padLeft(2, '0')}"
                          : "";

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
            ChatInputField(
                controller: messageController, onSend: sendMessage),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
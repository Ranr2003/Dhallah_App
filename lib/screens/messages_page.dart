import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_widgets.dart';
import '../services/message_serv.dart';
import '../services/database_serv.dart';

class MessagesPage extends StatefulWidget {
  final String userName;
  final String receiverId;
  final String chatRoomId;
  final String senderId;
  final String reportId;
  final String receiverReportId;
  final bool fromMatches; // 🛠️ إضافة المتغير

  const MessagesPage({
    super.key,
    required this.userName,
    required this.receiverId,
    required this.chatRoomId,
    required this.senderId,
    required this.reportId,
    required this.receiverReportId,
    this.fromMatches = false, // 🛠️ افتراضياً false (للقادمين من قائمة الرسائل)
  });

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final MessageService _messageService = MessageService();
  final TextEditingController messageController = TextEditingController();
  final String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";
  StreamSubscription<DocumentSnapshot>? _roomListener;
  String _myName = "مستخدم"; // ✅ أضيفي هذا السطر

  @override
  void initState() {
    super.initState();
    _loadMyName(); // ✅ أضيفي هذا الاستدعاء
    _messageService.markAsRead(widget.chatRoomId);
    _messageService.initializeChatRoom(
      chatRoomId: widget.chatRoomId,
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      reportId: widget.reportId,
      receiverReportId: widget.receiverReportId,
      userName: widget.userName,
    );
    _roomListener = _messageService.startRoomListener(
      chatRoomId: widget.chatRoomId,
      onRoomDeleted: () {
        if (mounted) {
          // 🛠️ منطق العودة المخصص
          if (widget.fromMatches) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          } else {
            Navigator.of(context).pop();
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("تم إنهاء هذه المحادثة")),
          );
        }
      },
    );
  }

  // ✅ أضيفي هذه الدالة
  Future<void> _loadMyName() async {
    final DatabaseService dbService = DatabaseService();
    final userData = await dbService.getUserById(myUid);
    if (userData != null && mounted) {
      setState(() => _myName = userData.name);
    }
  }

  void _sendMessage() async {
    if (messageController.text.trim().isEmpty) return;
    final text = messageController.text.trim();
    messageController.clear();
    try {
      await _messageService.sendMessage(
        chatRoomId: widget.chatRoomId,
        messageText: text,
        receiverId: widget.receiverId,
        senderName: _myName, // ✅ اسم المرسل الحالي وليس widget.userName
      );
    } catch (e) {
      debugPrint("خطأ في الإرسال: $e");
    }
  }

  void _showOptionsMenu() {
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
            const Text("هل عثرت على غرضك؟",
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A4A75))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _terminate(false);
                        },
                        child: const Text("لا"))),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showCloseConfirmationDialog();
                        },
                        child: const Text("نعم"))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCloseConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تأكيد الإغلاق"),
        content: const Text("سيتم إغلاق البلاغ وإنهاء المحادثة نهائياً."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _terminate(true);
              },
              child: const Text("تأكيد")),
        ],
      ),
    );
  }

  void _terminate(bool shouldClose) {
    _messageService.terminateConversation(
      chatRoomId: widget.chatRoomId,
      shouldCloseStatus: shouldClose,
      reportId: widget.reportId,
      receiverReportId: widget.receiverReportId,
    );
  }

  @override
  void dispose() {
    _roomListener?.cancel();
    messageController.dispose();
    super.dispose();
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
            stream: _messageService.getChatRoomStream(widget.chatRoomId),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.exists) {
                var roomData = snapshot.data!.data() as Map<String, dynamic>;
                int unreadCount =
                (roomData['unreadCount'] as num? ?? 0).toInt();
                String lastSenderId = roomData['lastSenderId'] ?? "";
                if (unreadCount > 0 && lastSenderId != myUid) {
                  _messageService.markAsRead(widget.chatRoomId);
                }
              }
              return Text(widget.userName,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo'));
            },
          ),
          centerTitle: true,
          actions: [
            FutureBuilder<String?>(
              future: _messageService.getMyReportType(
                senderId: widget.senderId,
                reportId: widget.reportId,
                receiverReportId: widget.receiverReportId,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == 'lost') {
                  return IconButton(
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.textPrimary),
                    onPressed: _showOptionsMenu,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            Column(
              children: [
                const Center(
                    child: ChatAvatar(
                        imageUrl: 'https://via.placeholder.com/150')),
                const SizedBox(height: 10),
                Text(widget.userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Cairo')),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _messageService.getMessages(widget.chatRoomId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFB293CD)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text("ابدأ الدردشة الآن..",
                            style: TextStyle(fontFamily: 'Cairo')));
                  }
                  final messages = snapshot.data!.docs;
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var data =
                      messages[index].data() as Map<String, dynamic>;
                      return ChatBubble(
                        message: data['message'] ?? "",
                        isSender: data['senderId'] == myUid,
                        time: (data['timestamp'] as Timestamp?)
                            ?.toDate()
                            .toString()
                            .substring(11, 16) ??
                            "",
                      );
                    },
                  );
                },
              ),
            ),
            ChatInputField(controller: messageController, onSend: _sendMessage),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

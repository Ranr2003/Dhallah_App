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
  final ChatService _chatService = ChatService();

  // جلب المعرف من الـ ChatService (سيكون هو الـ UID من فايربيس)
  late String currentUserId;

  @override
  void initState() {
  super.initState();
  print("Current User UID: ${_chatService.currentUserId}");
  currentUserId = _chatService.currentUserId ?? "unknown";
  }

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
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.userName, style: const TextStyle(color: AppColors.textPrimary)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            Center(child: ChatAvatar(imageUrl: 'https://via.placeholder.com/150')),
            const SizedBox(height: 10),
            Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
                    return const Center(child: Text("لا توجد رسائل بعد.. ابدأ الدردشة!"));
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var data = messages[index].data() as Map<String, dynamic>;

                      bool isMe = data['senderId'] == currentUserId;

                      DateTime? date = (data['timestamp'] as Timestamp?)?.toDate();
                      String timeString = date != null ? "${date.hour}:${date.minute}" : "..";

                      return ChatBubble(
                        message: data['messageText'] ?? "",
                        isSender: isMe,
                        time: timeString,
                      );
                    },
                  );
                },
              ),
            ),
            ChatInputField(
              controller: _messageController,
              onSend: _sendChatMessage,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/report_model.dart';
import '../services/database_serv.dart';
import '../services/item_serv.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_widgets.dart';
import 'messages_page.dart';

class MatchesPage extends StatefulWidget {
  final List<dynamic> matches;
  final String currentUid;
  const MatchesPage({super.key, required this.matches, required this.currentUid});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final Map<String, Report?> _reportCache = {};

  final ItemService _service = ItemService();

  Future<Report?> _getReport(String id) async {
    if (!_reportCache.containsKey(id)) {
      _reportCache[id] = await _service.getReportById(id);
    }
    return _reportCache[id];
  }
  @override
  Widget build(BuildContext context) {
    return Directionality(
             textDirection: ui.TextDirection.rtl,
             child: Container(
                      decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Color(0xFFFDFBFF), Color(0xFFF2E7FE)],
                                    ),
                     ),
                     child: Scaffold(
                          backgroundColor: Colors.transparent,
                          body: SafeArea(
                                  child: Column(
                                            children: [
                                                       _buildAppBar(),
                                                       _buildMatchList(),
                                            ],
                                  ),
                          ),
                     ),
             ),
    );
  }
  Widget _buildAppBar() {
    return Padding(
             padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
             child: Stack(
                      alignment: Alignment.center,
                      children: [
                                 Text("نتائج التطابق الذكي",
                                   style: TextStyle(
                                           fontFamily: 'Tajawal',
                                           fontSize: AppDimens.fontAppBar,
                                           fontWeight: FontWeight.bold,
                                           color: AppColors.primaryDark,
                                   ),
                                 ),
                                 Align(
                                   alignment: Alignment.centerRight,
                                   child: IconButton(
                                            icon: Icon(Icons.arrow_back_ios,
                                                    size: 30,
                                                    color: AppColors.primaryDark,
                                            ),
                                            onPressed: () => Navigator.pop(context),
                                   ),
                                ),
                      ],
             ),
    );
  }
  Widget _buildMatchList() {
    return Expanded(
             child: widget.matches.isEmpty ? _buildEmptyState()
                  : ListView.builder(
                         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                         itemCount: widget.matches.length,
                         itemBuilder: (context, index) {
                           final match = widget.matches[index];
                           final double score = (match['score'] ?? 0.0) * 100;
                           final String matchedId = match['matched_report_id'] ?? "";
                           return _buildMatchCard(matchedId, score);
                         },
                 ),
    );
  }
  Widget _buildEmptyState() {
    return  Center(
      child: Text("لا توجد نتائج",
        style: TextStyle(
            fontFamily: 'Tajawal'),
      ),
    );
  }
  Widget _buildMatchCard(String matchedId, double score) {
    return FutureBuilder<Report?>(
         future: _getReport(matchedId),
         builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingShimmer();
            }
            final report = snapshot.data;
            if (report == null) return const SizedBox();
            return _buildCardContent(report, score);
         },
    );
  }
  Widget _buildLoadingShimmer() {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      height: 145,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFFB293CD),
        ),
      ),
    );
  }

  Widget _buildCardContent(Report report, double score) {
    return Container(
             margin: EdgeInsets.only(bottom: 15),
             decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                   BoxShadow(
                     color: const Color(0xFFD2B4EC).withValues(alpha: 0.15),
                     blurRadius: 10,
                     offset: const Offset(0, 4),
                  ),
               ],
             ),
            child: IntrinsicHeight(
                 child: Row(
                         crossAxisAlignment: CrossAxisAlignment.stretch,
                         children: [
                                    _buildItemImage(report.item.imageURL),
                                    _buildItemDetails(report, score),
                         ],
                 ),
            ),
    );
  }

  Widget _buildItemImage(String imageUrl) {
    return Container(
            width: 115,
            color: Colors.grey[50],
            child: Image.network(imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(
                          width: 115,
                          color: Colors.grey[100],
                          child: Icon(Icons.image_not_supported,
                                   color: Colors.grey,
                                   size: 30,
                          ),
                        ),
           ),
    );
  }

  Widget _buildItemDetails(Report report, double score) {
    return Expanded(
            child: Padding(
                     padding: const EdgeInsets.all(10),
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                         Row(
                                           children: [
                                             Expanded(
                                               child: Text(report.item.category,
                                                        style: TextStyle(
                                                                 fontFamily: 'Tajawal',
                                                                 fontSize: AppDimens.fontXl,
                                                                 fontWeight: FontWeight.bold,
                                                                 color: AppColors.darkgray,
                                                        ),
                                               ),
                                             ),
                                             Padding(
                                               padding: EdgeInsets.only(top: 8, left: 4),
                                               child: _buildScoreCircle(score),
                                             ),
                                           ],
                                         ),
                                        const SizedBox(height: 6),
                                       InfoRow(
                                           text: report.locationName,
                                           icon: Icons.place_outlined,
                                           isRtl: true,
                                           color: Colors.grey,
                                           ),
                                        const SizedBox(height: 12),
                                WaterRippleButton(
                                  text: 'تواصل الآن',
                                  height: 40,
                                  onTap: () async {
                                    final receiverId = report.userId;
                                    final senderId = widget.currentUid;

                                    if (receiverId == "unknown" || receiverId == senderId) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("لا يمكن بدء محادثة مع هذا المستخدم")),
                                      );
                                      return;
                                    }

                                    // 1. جلب بيانات المستخدم المستلم (صاحب البلاغ) من قاعدة البيانات
                                    final DatabaseService _dbService = DatabaseService();
                                    final receiverData = await _dbService.getUserById(receiverId);

                                    // جلب اسم المستلم الحقيقي، وإذا لم يوجد نضع "مستخدم" كاحتياط
                                    String displayName = receiverData?.name ?? "مستخدم";

                                    // 2. إنشاء معرف الغرفة الفريد
                                    List<String> ids = [senderId, receiverId];
                                    ids.sort();
                                    String chatRoomId = ids.join("_");

                                    // 3. التحقق من الغرفة في Firestore أو إنشاؤها
                                    final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId);
                                    final doc = await chatRoomRef.get();

                                    if (!doc.exists) {
                                      await chatRoomRef.set({
                                        'participants': ids,
                                        'lastMessage': "",
                                        'senderName': "مستخدم", // يمكن جلب اسم المرسل أيضاً بنفس الطريقة لو حابة
                                        'receiverName': displayName,
                                        'senderId': senderId,
                                        'receiverId': receiverId,
                                        'timestamp': FieldValue.serverTimestamp(),
                                        'unreadCount': 0,
                                      });
                                    }

                                    // 4. الانتقال لصفحة الرسائل بالاسم الحقيقي للمستخدم
                                    if (mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MessagesPage(
                                            userName: displayName, // سيظهر الآن اسم المستخدم الحقيقي (مثل رنيده) تلقائياً
                                            receiverId: receiverId,
                                            chatRoomId: chatRoomId,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                )

                              ],
                     ),
            ),
    );
  }
  Widget _buildScoreCircle(double score) {
    return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                         value: score / 100,
                         strokeWidth:5,
                         backgroundColor:  Colors.grey[50],
                         valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              Text("${score.toStringAsFixed(0)}%",
                  style: TextStyle(
                           fontSize: 9,
                           fontWeight: FontWeight.bold,
                           color:AppColors.primaryDark,
                  ),
              ),
            ],
    );
  }

}

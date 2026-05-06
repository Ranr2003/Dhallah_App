import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/report_model.dart';
import '../services/database_serv.dart';
import '../services/report_serv.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_widgets.dart';
import 'messages_page.dart';
import '../services/message_serv.dart';


class MatchesPage extends StatefulWidget {
  final List<dynamic> matches;
  final String currentUid;
  final String reportId;

  const MatchesPage({
    super.key,
    required this.matches,
    required this.currentUid,
    required this.reportId,
  });

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final Map<String, Report?> _reportCache = {};
  final ReportService _reportService = ReportService();
  final DatabaseService dbService = DatabaseService();
  final MessageService _messageService = MessageService();
  Future<Report?> _getReport(String id) async {
    if (!_reportCache.containsKey(id)) {
      _reportCache[id] = await _reportService.fetchReportById(id);
    }
    return _reportCache[id];
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            "نتائج التطابق",
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
              icon: const Icon(Icons.arrow_back_ios,
                  size: 20,
                  color: AppColors.primaryDark
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
      child: widget.matches.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
    return const Center(
      child: Text("لا توجد نتائج", style: TextStyle(fontFamily: 'Tajawal')),
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
      margin: const EdgeInsets.only(bottom: 15),
      height: 145,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFB293CD)),
      ),
    );
  }

  Widget _buildCardContent(Report report, double score) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
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
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 115,
          color: Colors.grey[100],
          child: const Icon(Icons.image_not_supported,
              color: Colors.grey,
              size: 30
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
                  child: Text(
                    report.item.category,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: AppDimens.fontXl,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkgray,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
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
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                final receiverId = report.userId;
                final senderId = widget.currentUid;

                if (receiverId == "unknown" || receiverId == senderId) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text("لا يمكن بدء محادثة مع هذا المستخدم")),
                  );
                  return;
                }

                List<String> participants = [senderId, receiverId]..sort();
                List<String> reportIds = [widget.reportId, report.reportId ?? ""]..sort();
                String chatRoomId = "chat_${participants.join("_")}_${reportIds.join("_")}";

                final receiverData = await dbService.getUserById(receiverId);
                String receiverDisplayName = receiverData?.name ?? "مستخدم";

                await _messageService.initializeChatRoom(
                  chatRoomId: chatRoomId,
                  senderId: senderId,
                  receiverId: receiverId,
                  reportId: widget.reportId,
                  receiverReportId: report.reportId ?? "",
                  userName: receiverDisplayName,
                );

                if (!mounted) return;

                navigator.push(
                  MaterialPageRoute(
                    builder: (context) => MessagesPage(
                      userName: receiverDisplayName,
                      receiverId: receiverId,
                      chatRoomId: chatRoomId,
                      senderId: senderId,
                      reportId: widget.reportId,
                      receiverReportId: report.reportId ?? "",
                      fromMatches: true,
                    ),
                  ),
                );
              },
            ),
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
            strokeWidth: 5,
            backgroundColor: Colors.grey[50],
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        Text(
          "${score.toStringAsFixed(0)}%",
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}
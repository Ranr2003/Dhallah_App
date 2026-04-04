// admin_page.dart
// نسخة كاملة ومصححة (تم إصلاح أقواس السطور 90-100)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إدارة بلاغات ضالة",
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5A4A75),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "المفقودات", icon: Icon(Icons.search_off)),
            Tab(text: "الموجودات", icon: Icon(Icons.check_circle_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsList('lost_reports'),
          _buildReportsList('found_reports'),
        ],
      ),
    );
  }

  Widget _buildReportsList(String collectionName) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collectionName)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("خطأ في الاتصال بالسيرفر"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF5A4A75)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("لا توجد بلاغات نشطة حالياً",
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: collectionName == 'lost_reports'
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  child: Icon(
                    collectionName == 'lost_reports' ? Icons.priority_high : Icons.check,
                    color: collectionName == 'lost_reports' ? Colors.red : Colors.green,
                  ),
                ),
                title: Text(data['itemName'] ?? "بلاغ بدون عنوان",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                subtitle: Text("الموقع: ${data['location'] ?? 'غير محدد'}",
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () => _showReportDetails(data, doc.id, collectionName),
              ), // تم إصلاح القوس هنا
            ); // تم إصلاح القوس هنا
          },
        );
      },
    );
  }

  void _showReportDetails(Map<String, dynamic> data, String docId, String collection) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  const Text("تفاصيل البلاغ",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                ],
              ),
              const Divider(),
              _detailRow("الغرض:", data['itemName']),
              _detailRow("الموقع:", data['location']),
              _detailRow("الوصف:", data['description'] ?? "لا يوجد وصف إضافي"),
              _detailRow("تاريخ البلاغ:", data['date'] ?? "غير محدد"),
              const SizedBox(height: 20),
              const Text("معلومات التواصل:", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              _detailRow("الاسم:", data['userName']?.toString() ?? "غير متوفر"),
              _detailRow("الجوال:", data['userPhone']?.toString() ?? "غير متوفر"),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmDelete(collection, docId),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("حذف البلاغ نهائياً", style: TextStyle(fontFamily: 'Cairo')),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(value ?? "غير متوفر",
                textAlign: TextAlign.right,
                style: const TextStyle(fontFamily: 'Cairo')),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF5A4A75))),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(String collection, String docId) async {
    Navigator.pop(context);
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("حذف بلاغ"),
          content: const Text("هل أنت متأكد من حذف هذا البلاغ؟ لا يمكن التراجع عن هذه الخطوة."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
                Navigator.pop(context);
              },
              child: const Text("حذف", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
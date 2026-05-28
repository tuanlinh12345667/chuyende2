import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiProvider = Provider.of<ApiProvider>(context);
    final notifications = apiProvider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông Báo Mới", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF007FF0),
        centerTitle: true,
        elevation: 0,
      ),
      body: notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text("Hộp thư trống thông báo", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.campaign, color: Color(0xFF007FF0)),
              ),
              title: Text(
                item["title"] ?? "",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(item["body"] ?? "", style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(item["time"] ?? "", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                onPressed: () {
                  apiProvider.removeNotification(item["id"]!);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
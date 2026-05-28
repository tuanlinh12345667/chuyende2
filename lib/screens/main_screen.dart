import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'notification_screen.dart';
import 'account_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0; // Để mặc định tab Trang chủ khi mở app

  // Danh sách chỉ còn 3 màn hình: Trang chủ (0), Thông báo (1), Tài khoản (2)
  final List<Widget> _tabs = [
    const HomeScreen(),
    const NotificationScreen(),
    const AccountScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (i) => setState(() => _index = i),
        // ĐÃ SỬA: Loại bỏ mục Khuyến mãi, danh sách items khớp hoàn toàn với mảng _tabs bên trên
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
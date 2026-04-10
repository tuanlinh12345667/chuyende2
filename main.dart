import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_provider.dart';
import 'product_detail_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// ----------------------------------------------------
// CLASS AuthProvider: QUẢN LÝ TÀI KHOẢN, YÊU THÍCH, ĐÃ XEM & VOUCHER
// ----------------------------------------------------
class AuthProvider with ChangeNotifier {
  SharedPreferences? _prefs;
  bool _isLoggedIn = false;
  String _username = '';
  String _email = '';
  String _membershipLevel = 'Hội viên Mới';
  int _points = 0;
  int _voucherCount = 0; // Thêm quản lý số lượng voucher
  List<String> _likedProducts = [];
  List<String> _viewedProducts = []; // Thêm danh sách đã xem

  Map<String, dynamic> _usersDatabase = {};

  bool get isLoggedIn => _isLoggedIn;
  String get username => _username;
  String get membershipLevel => _membershipLevel;
  int get points => _points;
  int get voucherCount => _voucherCount;
  List<String> get likedProducts => _likedProducts;
  List<String> get viewedProducts => _viewedProducts;

  AuthProvider() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    String? dbString = _prefs?.getString('users_db');
    if (dbString != null) {
      _usersDatabase = json.decode(dbString);
    }
    String? loggedInEmail = _prefs?.getString('logged_in_email');
    if (loggedInEmail != null && _usersDatabase.containsKey(loggedInEmail)) {
      _email = loggedInEmail;
      _isLoggedIn = true;
      _loadUserData();
    }
    notifyListeners();
  }

  void _loadUserData() {
    final userData = _usersDatabase[_email];
    _username = userData['username'];
    _points = userData['points'];
    _membershipLevel = userData['level'];
    _voucherCount = userData['vouchers'] ?? 0;
    _likedProducts = List<String>.from(userData['liked'] ?? []);
    _viewedProducts = List<String>.from(userData['viewed'] ?? []);
  }

  Future<void> _saveDatabase() async {
    await _prefs?.setString('users_db', json.encode(_usersDatabase));
  }

  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  Future<String?> register(String email, String password, String username) async {
    await Future.delayed(const Duration(seconds: 1));
    if (!isValidEmail(email)) return "Định dạng email không hợp lệ!";
    if (password.length < 6) return "Mật khẩu phải có ít nhất 6 ký tự!";
    if (_usersDatabase.containsKey(email)) return "Email này đã được đăng ký!";

    _usersDatabase[email] = {
      'password': password,
      'username': username.isNotEmpty ? username : email.split('@')[0],
      'points': 200,
      'level': 'Hội viên Bạc',
      'vouchers': 0, // Khởi tạo 0 voucher
      'liked': [],
      'viewed': [] // Khởi tạo danh sách đã xem rỗng
    };
    await _saveDatabase();
    return null;
  }

  Future<String?> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (!isValidEmail(email)) return "Định dạng email không hợp lệ!";
    if (!_usersDatabase.containsKey(email)) return "Tài khoản không tồn tại. Vui lòng đăng ký!";
    if (_usersDatabase[email]!['password'] != password) return "Mật khẩu không chính xác!";

    _isLoggedIn = true;
    _email = email;
    _loadUserData();
    await _prefs?.setString('logged_in_email', email);
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _username = '';
    _email = '';
    _likedProducts = [];
    _viewedProducts = [];
    _voucherCount = 0;
    await _prefs?.remove('logged_in_email');
    notifyListeners();
  }

  bool isLiked(String productId) => _likedProducts.contains(productId);

  void toggleLike(String productId) {
    if (!_isLoggedIn) return;
    if (_likedProducts.contains(productId)) {
      _likedProducts.remove(productId);
    } else {
      _likedProducts.add(productId);
    }
    _usersDatabase[_email]['liked'] = _likedProducts;
    _saveDatabase();
    notifyListeners();
  }

  // THÊM: Chức năng lưu sản phẩm đã xem
  void addViewedProduct(String productId) {
    if (!_isLoggedIn) return;
    _viewedProducts.remove(productId); // Xóa nếu đã có để đưa lên đầu
    _viewedProducts.insert(0, productId); // Thêm vào vị trí đầu tiên
    if (_viewedProducts.length > 20) {
      _viewedProducts.removeLast(); // Chỉ giữ tối đa 20 sản phẩm gần nhất
    }
    _usersDatabase[_email]['viewed'] = _viewedProducts;
    _saveDatabase();
    notifyListeners();
  }

  // THÊM: Chức năng thu thập voucher
  void addVoucher() {
    if (!_isLoggedIn) return;
    _voucherCount++;
    _usersDatabase[_email]['vouchers'] = _voucherCount;
    _saveDatabase();
    notifyListeners();
  }
}

// ----------------------------------------------------
// UI CHÍNH
// ----------------------------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Price Compare Pro',
      theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[100],
          appBarTheme: const AppBarTheme(iconTheme: IconThemeData(color: Colors.white))),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ApiProvider>(context, listen: false).fetchProductsFromApi();
    });
  }

  String formatCurrency(double price) => NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);

  Widget _buildHomeTab(ApiProvider provider) {
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 140, margin: const EdgeInsets.symmetric(vertical: 12), child: const BannerCarousel()),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: provider.categories.length,
              itemBuilder: (context, index) {
                final cat = provider.categories[index];
                final isSelected = cat == provider.selectedCategory;
                return GestureDetector(
                  onTap: () => provider.setCategory(cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: isSelected ? Colors.blue[700] : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[300]!)),
                    child: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                );
              },
            ),
          ),
          const Padding(padding: EdgeInsets.all(12.0), child: Text('Deal giá tốt nhất hôm nay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: provider.filteredProducts.length,
            itemBuilder: (context, index) {
              final product = provider.filteredProducts[index];
              return GestureDetector(
                onTap: () {
                  // LƯU VÀO LỊCH SỬ ĐÃ XEM KHI BẤM VÀO SẢN PHẨM
                  auth.addViewedProduct(product.id);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))]),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(tag: product.id, child: Image.network(product.imageUrl, width: 90, height: 90, fit: BoxFit.cover, cacheWidth: 250, errorBuilder: (c,e,s) => const Icon(Icons.image))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Row(children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              Text(' ${product.rating} (${product.reviews})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const Spacer(),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(4)), child: Text('So sánh ${product.prices.length} nguồn', style: TextStyle(color: Colors.green[700], fontSize: 11, fontWeight: FontWeight.bold)))
                            ]),
                            const SizedBox(height: 8),
                            Text(formatCurrency(product.lowestPrice), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 17)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildBody(ApiProvider provider) {
    switch (_selectedIndex) {
      case 0: return _buildHomeTab(provider);
      case 1: return const PromoTab(); // Đã có chức năng mới
      case 2: return const NotificationTab(); // Đã có chức năng mới
      case 3: return const AccountTab();
      default: return _buildHomeTab(provider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ApiProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        elevation: 0,
        title: Text(_selectedIndex == 0 ? '' : _selectedIndex == 1 ? 'Khuyến mãi hot' : _selectedIndex == 2 ? 'Thông báo' : 'Tài khoản', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
      ),
      body: _buildBody(provider),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.label), label: 'Khuyến mãi'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Thông báo'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});
  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
        if (_currentPage < 2) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        if (_controller.hasClients) {
          _controller.animateToPage(_currentPage, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = Provider.of<ApiProvider>(context, listen: false).banners;
    return PageView.builder(
      controller: _controller,
      onPageChanged: (value) => setState(() => _currentPage = value),
      itemCount: banners.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage(banners[index]), fit: BoxFit.cover)),
        );
      },
    );
  }
}

// ----------------------------------------------------
// TÍNH NĂNG MỚI: MÀN HÌNH KHUYẾN MÃI (VOUCHER)
// ----------------------------------------------------
class PromoTab extends StatefulWidget {
  const PromoTab({super.key});
  @override
  State<PromoTab> createState() => _PromoTabState();
}

class _PromoTabState extends State<PromoTab> {
  // Fake data danh sách voucher
  final List<Map<String, dynamic>> _vouchers = [
    {'id': '1', 'title': 'Giảm 50K cho Đơn từ 500K', 'code': 'PRICEPRO50', 'saved': false, 'color': Colors.orange},
    {'id': '2', 'title': 'Freeship mọi đơn hàng', 'code': 'FREESHIP', 'saved': false, 'color': Colors.green},
    {'id': '3', 'title': 'Giảm 10% tối đa 100K Điện thoại', 'code': 'PHONE10', 'saved': false, 'color': Colors.blue},
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vouchers.length,
      itemBuilder: (context, index) {
        final voucher = _vouchers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                    color: voucher['color'].withOpacity(0.2),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12))
                ),
                child: Center(child: Icon(Icons.local_offer, size: 40, color: voucher['color'])),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(voucher['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Mã: ${voucher['code']}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton(
                  onPressed: voucher['saved'] ? null : () {
                    if (!auth.isLoggedIn) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để lưu voucher!')));
                      return;
                    }
                    setState(() { voucher['saved'] = true; });
                    auth.addVoucher(); // Tăng số lượng voucher ở Tab Tài khoản
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã lưu mã ${voucher['code']}! Kiểm tra trong Tài khoản.'), backgroundColor: Colors.green));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: voucher['saved'] ? Colors.grey : Colors.blue[800],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(voucher['saved'] ? 'Đã lưu' : 'Lưu', style: const TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------
// TÍNH NĂNG MỚI: MÀN HÌNH THÔNG BÁO
// ----------------------------------------------------
class NotificationTab extends StatefulWidget {
  const NotificationTab({super.key});
  @override
  State<NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab> {
  // Fake data thông báo
  final List<Map<String, dynamic>> _notifications = [
    {'title': 'Sản phẩm bạn thích đang giảm giá!', 'body': 'iPhone 15 Pro Max vừa giảm 500k tại Shopee.', 'time': '10 phút trước', 'isRead': false, 'icon': Icons.trending_down, 'color': Colors.red},
    {'title': 'Chào mừng bạn mới', 'body': 'Tặng bạn mã FREESHIP cho đơn hàng đầu tiên.', 'time': '2 giờ trước', 'isRead': false, 'icon': Icons.card_giftcard, 'color': Colors.green},
    {'title': 'Cập nhật tính năng mới', 'body': 'Price Compare Pro vừa cập nhật tính năng biểu đồ giá.', 'time': '1 ngày trước', 'isRead': true, 'icon': Icons.new_releases, 'color': Colors.blue},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: _notifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notif = _notifications[index];
        return Container(
          color: notif['isRead'] ? Colors.white : Colors.blue[50],
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(backgroundColor: notif['color'].withOpacity(0.2), child: Icon(notif['icon'], color: notif['color'])),
            title: Text(notif['title'], style: TextStyle(fontWeight: notif['isRead'] ? FontWeight.normal : FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(notif['body'], style: TextStyle(color: Colors.grey[800])),
                const SizedBox(height: 4),
                Text(notif['time'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            onTap: () {
              setState(() { notif['isRead'] = true; }); // Đánh dấu đã đọc
            },
          ),
        );
      },
    );
  }
}

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.isLoggedIn) {
      return const MemberDashboard();
    }
    return const LoginForm();
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLogin = true;
  bool _isAuthLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return _isAuthLoading
        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 10), Text('Đang xử lý...')]))
        : Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle, size: 90, color: Colors.blue[700]),
            const SizedBox(height: 20),
            Text(_isLogin ? 'Đăng nhập tài khoản' : 'Tạo tài khoản mới', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            if (!_isLogin) ...[
              const SizedBox(height: 16),
              TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Tên hiển thị (Không bắt buộc)', prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            ],
            const SizedBox(height: 16),
            TextField(controller: _passController, obscureText: true, decoration: InputDecoration(labelText: 'Mật khẩu', prefixIcon: const Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final email = _emailController.text.trim();
                  final pass = _passController.text;
                  final name = _nameController.text.trim();

                  if (email.isEmpty || pass.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đủ email và mật khẩu!'), backgroundColor: Colors.orange));
                    return;
                  }

                  setState(() => _isAuthLoading = true);
                  String? errorMessage;

                  if (_isLogin) {
                    errorMessage = await auth.login(email, pass);
                  } else {
                    errorMessage = await auth.register(email, pass, name);
                    if (errorMessage == null) await auth.login(email, pass);
                  }

                  setState(() => _isAuthLoading = false);

                  if (errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isLogin ? 'Đăng nhập thành công!' : 'Đăng ký thành công!'), backgroundColor: Colors.green));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(_isLogin ? 'ĐĂNG NHẬP' : 'ĐĂNG KÝ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? 'Chưa có tài khoản? Đăng ký ngay' : 'Đã có tài khoản? Đăng nhập', style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold))
            )
          ],
        ),
      ),
    );
  }
}

class MemberDashboard extends StatelessWidget {
  const MemberDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(radius: 40, backgroundColor: Colors.blue[800], child: Text(auth.username.isNotEmpty ? auth.username[0].toUpperCase() : '?', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))),
              const SizedBox(width: 20),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(auth.username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)), child: Text(auth.membershipLevel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))),
              ]),
              const Spacer(),
              IconButton(icon: Icon(Icons.settings, color: Colors.blue[800]), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [const Text('Điểm', style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 4), Text('${auth.points}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue))]),
                const VerticalDivider(),
                // SỐ VOUCHER ĐÃ ĐƯỢC LIÊN KẾT VỚI DỮ LIỆU THẬT
                Column(children: [const Text('Voucher', style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 4), Text('${auth.voucherCount}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: const Text('Sản phẩm đã thích', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LikedProductsScreen())),
          ),
          const Divider(),
          // NÚT SẢN PHẨM ĐÃ XEM ĐÃ CÓ THỂ BẤM
          ListTile(
            leading: const Icon(Icons.history, color: Colors.blue),
            title: const Text('Sản phẩm đã xem', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ViewedProductsScreen())),
          ),
          const Divider(),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => auth.logout(),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text('ĐĂNG XUẤT', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}

class LikedProductsScreen extends StatelessWidget {
  const LikedProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final api = Provider.of<ApiProvider>(context, listen: false);

    final likedItems = api.filteredProducts.where((p) => auth.likedProducts.contains(p.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm đã thích', style: TextStyle(color: Colors.black87)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black87), elevation: 0),
      body: likedItems.isEmpty
          ? const Center(child: Text('Bạn chưa thích sản phẩm nào cả 💔', style: TextStyle(fontSize: 16, color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: likedItems.length,
        itemBuilder: (context, index) {
          final product = likedItems[index];
          return Card(
            child: ListTile(
              leading: Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
              title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(product.lowestPrice), style: const TextStyle(color: Colors.red)),
              trailing: IconButton(icon: const Icon(Icons.favorite, color: Colors.red), onPressed: () => auth.toggleLike(product.id)),
              onTap: () {
                auth.addViewedProduct(product.id); // Lưu lịch sử khi bấm xem từ đây
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));
              },
            ),
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------
// TÍNH NĂNG MỚI: MÀN HÌNH SẢN PHẨM ĐÃ XEM
// ----------------------------------------------------
class ViewedProductsScreen extends StatelessWidget {
  const ViewedProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final api = Provider.of<ApiProvider>(context, listen: false);

    // Lọc ra các sản phẩm dựa theo ID trong danh sách đã xem, giữ nguyên thứ tự mới nhất
    final viewedItems = auth.viewedProducts.map((id) => api.filteredProducts.firstWhere((p) => p.id == id, orElse: () => api.filteredProducts[0])).toList();
    // Loại bỏ các trường hợp lỗi nếu ID không tồn tại (đề phòng)
    viewedItems.removeWhere((p) => !auth.viewedProducts.contains(p.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm đã xem gần đây', style: TextStyle(color: Colors.black87, fontSize: 16)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black87), elevation: 0),
      body: auth.viewedProducts.isEmpty
          ? const Center(child: Text('Lịch sử xem trống 🕒', style: TextStyle(fontSize: 16, color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: viewedItems.length,
        itemBuilder: (context, index) {
          final product = viewedItems[index];
          return Card(
            child: ListTile(
              leading: Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
              title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(product.lowestPrice), style: const TextStyle(color: Colors.red)),
              onTap: () {
                auth.addViewedProduct(product.id); // Cập nhật lại vị trí lên đầu
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));
              },
            ),
          );
        },
      ),
    );
  }
}
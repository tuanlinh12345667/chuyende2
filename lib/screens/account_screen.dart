import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_provider.dart';
import 'product_detail_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isLoginMode = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _handleAuthSubmit(ApiProvider provider) {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String msgResult;

    if (_isLoginMode) {
      msgResult = provider.loginUser(email, password);
    } else {
      msgResult = provider.registerUser(email, password);
    }

    if (msgResult == "SUCCESS") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isLoginMode ? "Đăng nhập thành công!" : "Đăng ký thành công! Đang chuyển sang đăng nhập.")),
      );
      if (!_isLoginMode) {
        setState(() {
          _isLoginMode = true;
        });
      }
      _passwordController.clear();
    } else {
      // Phát hiện thiếu ký tự @, dấu chấm, mật khẩu ngắn -> Báo lỗi chi tiết bằng Dialog trực quan
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text("Lỗi xác thực", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(msgResult, style: const TextStyle(fontSize: 15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Đồng ý", style: TextStyle(color: Color(0xFF007FF0), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiProvider = Provider.of<ApiProvider>(context);

    // TRƯỜNG HỢP 1: CHƯA ĐĂNG NHẬP -> XUẤT FORM ĐĂNG KÝ / ĐĂNG NHẬP CHUẨN
    if (!apiProvider.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isLoginMode ? "Đăng Nhập Hệ Thống" : "Tạo Tài Khoản Mới"),
          backgroundColor: const Color(0xFF007FF0),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Icon(Icons.lock_person_outlined, size: 80, color: const Color(0xFF007FF0).withOpacity(0.8)),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email đăng nhập",
                  hintText: "vi_du@gmail.com",
                  prefixIcon: Icon(Icons.mail_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Mật khẩu bảo mật",
                  prefixIcon: Icon(Icons.lock_open_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007FF0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () => _handleAuthSubmit(apiProvider),
                  child: Text(_isLoginMode ? "ĐĂNG NHẬP" : "ĐĂNG KÝ NGAY", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoginMode = !_isLoginMode;
                  });
                },
                child: Text(
                  _isLoginMode ? "Chưa có tài khoản? Đăng ký tại đây" : "Đã có tài khoản? Quay về đăng nhập",
                  style: const TextStyle(color: Color(0xFF007FF0), fontWeight: FontWeight.w600),
                ),
              )
            ],
          ),
        ),
      );
    }

    // TRƯỜNG HỢP 2: ĐÃ ĐĂNG NHẬP THÀNH CÔNG -> HIỂN THỊ TRẠNG THÁI YÊU THÍCH VÀ ĐÃ XEM
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF007FF0),
          elevation: 0,
          title: Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Color(0xFF007FF0))),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  apiProvider.currentUserEmail ?? "User",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              tooltip: 'Đăng xuất',
              onPressed: () => apiProvider.logout(),
            )
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.orange,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(icon: Icon(Icons.favorite), text: "Yêu thích"),
              Tab(icon: Icon(Icons.history), text: "Đã xem gần đây"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGridProductList(context, apiProvider.favoriteProducts, "Danh sách yêu thích trống.\nHãy nhấn tim ❤️ tại trang sản phẩm!"),
            _buildGridProductList(context, apiProvider.viewedProducts, "Bạn chưa xem sản phẩm nào gần đây."),
          ],
        ),
      ),
    );
  }

  Widget _buildGridProductList(BuildContext context, List<dynamic> products, String errorMsg) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // ĐÃ ĐƯỢC SỬA: CenterTextAlignment.center -> TextAlign.center
          child: Text(errorMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.4)),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.76,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return GestureDetector(
          onTap: () {
            // Khi ấn xem lại, tự động đẩy sản phẩm lên đầu tiên trong danh sách đã xem
            Provider.of<ApiProvider>(context, listen: false).addViewedProduct(product);
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)));
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  "${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{3})(?=\d)'), (Match m) => '${m[1]}.')} đ",
                  style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
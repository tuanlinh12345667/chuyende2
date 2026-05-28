import 'dart:async';
import 'dart:convert'; // 🟢 Thêm thư viện giải mã JSON
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http; // 🟢 THÊM THƯ VIỆN KẾT NỐI MẠNG INTERNET
import '../models/product_model.dart';

class ApiProvider with ChangeNotifier {
  final List<ProductModel> _viewedProducts = [];

  // ===========================================================================
  // 🟢 QUẢN LÝ TRẠNG THÁI TÀI KHOẢN & BỘ NHỚ LƯU TRỮ CỐ ĐỊNH
  // ===========================================================================
  bool _isLoggedIn = false;
  String? _currentUserEmail;

  final Map<String, String> _userDatabase = {
    "test@gmail.com": "123456",
    "admin@gmail.com": "123456",
  };

  final List<Map<String, String>> _notifications = [
    {
      "id": "1",
      "title": "Chào mừng bạn đến với SmartChoice!",
      "body": "Hệ thống tổng hợp dữ liệu và so sánh giá tiêu dùng thông minh trực tuyến đã sẵn sàng.",
      "time": "Vừa xong"
    },
  ];
  Timer? _notificationTimer;

  // BỘ ĐẾM VÀ BỘ NHỚ THEO DÕI BIẾN ĐỘNG GIÁ TỰ ĐỘNG
  Timer? _priceReductionTimer;
  final Map<String, double> _originalPrices = {};
  final Map<String, int> _reductionCounts = {};
  final Map<String, double> _dynamicReductions = {};

  // TRẠNG THÁI TẢI DỮ LIỆU
  bool _isLoading = false; // 🟢 Theo dõi trạng thái nạp dữ liệu

  ApiProvider() {
    // Kích hoạt nạp dữ liệu từ link API ONLINE thực tế
    fetchProducts();

    // Kích hoạt bộ đếm thời gian sinh thông báo tự động mỗi 30 giây đến 1 phút
    _startAutomaticNotifications();

    // Kích hoạt bộ đếm nhảy giá tuần hoàn mỗi 1 phút
    _startAutomaticPriceReduction();
  }

  // Getters cho các thuộc tính cơ bản
  List<ProductModel> get viewedProducts => _viewedProducts;
  List<ProductModel> get favoriteProducts => allProducts.where((p) => p.isFavorite).toList();
  bool get isLoading => _isLoading; // 🟢 Getter kiểm tra trạng thái đang tải

  // Getters cho phần Tài khoản & Thông báo mới
  bool get isLoggedIn => _isLoggedIn;
  String? get currentUserEmail => _currentUserEmail;
  List<Map<String, String>> get notifications => _notifications;

  // ===========================================================================
  // 🟢 LOGIC NẠP SẢN PHẨM TỪ LINK API ONLINE THỰC TẾ (ĐÃ ĐƯỢC CẬP NHẬT)
  // ===========================================================================
  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    // 🟢 DÁN ĐƯỜNG LINK BẠN VỪA LẤY ĐƯỢC TỪ JSONKEEPER HOẶC MOCKAPI VÀO ĐÂY NHÉ:
    final String apiUrl = "https://jsonkeeper.com/b/F2UJ2";

    try {
      // Gửi yêu cầu GET tải dữ liệu thực tế từ internet về máy
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // Giải mã chuỗi UTF-8 từ Server trả về để tránh lỗi font hiển thị tiếng Việt
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

        _allProducts.clear();

        // Duyệt qua chuỗi dữ liệu JSON thực tế mạng và ánh xạ thành cấu trúc ProductModel
        for (var item in data) {
          _allProducts.add(ProductModel.fromJson(item));
        }
        print("🟢 SmartChoice: Nạp kho dữ liệu sản phẩm từ API ONLINE thành công!");
      } else {
        print("🔴 Lỗi phản hồi từ Server Backend: ${response.statusCode}");
      }
    } catch (error) {
      print("🔴 Lỗi nghiêm trọng khi kết nối gọi dữ liệu mạng API: $error");
    } finally {
      _isLoading = false;
      notifyListeners(); // Kích hoạt render toàn bộ danh sách sản phẩm lên giao diện
    }
  }

  // ===========================================================================
  // 🟢 LOGIC XỬ LÝ ĐĂNG KÝ / ĐĂNG NHẬP CHUẨN KÝ TỰ (GIỮ NGUYÊN)
  // ===========================================================================
  String registerUser(String email, String password) {
    if (email.isEmpty || password.isEmpty) {
      return "Vui lòng điền đầy đủ thông tin tài khoản và mật khẩu!";
    }
    if (!email.contains("@") || !email.contains(".")) {
      return "Định dạng Email không hợp lệ (Thiếu ký tự '@' hoặc dấu '.')!";
    }
    if (password.length < 6) {
      return "Mật khẩu quá ngắn (Yêu cầu tối thiểu từ 6 ký tự trở lên)!";
    }
    if (_userDatabase.containsKey(email)) {
      return "Tài khoản Email này đã tồn tại trên hệ thống!";
    }

    _userDatabase[email] = password;
    notifyListeners();
    return "SUCCESS";
  }

  String loginUser(String email, String password) {
    if (email.isEmpty || password.isEmpty) {
      return "Vui lòng nhập đầy đủ Email và Mật khẩu!";
    }
    if (!_userDatabase.containsKey(email) || _userDatabase[email] != password) {
      return "Địa chỉ Email hoặc Mật khẩu không chính xác. Vui lòng kiểm tra lại!";
    }

    _isLoggedIn = true;
    _currentUserEmail = email;
    notifyListeners();
    return "SUCCESS";
  }

  void logout() {
    _isLoggedIn = false;
    _currentUserEmail = null;
    notifyListeners();
  }

  // ===========================================================================
  // 🟢 LOGIC THÔNG BÁO TỰ ĐỘNG KHÔNG CẦN QHA KHUYẾN MÃI (GIỮ NGUYÊN)
  // ===========================================================================
  void _startAutomaticNotifications() {
    int notificationIndex = 1;
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      notificationIndex++;
      _notifications.insert(0, {
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
        "title": "Cập nhật giá số #$notificationIndex 🔥",
        "body": "Hệ thống SmartChoice vừa quét và ghi nhận biến động giá mới tại các đại lý lớn. Bấm để xem chi tiết!",
        "time": "Vừa xong"
      });
      notifyListeners();
    });
  }

  // ===========================================================================
  // 🟢 LOGIC TỰ ĐỘNG NHẢY GIÁ DÙNG BỘ ĐẾM TRẠNG THÁI (GIỮ NGUYÊN)
  // ===========================================================================
  void _startAutomaticPriceReduction() {
    _priceReductionTimer?.cancel();

    _priceReductionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_allProducts.isEmpty) return;

      final random = Random();

      for (int i = 0; i < _allProducts.length; i++) {
        final product = _allProducts[i];
        String pId = product.id;

        if (!_originalPrices.containsKey(pId)) {
          _originalPrices[pId] = product.price;
          _reductionCounts[pId] = 0;
          _dynamicReductions[pId] = 0;
        }

        int currentCount = _reductionCounts[pId] ?? 0;

        if (currentCount >= 2) {
          _reductionCounts[pId] = 0;
          _dynamicReductions[pId] = 0;
        } else {
          double reductionAmount = 50000 + random.nextInt(50001).toDouble();

          double originalPrice = _originalPrices[pId]!;
          double accumulatedReduction = (_dynamicReductions[pId] ?? 0) + reductionAmount;

          if (originalPrice - accumulatedReduction > 50000) {
            _dynamicReductions[pId] = accumulatedReduction;
            _reductionCounts[pId] = currentCount + 1;
          }
        }
      }
      notifyListeners();
    });
  }

  void removeNotification(String id) {
    _notifications.removeWhere((notification) => notification["id"] == id);
    notifyListeners();
  }

  // ===========================================================================
  // 🟢 HOẠT ĐỘNG SẢN PHẨM ĐÃ XEM KHÔNG TRÙNG LẶP (GIỮ NGUYÊN)
  // ===========================================================================
  void addViewedProduct(ProductModel product) {
    _viewedProducts.removeWhere((p) => p.id == product.id);
    _viewedProducts.insert(0, product);
    notifyListeners();
  }

  void toggleFavorite(String productId) {
    final index = _allProducts.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _allProducts[index].isFavorite = !_allProducts[index].isFavorite;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 🟢 GETTERS THÔNG MINH - TỰ ĐỘNG AN BÀI GIÁ ĐÃ GIẢM KHI RENDER (GIỮ NGUYÊN)
  // ===========================================================================
  List<ProductModel> get products => allProducts;

  List<ProductModel> get allProducts {
    return _allProducts.map((product) {
      String pId = product.id;
      int count = _reductionCounts[pId] ?? 0;
      double reduction = _dynamicReductions[pId] ?? 0;

      if (count == 0 || reduction == 0) {
        return product;
      } else {
        return ProductModel(
          id: product.id,
          name: product.name,
          category: product.category,
          price: product.price - reduction,
          imageUrl: product.imageUrl,
          stores: product.stores,
          isFavorite: product.isFavorite,
        );
      }
    }).toList();
  }

  // ===========================================================================
  // 💎 KHỞI TẠO MẢNG RỖNG LINH HOẠT - NHẬN DỮ LIỆU ĐỘNG (GIỮ NGUYÊN)
  // ===========================================================================
  final List<ProductModel> _allProducts = [];

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _priceReductionTimer?.cancel();
    super.dispose();
  }
}
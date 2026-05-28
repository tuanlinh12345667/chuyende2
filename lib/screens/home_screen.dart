import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_provider.dart';
import 'product_detail_screen.dart';
// 🟢 BỔ SUNG IMPORT: Import trang danh mục sản phẩm mới
import 'category_products_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _hours = 12;
  int _minutes = 29;
  int _seconds = 34;
  Timer? _flashSaleTimer;

  String _searchQuery = "";
  String _selectedCategory = "Tất cả";

  @override
  void initState() {
    super.initState();
    _startFlashSaleCountdown();
  }

  @override
  void dispose() {
    _flashSaleTimer?.cancel();
    super.dispose();
  }

  void _startFlashSaleCountdown() {
    _flashSaleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_seconds > 0) {
            _seconds--;
          } else {
            _seconds = 59;
            if (_minutes > 0) {
              _minutes--;
            } else {
              _minutes = 59;
              if (_hours > 0) {
                _hours--;
              } else {
                _hours = 12;
                _minutes = 29;
                _seconds = 34;
              }
            }
          }
        });
      }
    });
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.'
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiProvider = Provider.of<ApiProvider>(context);
    final rawProducts = apiProvider.products;

    // Lọc sản phẩm cho khu vực chính dựa trên ô tìm kiếm và danh mục chọn (Từ thanh điều hướng đầu trang)
    final filteredProducts = rawProducts.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesCategory = true;
      if (_selectedCategory != "Tất cả") {
        matchesCategory = product.category.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
            _selectedCategory.toLowerCase().contains(product.category.toLowerCase());
      }
      return matchesSearch && matchesCategory;
    }).toList();

    // TỰ ĐỘNG LẤY SẢN PHẨM HIỂN THỊ VÀO MỤC GỢI Ý HÔM NAY (Đảo ngược danh sách)
    final suggestedProducts = rawProducts.reversed.toList();

    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 768; // Kiểm tra nếu là máy ảo di động hẹp
    int crossAxisCount = screenWidth > 1200 ? 5 : (screenWidth > 800 ? 3 : 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // 1. TOP HEADER XANH DƯƠNG (ĐÃ TỐI ƯU SAFEAREA HẠ THẤP TRÊN MOBILE)
            // -----------------------------------------------------------------
            Container(
              color: const Color(0xFF007FF0),
              child: SafeArea(
                bottom: false, // Chỉ kích hoạt đệm phía trên để né tai thỏ/nốt ruồi
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 40,
                    isMobile ? 12 : 16, // Đẩy khoảng cách trên cho thông thoáng
                    isMobile ? 16 : 40,
                    16,
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _searchQuery = "";
                            _selectedCategory = "Tất cả";
                          });
                        },
                        child: Text(
                          "SmartChoice",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 20 : 26,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 16 : 40),
                      Expanded(
                        child: Container(
                          height: 44, // Tăng nhẹ chiều cao giúp tăng diện tích bấm vào
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: 'Bạn muốn tìm sản phẩm gì...',
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                              prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 11), // Cân đối lại chữ bên trong ô
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // -----------------------------------------------------------------
            // 2. SUB CATEGORIES STRIP (ĐÃ SỬA: VUỐT NGANG KHÔNG LO TRÀN VIỀN)
            // -----------------------------------------------------------------
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: isMobile ? 16 : 40),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal, // Kích hoạt kéo vuốt ngang trên Mobile
                child: Row(
                  children: [
                    const Icon(Icons.menu, color: Colors.orange, size: 18),
                    const SizedBox(width: 6),
                    const Text("Danh mục sản phẩm", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13)),
                    const SizedBox(width: 20),
                    _buildTopNavButton("Tất cả"),
                    _buildTopNavButton("Điện thoại"),
                    _buildTopNavButton("Laptop"),
                    _buildTopNavButton("Đồng hồ"),
                    _buildTopNavButton("Phụ kiện"),
                    _buildTopNavButton("Điện lạnh"),
                  ],
                ),
              ),
            ),

            // -----------------------------------------------------------------
            // 3. MAIN HERO BANNERS (ĐÃ SỬA CHUYỂN DÒNG TRÊN MOBILE)
            // -----------------------------------------------------------------
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: isMobile
                    ? Column( // Nếu là Mobile thì xếp đè lên nhau
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network('https://picsum.photos/id/1073/800/350', height: 160, width: double.infinity, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network('https://picsum.photos/id/201/400/160', height: 90, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ],
                )
                    : Row( // Nếu là Web màn hình lớn thì xếp hàng ngang như cũ
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network('https://picsum.photos/id/1073/800/350', height: 260, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network('https://picsum.photos/id/201/400/160', height: 124, width: double.infinity, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network('https://picsum.photos/id/364/400/160', height: 124, width: double.infinity, fit: BoxFit.cover),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),

            // -----------------------------------------------------------------
            // 4. FLASH SALE SECTION
            // -----------------------------------------------------------------
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4500),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flash_on, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    const Text("Flash sale", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 20),
                    _buildTimerBox(_twoDigits(_hours)),
                    const SizedBox(width: 4),
                    const Text(":", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    _buildTimerBox(_twoDigits(_minutes)),
                    const SizedBox(width: 4),
                    const Text(":", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    _buildTimerBox(_twoDigits(_seconds)),
                  ],
                ),
              ),
            ),

            // -----------------------------------------------------------------
            // 5. PRODUCT GRID (Khu vực danh sách chính)
            // -----------------------------------------------------------------
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: filteredProducts.isEmpty
                    ? const SizedBox(
                    height: 150,
                    child: Center(
                        child: Text(
                          "Không tìm thấy sản phẩm phù hợp!",
                          textAlign: TextAlign.center,
                        )
                    )
                )
                    : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredProducts.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, index) {
                    final item = filteredProducts[index];
                    return _buildProductCard(context, item, index);
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // 6. DANH MỤC SẢN PHẨM (Grid Icon Trực Quan)
            // -----------------------------------------------------------------
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Danh mục sản phẩm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: screenWidth > 1200 ? 9 : (screenWidth > 800 ? 5 : 3),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 16,
                      children: [
                        _buildGridCategoryItem("Tất cả", Icons.grid_view),
                        _buildGridCategoryItem("Điện thoại", Icons.phone_android),
                        _buildGridCategoryItem("Laptop", Icons.laptop),
                        _buildGridCategoryItem("Đồng hồ", Icons.watch),
                        _buildGridCategoryItem("Phụ kiện", Icons.headphones),
                        _buildGridCategoryItem("Điện lạnh", Icons.ac_unit),
                        _buildGridCategoryItem("Tivi - Loa", Icons.tv),
                        _buildGridCategoryItem("Gia dụng", Icons.blender),
                        _buildGridCategoryItem("Tin học", Icons.computer),
                      ],
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // 7. KHU VỰC TIN TỨC & QUẢNG CÁO ĐẠI LÝ (ĐÃ SỬA TRÁNH TRÀN TRÊN MOBILE)
            // -----------------------------------------------------------------
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: isMobile
                    ? Column( // Xếp dọc tin tức trên Mobile
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("TIN TỨC XU HƯỚNG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                          const Divider(height: 20),
                          _buildNewsRow("Tiết kiệm điện năng cùng các dòng máy lạnh công nghệ mới", "26/05/2026", "https://picsum.photos/id/122/150/100"),
                          const SizedBox(height: 12),
                          _buildNewsRow("Top các dòng thiết bị tủ đông mini tiện lợi đáng cân nhắc", "25/05/2026", "https://picsum.photos/id/180/150/100"),
                        ],
                      ),
                    ),
                  ],
                )
                    : Row( // Giữ nguyên hàng ngang trên máy tính Web
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("TIN TỨC XU HƯỚNG", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                            const Divider(height: 24),
                            _buildNewsRow("Tiết kiệm điện năng cùng các dòng máy lạnh công nghệ mới năm nay", "26/05/2026", "https://picsum.photos/id/122/150/100"),
                            const SizedBox(height: 16),
                            _buildNewsRow("Top các dòng thiết bị tủ đông mini tiện lợi đáng cân nhắc cho gia đình", "25/05/2026", "https://picsum.photos/id/180/150/100"),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            color: Colors.white,
                            child: Image.network('https://picsum.photos/id/119/350/180', fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            color: Colors.white,
                            child: Image.network('https://picsum.photos/id/250/350/180', fit: BoxFit.cover),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // 8. SẢN PHẨM GỢI Ý HÔM NAY
            // -----------------------------------------------------------------
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        "Sản phẩm gợi ý hôm nay",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
                    ),
                    const SizedBox(height: 16),
                    suggestedProducts.isEmpty
                        ? const SizedBox(height: 100, child: Center(child: Text("Đang tải danh sách gợi ý...", textAlign: TextAlign.center)))
                        : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: suggestedProducts.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.72,
                      ),
                      itemBuilder: (context, index) {
                        final item = suggestedProducts[index];
                        return _buildProductCard(context, item, index + 5);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // -----------------------------------------------------------------
            // 9. CHÂN TRANG ĐẦY ĐỦ THÔNG TIN (ĐÃ SỬA CẤU TRÚC PHÙ HỢP CẢ MOBILE)
            // -----------------------------------------------------------------
            Container(
              color: const Color(0xFFF8F9FA),
              padding: EdgeInsets.symmetric(vertical: 40, horizontal: isMobile ? 20 : 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal, // Tự động xoay dòng thành cột trên Mobile
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isMobile ? 0 : 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("SmartChoice", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue, fontStyle: FontStyle.italic)),
                            const SizedBox(height: 12),
                            const Text("HỆ THỐNG DỮ LIỆU ĐỒ ÁN PHÂN TÍCH GIÁ TIÊU DÙNG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 8),
                            const Text("Ứng dụng phát triển trên nền tảng Flutter Cross-Platform.\nHỗ trợ tổng hợp thông tin, so sánh giá từ các nguồn đại lý thương mại điện tử công khai.", style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.5)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4), color: Colors.blueGrey,
                                  child: const Text("ACADEMIC PROJECT", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(4), color: Colors.green,
                                  child: const Text("SECURE VERIFIED", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            if (isMobile) const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: isMobile ? 0 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Hỗ trợ kỹ thuật", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 12),
                            _buildFooterLink("Hotline SV: 096.xxx.xxxx"),
                            _buildFooterLink("Email: support@student.edu.vn"),
                            _buildFooterLink("Điều khoản sử dụng mẫu"),
                            _buildFooterLink("Quy chế kiểm tra dữ liệu"),
                            if (isMobile) const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: isMobile ? 0 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Hợp tác đồ án", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                              onPressed: () {},
                              icon: const Icon(Icons.code, size: 16),
                              label: const Text("Xem mã nguồn liên kết", style: TextStyle(fontSize: 11)),
                            ),
                            const SizedBox(height: 16),
                            const Text("Kết nối cộng đồng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(Icons.cloud_queue, color: Colors.blue),
                                SizedBox(width: 12),
                                Icon(Icons.code_off, color: Colors.grey),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, dynamic item, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(product: item)));
      },
      child: Container(
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Center(child: Image.network(item.imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported)))),
            const SizedBox(height: 10),
            Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_formatPrice(item.lowestPrice)} đ",
                  style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text("-${(10 + index % 5 * 3)}%", style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.storefront, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.stores.isNotEmpty ? "${item.stores.first.shopName.toLowerCase()}.com" : "shop.vn",
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavButton(String name) {
    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = name;
          });
        },
        child: Text(name, style: TextStyle(fontSize: 13, color: _selectedCategory == name ? Colors.orange : Colors.black87, fontWeight: _selectedCategory == name ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  // ===========================================================================
  // 🔥 ĐÃ ĐƯỢC CHỈNH SỬA: BẤM VÀO ĐÂY SẼ CHUYỂN TRANG MỚI ĐỘC LẬP
  // ===========================================================================
  Widget _buildGridCategoryItem(String title, IconData icon) {
    return InkWell(
      onTap: () {
        // 🟢 THAY ĐỔI: Sử dụng Navigator để đẩy sang một trang danh mục riêng,
        // hoàn toàn không đụng chạm đến state hiện tại của HomeScreen.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryProductsScreen(categoryName: title),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100, // Sử dụng màu nền sạch sẽ, đồng bộ ổn định
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blueGrey, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsRow(String title, String date, String imgUrl) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(imgUrl, width: 100, height: 70, fit: BoxFit.cover)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(color: Colors.black54, fontSize: 12)),
    );
  }

  Widget _buildTimerBox(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
      child: Text(time, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
    );
  }
}
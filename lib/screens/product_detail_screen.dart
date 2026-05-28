import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product_model.dart';
import '../providers/api_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // 🟢 BỔ SUNG: Biến trạng thái theo dõi bộ lọc đang được chọn (mặc định là rẻ nhất)
  String _selectedFilter = 'rẻ nhất';

  // ===========================================================================
  // 🟢 PHẦN THÊM MỚI: KÍCH HOẠT LƯU LỊCH SỬ "ĐÃ XEM GẦN ĐÂY" NGAY KHI MỞ TRANG
  // ===========================================================================
  @override
  void initState() {
    super.initState();
    // Chờ giao diện dựng xong (PostFrame) sẽ nạp sản phẩm này vào lịch sử hệ thống
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ApiProvider>(context, listen: false).addViewedProduct(widget.product);
    });
  }

  // ===========================================================================
  // 🟢 PHẦN TỐI ƯU: TỰ ĐỘNG SỬA ĐỔI LINK VÀ DỰ PHÒNG CHẾ ĐỘ MỞ
  // ===========================================================================
  Future<void> _openStoreUrl(BuildContext context, String urlString, String shopName) async {
    // 1. Làm sạch khoảng trắng thừa
    String cleanUrl = urlString.trim();

    // 2. Bảo vệ: Nếu file JSON viết thiếu "https://", code sẽ tự bù vào để Chrome hiểu được
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }

    final Uri url = Uri.parse(cleanUrl);

    try {
      // Lượt 1: Thử ép buộc mở bằng ứng dụng Chrome ngoài độc lập
      bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);

      // Lượt 2: Nếu máy ảo chặn externalApplication, dùng chế độ mặc định của hệ thống
      if (!launched) {
        launched = await launchUrl(url, mode: LaunchMode.platformDefault);
      }

      if (!launched) throw Exception('Không thể khởi chạy liên kết');

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở liên kết của $shopName!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Hàm định dạng tiền tệ
  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.'
    );
  }

  // 🟢 BỔ SUNG: Hàm xử lý sắp xếp và lọc danh sách cửa hàng dựa theo bộ lọc được chọn
  List<StoreModel> _getFilteredStores(List<StoreModel> originalStores) {
    List<StoreModel> sortedList = List.from(originalStores);

    if (_selectedFilter == 'rẻ nhất') {
      // Sắp xếp giá tăng dần từ thấp đến cao
      sortedList.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedFilter == 'khuyến mãi') {
      // Giả lập logic Khuyến mãi bằng cách đảo ngược danh sách hoặc đẩy shop ngẫu nhiên lên đầu để thay đổi giao diện trực quan
      sortedList = sortedList.reversed.toList();
    }
    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    final apiProvider = Provider.of<ApiProvider>(context);

    // Tính khoảng giá dao động từ danh sách cửa hàng thực tế
    double minPrice = widget.product.price;
    double maxPrice = widget.product.price;
    if (widget.product.stores.isNotEmpty) {
      minPrice = widget.product.stores.map((s) => s.price).reduce((a, b) => a < b ? a : b);
      maxPrice = widget.product.stores.map((s) => s.price).reduce((a, b) => a > b ? a : b);
    }

    // 🟢 BỔ SUNG: Lấy danh sách cửa hàng đã áp dụng bộ lọc sắp xếp
    final displayStores = _getFilteredStores(widget.product.stores);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("So Sánh Giá Sản Phẩm", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF007FF0),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              widget.product.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.product.isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: () {
              apiProvider.toggleFavorite(widget.product.id);
            },
          )
        ],
      ),
      body: Column(
        children: [
          // -----------------------------------------------------------------
          // KHU VỰC THÔNG TIN TỔNG QUAN SẢN PHẨM
          // -----------------------------------------------------------------
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  height: 180,
                  padding: const EdgeInsets.all(8),
                  child: Image.network(
                    widget.product.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.product.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Giá từ: ${_formatPrice(minPrice)} đ  -  ${_formatPrice(maxPrice)} đ',
                  style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    const Text("4.8 (120 đánh giá)  |  ", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                      'Có ${widget.product.stores.length} nơi bán tương thích',
                      style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // -----------------------------------------------------------------
          // THANH LỌC / SẮP XẾP NHANH (ĐÃ KÍCH HOẠT NHẬN DIỆN CLICK TRẠNG THÁI)
          // -----------------------------------------------------------------
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Sắp xếp theo:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                Row(
                  children: [
                    // Nút Giá rẻ nhất
                    _buildSortBadge("Giá rẻ nhất", _selectedFilter == 'rẻ nhất', () {
                      setState(() {
                        _selectedFilter = 'rẻ nhất';
                      });
                    }),
                    const SizedBox(width: 8),
                    // Nút Khuyến mãi
                    _buildSortBadge("Khuyến mãi", _selectedFilter == 'khuyến mãi', () {
                      setState(() {
                        _selectedFilter = 'khuyến mãi';
                      });
                    }),
                  ],
                )
              ],
            ),
          ),

          // -----------------------------------------------------------------
          // DANH SÁCH CÁC CỬA HÀNG SO SÁNH GIÁ (ĐÃ ĐƯỢC THAY BẰNG DANH SÁCH ĐÃ LỌC)
          // -----------------------------------------------------------------
          Expanded(
            child: displayStores.isEmpty
                ? const Center(child: Text("Hiện tại chưa tìm thấy nơi bán nào cho sản phẩm này."))
                : ListView.builder(
              itemCount: displayStores.length,
              padding: const EdgeInsets.only(bottom: 16),
              itemBuilder: (context, index) {
                final store = displayStores[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.blue.shade50,
                        child: Text(store.logo, style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.shopName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                                  child: const Text("🎁 Quà tặng kèm", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 4),
                                const Text("FreeShip", style: TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_formatPrice(store.price)} đ',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[800],
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                elevation: 0,
                              ),
                              // Gọi hàm mở URL an toàn đã tối ưu
                              onPressed: () => _openStoreUrl(context, store.url, store.shopName),
                              child: const Text(
                                  'Đến nơi bán',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🟢 ĐÃ TỐI ƯU: Bổ sung thuộc tính VoidCallback onTap để nhận diện click
  Widget _buildSortBadge(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? Colors.blue : Colors.transparent),
        ),
        child: Text(
          text,
          style: TextStyle(color: isActive ? Colors.blue : Colors.black54, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }
}
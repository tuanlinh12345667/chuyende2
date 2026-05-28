import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_provider.dart';
import 'product_detail_screen.dart';

class CategoryProductsScreen extends StatelessWidget {
  final String categoryName;

  const CategoryProductsScreen({super.key, required this.categoryName});

  // Hàm định dạng tiền tệ
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

    // Lọc danh sách sản phẩm theo đúng danh mục được truyền sang
    final filteredProducts = rawProducts.where((product) {
      if (categoryName == "Tất cả") return true;
      return product.category.toLowerCase().contains(categoryName.toLowerCase()) ||
          categoryName.toLowerCase().contains(product.category.toLowerCase());
    }).toList();

    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 1200 ? 5 : (screenWidth > 800 ? 3 : 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: Text(
          "Danh mục: $categoryName",
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF007FF0),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: filteredProducts.isEmpty
          ? const Center(child: Text("Không có sản phẩm nào thuộc danh mục này!"))
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredProducts.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) {
          final item = filteredProducts[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductDetailScreen(product: item)),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_formatPrice(item.lowestPrice)} đ",
                        style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "-${(10 + index % 5 * 3)}%",
                        style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
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
        },
      ),
    );
  }
}
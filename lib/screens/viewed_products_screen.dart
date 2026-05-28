import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_provider.dart';
import 'product_detail_screen.dart';

class ViewedProductsScreen extends StatelessWidget {
  const ViewedProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiProvider = Provider.of<ApiProvider>(context);
    final viewedProducts = apiProvider.viewedProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm đã xem', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF007FF0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey[200],
      body: viewedProducts.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Bạn chưa xem sản phẩm nào', style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : ListView.builder(
        itemCount: viewedProducts.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final product = viewedProducts[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: Image.network(
                product.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
              ),
              title: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                '${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(product: product),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
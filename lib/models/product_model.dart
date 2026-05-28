class StoreModel {
  final String shopName;
  final double price;
  final String logo;
  final String url;

  StoreModel({
    required this.shopName,
    required this.price,
    required this.logo,
    required this.url,
  });

  // 🟢 BỔ SUNG: Hàm đọc dữ liệu JSON cho từng Cửa hàng
  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      shopName: json['shopName'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      logo: json['logo'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;
  bool isFavorite;
  final List<StoreModel> stores;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    this.isFavorite = false,
    required this.stores,
  });

  // 🟢 BỔ SUNG: Hàm đọc dữ liệu JSON cho Sản phẩm (Xoá bỏ lỗi gạch đỏ dòng 78)
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] ?? '',
      isFavorite: json['isFavorite'] ?? false,
      // Duyệt qua danh sách cửa hàng trong json để chuyển thành List<StoreModel>
      stores: (json['stores'] as List?)
          ?.map((store) => StoreModel.fromJson(store))
          .toList() ?? [],
    );
  }

  // ===========================================================================
  // 🔥 BỔ SUNG: GETTER TỰ ĐỘNG LẤY GIÁ THẤP NHẤT TỪ CÁC CỬA HÀNG ĐỂ HIỆN MÀN HÌNH CHÍNH
  // ===========================================================================
  double get lowestPrice {
    // Nếu không có danh sách shop hoặc danh sách rỗng, trả về giá gốc của sản phẩm
    if (stores.isEmpty) {
      return price;
    }

    // Giả định giá của shop đầu tiên là thấp nhất
    double minPrice = stores[0].price;

    // Duyệt qua các shop còn lại để so sánh và tìm giá nhỏ nhất thực tế
    for (var store in stores) {
      if (store.price < minPrice) {
        minPrice = store.price;
      }
    }
    return minPrice;
  }
}
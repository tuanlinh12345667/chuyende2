import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String _userName = "Hieu";
  int _points = 200;

  final List<String> _viewedIds = [];
  final List<String> _favoriteIds = [];
  final List<String> _claimedVoucherCodes = [];

  String get userName => _userName;
  int get points => _points;
  int get vouchersCount => 3 - _claimedVoucherCodes.length;
  List<String> get viewedIds => _viewedIds;
  List<String> get favoriteIds => _favoriteIds;
  List<String> get claimedVoucherCodes => _claimedVoucherCodes;

  void updateProfile(String newName) {
    _userName = newName;
    notifyListeners();
  }

  void claimVoucher(String code) {
    if (!_claimedVoucherCodes.contains(code)) {
      _claimedVoucherCodes.add(code);
      _points += 50;
      notifyListeners();
    }
  }

  void addToViewed(String id) {
    _viewedIds.remove(id);
    _viewedIds.insert(0, id);
    notifyListeners();
  }

  void toggleFavorite(String id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
  }

  bool isFavorite(String id) {
    return _favoriteIds.contains(id);
  }
}
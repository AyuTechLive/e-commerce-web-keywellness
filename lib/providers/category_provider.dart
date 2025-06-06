import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  CategoryProvider() {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('categories').get();
      _categories = snapshot.docs
          .map((doc) => Category.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error loading categories: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Category?> getCategory(String id) async {
    try {
      final doc = await _firestore.collection('categories').doc(id).get();
      if (doc.exists) {
        return Category.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      print('Error getting category: $e');
    }
    return null;
  }

  Future<void> refreshCategories() async {
    await _loadCategories();
  }
}

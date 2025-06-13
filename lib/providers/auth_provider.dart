// providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      await _loadUserModel();
    } else {
      _userModel = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserModel() async {
    if (_user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      print('Error loading user model: $e');
    }
  }

  Future<String?> signUp(
      String name, String email, String password, String phone) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final userModel = UserModel(
          id: credential.user!.uid,
          name: name,
          email: email,
          phone: phone,
          addresses: [], // Start with empty addresses list
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toMap());

        _userModel = userModel;
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateProfile(String name, String phone) async {
    if (_user == null || _userModel == null) return;

    try {
      final updatedUser = _userModel!.copyWith(
        name: name,
        phone: phone,
      );

      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .update(updatedUser.toMap());

      _userModel = updatedUser;
      notifyListeners();
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  // Address Management Methods
  Future<String?> addAddress(AddressModel address) async {
    if (_user == null || _userModel == null) return 'User not authenticated';

    try {
      List<AddressModel> updatedAddresses = List.from(_userModel!.addresses);

      // If this is the first address or marked as default, make it default
      if (updatedAddresses.isEmpty || address.isDefault) {
        // Remove default from other addresses
        updatedAddresses = updatedAddresses
            .map((addr) => addr.copyWith(isDefault: false))
            .toList();
      }

      updatedAddresses.add(address);

      final updatedUser = _userModel!.copyWith(addresses: updatedAddresses);

      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .update(updatedUser.toMap());

      _userModel = updatedUser;
      notifyListeners();
      return null;
    } catch (e) {
      print('Error adding address: $e');
      return e.toString();
    }
  }

  Future<String?> updateAddress(AddressModel address) async {
    if (_user == null || _userModel == null) return 'User not authenticated';

    try {
      List<AddressModel> updatedAddresses = _userModel!.addresses.map((addr) {
        if (addr.id == address.id) {
          return address;
        }
        // If this address is being set as default, remove default from others
        if (address.isDefault && addr.isDefault) {
          return addr.copyWith(isDefault: false);
        }
        return addr;
      }).toList();

      final updatedUser = _userModel!.copyWith(addresses: updatedAddresses);

      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .update(updatedUser.toMap());

      _userModel = updatedUser;
      notifyListeners();
      return null;
    } catch (e) {
      print('Error updating address: $e');
      return e.toString();
    }
  }

  Future<String?> deleteAddress(String addressId) async {
    if (_user == null || _userModel == null) return 'User not authenticated';

    try {
      List<AddressModel> updatedAddresses =
          _userModel!.addresses.where((addr) => addr.id != addressId).toList();

      // If we deleted the default address and there are other addresses,
      // make the first one default
      if (updatedAddresses.isNotEmpty &&
          !updatedAddresses.any((addr) => addr.isDefault)) {
        updatedAddresses[0] = updatedAddresses[0].copyWith(isDefault: true);
      }

      final updatedUser = _userModel!.copyWith(addresses: updatedAddresses);

      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .update(updatedUser.toMap());

      _userModel = updatedUser;
      notifyListeners();
      return null;
    } catch (e) {
      print('Error deleting address: $e');
      return e.toString();
    }
  }

  Future<String?> setDefaultAddress(String addressId) async {
    if (_user == null || _userModel == null) return 'User not authenticated';

    try {
      List<AddressModel> updatedAddresses = _userModel!.addresses.map((addr) {
        return addr.copyWith(isDefault: addr.id == addressId);
      }).toList();

      final updatedUser = _userModel!.copyWith(addresses: updatedAddresses);

      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .update(updatedUser.toMap());

      _userModel = updatedUser;
      notifyListeners();
      return null;
    } catch (e) {
      print('Error setting default address: $e');
      return e.toString();
    }
  }
}

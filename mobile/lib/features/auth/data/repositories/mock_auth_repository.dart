import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  static const String _boxName = 'auth_box';
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  @override
  Future<void> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Simple validation "Mock"
    if (password.length < 6) {
      throw Exception('Şifre en az 6 karakter olmalıdır.');
    }

    // "Login Successful" - Save dummy token
    final box = await _getBox();
    await box.put(_tokenKey, 'dummy_token_${DateTime.now().millisecondsSinceEpoch}');
    await box.put(_userIdKey, 'user_123'); // Mock User ID
  }

  @override
  Future<void> register(String email, String password, String fullName) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (password.length < 6) {
      throw Exception('Şifre en az 6 karakter olmalıdır.');
    }

    // "Register & Login Successful"
    final box = await _getBox();
    await box.put(_tokenKey, 'dummy_token_${DateTime.now().millisecondsSinceEpoch}');
    await box.put(_userIdKey, 'user_123');
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final box = await _getBox();
    await box.delete(_tokenKey);
    await box.delete(_userIdKey);
  }

  @override
  Future<bool> isAuthenticated() async {
    final box = await _getBox();
    return box.containsKey(_tokenKey);
  }
  
  @override
  Future<String?> getCurrentUserId() async {
      final box = await _getBox();
      return box.get(_userIdKey);
  }
}

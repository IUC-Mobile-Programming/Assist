import 'package:flutter/foundation.dart';

/// Base ViewModel that centralizes loading and error state handling.
class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<T> runAsync<T>(Future<T> Function() work) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      return await work();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

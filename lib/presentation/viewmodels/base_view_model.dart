import 'package:flutter/foundation.dart';

class BaseViewModel extends ChangeNotifier {
  bool _isBusy = false;
  String? _error;

  bool get isBusy => _isBusy;
  String? get error => _error;

  void setBusy(bool v) {
    _isBusy = v;
    notifyListeners();
  }

  void setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}


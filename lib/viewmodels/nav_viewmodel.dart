import 'package:flutter/foundation.dart';

/// Bottom-navigation index, shared so any screen can switch tabs.
class NavViewModel extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void setIndex(int i) {
    if (i == _index) return;
    _index = i;
    notifyListeners();
  }

  void reset() {
    _index = 0;
    notifyListeners();
  }
}

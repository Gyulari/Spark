import 'package:spark/app_import.dart';

class NavState extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}

class FocusLotState extends ChangeNotifier {
  ParkingLot? _focusLot;
  ParkingLot? get focusLot => _focusLot;

  void setFocusLot(ParkingLot lot) {
    _focusLot = lot;
    notifyListeners();
  }

  void clear() {
    _focusLot = null;
    notifyListeners();
  }
}
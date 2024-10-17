import 'package:flutter/material.dart';

class EventFilterProvider with ChangeNotifier {
  String? _selectedEventType;
  String? get selectedEventType => _selectedEventType;

  void setEventType(String? eventType) {
    _selectedEventType = eventType;
    notifyListeners();
  }
}
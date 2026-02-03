import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  // Default warna: Indigo
  MaterialColor _primaryColor = Colors.indigo;

  MaterialColor get primaryColor => _primaryColor;

  // Load warna saat aplikasi dibuka
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    int? colorValue = prefs.getInt('theme_color');

    if (colorValue != null) {
      // Cari MaterialColor yang cocok (Logic sederhana)
      if (colorValue == Colors.red.value) _primaryColor = Colors.red;
      else if (colorValue == Colors.green.value) _primaryColor = Colors.green;
      else if (colorValue == Colors.orange.value) _primaryColor = Colors.orange;
      else if (colorValue == Colors.purple.value) _primaryColor = Colors.purple;
      else if (colorValue == Colors.teal.value) _primaryColor = Colors.teal;
      else _primaryColor = Colors.indigo;

      notifyListeners();
    }
  }

  // Ganti warna dan simpan
  Future<void> changeTheme(MaterialColor newColor) async {
    _primaryColor = newColor;
    notifyListeners(); // Kabari seluruh aplikasi untuk ganti baju

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_color', newColor.value);
  }
}
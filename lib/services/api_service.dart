import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // URL API Gratisan (ZenQuotes)
  final String baseUrl = "https://zenquotes.io/api/random";

  Future<String> getMotivationalQuote() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        // Parsing JSON
        List<dynamic> data = jsonDecode(response.body);
        // Format: "Kata Mutiara - Oleh Siapa"
        return "\"${data[0]['q']}\" — ${data[0]['a']}";
      } else {
        return "Stay productive and focused!"; // Default kalau error
      }
    } catch (e) {
      return "Believe in yourself!"; // Default kalau tidak ada internet
    }
  }
}
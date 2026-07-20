import 'dart:convert';
import 'package:http/http.dart' as http;

class FoodImageService {
  static const _baseUrl = 'https://foodish-api.com/api/images/burger';

  Future<String?> fetchBurgerPhoto() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl)).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final url = decoded['image'] as String?;
      if (url == null || url.isEmpty) return null;
      return url;
    } catch (_) {
      return null;
    }
  }
}
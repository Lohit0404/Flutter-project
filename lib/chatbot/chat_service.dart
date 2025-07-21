import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String apiUrl = 'http://172.20.10.7:8000/chat'; // <-- your PC's IP

  static Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] ?? "No response";
      } else {
        return "Server error: ${response.statusCode}";
      }
    } catch (e) {
      return "Failed to connect to server.";
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  // Read API key from .env file manually since we can't depend on flutter_dotenv in a raw script easily without setup
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print("Error: .env file not found");
    return;
  }
  
  String apiKey = "";
  final lines = await envFile.readAsLines();
  for (var line in lines) {
    if (line.startsWith("GEMINI_API_KEY=")) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }

  if (apiKey.isEmpty) {
    print("Error: GEMINI_API_KEY not found in .env");
    return;
  }

  print("Using API Key: ${apiKey.substring(0, 5)}...");

  final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey");
  
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final sink = File('valid_models.txt').openWrite();
      for (var model in json['models']) {
        if (model['supportedGenerationMethods'].contains('generateContent')) {
          sink.writeln("- ${model['name']}");
        }
      }
      await sink.close();
      print("Wrote models to valid_models.txt");
    } else {
      print("Error fetching models: ${response.statusCode}");
      print(response.body);
    }
  } catch (e) {
    print("Exception: $e");
  }
}

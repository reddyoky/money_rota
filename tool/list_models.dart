import 'dart:io';
import 'dart:convert';

void main() async {
  // New API Key provided by user
  var apiKey = "AIzaSyAoRxtuAI7J5uIPTPDS4z6nUApOHkaqiyw"; 
  var url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  var client = HttpClient();
  try {
    var request = await client.getUrl(url);
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    
    var json = jsonDecode(responseBody);
    if (json['models'] != null) {
      var file = File('models_new_key.txt');
      var sink = file.openWrite();
      for (var m in json['models']) {
        sink.writeln(m['name']);
      }
      await sink.close();
      print("Wrote models to models_new_key.txt");
    } else {
      print("No models found or error: $responseBody");
    }
  } catch (e) {
    print("Error: $e");
  } finally {
    client.close();
  }
}

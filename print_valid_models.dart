import 'dart:io';

void main() {
  final file = File('valid_models.txt');
  if (file.existsSync()) {
    final lines = file.readAsLinesSync();
    print("--- VALID MODELS START ---");
    for (var line in lines) {
      if (line.trim().isNotEmpty) {
        print(line);
      }
    }
    print("--- VALID MODELS END ---");
  } else {
    print("File not found");
  }
}

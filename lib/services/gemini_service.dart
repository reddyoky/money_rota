import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/debt_model.dart';

class GeminiService {

  static String get _apiKey {
    if (!dotenv.isInitialized) return "";
    return dotenv.env['GEMINI_API_KEY'] ?? ""; 
  }
  
  late final GenerativeModel? _model;
  late final ChatSession? _chat;

  GeminiService() {
    if (_apiKey.isNotEmpty) {
      _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
      _chat = _model?.startChat();
    } else {
      _model = null;
      _chat = null;
    }
  }


  Future<String> explainDebtOrder(List<Debt> debts) async {
    try {
      if (_chat == null) return "API Anahtarı eksik. Ayarları kontrol et.";
      if (debts.isEmpty) return "Henüz borç eklenmemiş.";
      
      String debtSummary = debts.map((d) => 
        "- ${d.name}: ${d.currentBalance.toStringAsFixed(0)} TL, Faiz: %${d.interestRate}"
      ).join("\n");

      final prompt = """
      Sen bir finansal danışmansın. Aşağıdaki borçları "Çığ Yöntemi"ne (Yüksek faiz öncelikli) göre analiz et.
      Neden bu sırayla ödenmesi gerektiğini 2 kısa cümleyle, motive edici şekilde açıkla.
      
      Borçlar:
      $debtSummary
      """;

      final content = Content.text(prompt);
      final response = await _chat!.sendMessage(content);
      return response.text ?? "Analiz yapılamadı.";
    } catch (e) {
      print("🛑 GEMINI ANALİZ HATASI: $e");
      return "Bağlantı sorunu var. İnternetini kontrol et.";
    }
  }


  Future<String> getMotivationMessage(String debtName, int paidCount, int totalCount) async {
    try {
      if (_chat == null) return "Harika gidiyorsun! 🚀";
      
      final prompt = "Kullanıcı '$debtName' borcunun bir taksidini ödedi ($paidCount/$totalCount). Ona çok kısa (tek cümle), emojili ve motive edici bir tebrik mesajı yaz.";
      final content = Content.text(prompt);
      final response = await _chat!.sendMessage(content);
      return response.text ?? "Harika gidiyorsun! 🚀";
    } catch (e) {
      print("🛑 GEMINI MOTİVASYON HATASI: $e");
      return "Tebrikler! Bir adım daha bitti. 🎉";
    }
  }
}

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/debt_model.dart';

class GeminiService {

  static String get _apiKey {
    if (!dotenv.isInitialized) return "";
    return dotenv.env['GEMINI_API_KEY'] ?? ""; 
  }
  
  static const String _baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent";

  Future<String> explainDebtOrder(List<Debt> debts) async {
    try {
      if (_apiKey.isEmpty) return "API Anahtarı eksik. Ayarları kontrol et.";
      if (debts.isEmpty) return "Henüz borç eklenmemiş.";
      
      final now = DateTime.now();
      
      List<String> criticalDebts = [];
      List<String> normalDebts = [];

      for (var d in debts) {
        String minPaymentInfo = "";
        if (d.limit != null && d.limit! > 0) {
          double ratio = d.limit! > 50000 ? 0.40 : 0.20;
          double minPayment = d.currentBalance * ratio;
          minPaymentInfo = "(Asgari: ${minPayment.toStringAsFixed(0)} TL)";
        }

        String riskStatus = "";
        bool isCritical = false;
        
        if (d.lastPaymentDate != null) {
          final lastPay = DateTime.fromMillisecondsSinceEpoch(d.lastPaymentDate!);
          final daysSince = now.difference(lastPay).inDays;
          
          if (daysSince > 90) {
             riskStatus = "⚠️ YASAL TAKİPTE (AVUKATLIK)!";
             isCritical = true;
          } else if (daysSince > 60) {
             riskStatus = "🔴 KIRMIZI ALARM! (${90 - daysSince} gün kaldı)";
             isCritical = true;
          } else if (daysSince > 30) {
             riskStatus = "🟠 GECİKMEDE";
          }
        }
        
        String line = "- ${d.name}: ${d.currentBalance.toStringAsFixed(0)} TL, Faiz: %${d.interestRate} $minPaymentInfo $riskStatus";
        
        if (isCritical) {
          criticalDebts.add(line);
        } else {
          normalDebts.add(line);
        }
      }

      String criticalSection = criticalDebts.isEmpty 
          ? "Yok." 
          : criticalDebts.join("\n");
          
      String normalSection = normalDebts.join("\n");

      final promptText = """
      Sen katı prensipli, BDDK kurallarını bilen bir Türk finans uzmanısın.
      
      ACİL DURUM RAPORU (BU LİSTEDEKİLERİ MUTLAKA İLK SIRAYA AL):
      $criticalSection
      
      DİĞER BORÇLAR:
      $normalSection
      
      GÖREVİN:
      1. Eğer 'ACİL DURUM RAPORU' kısmında borç varsa, LİSTENİN EN BAŞINA bunları koy. Faiz oranlarına bakma. Kullanıcıyı "Yasal takip riskin var, hemen bunları öde!" diye uyar.
      2. Sonra 'DİĞER BORÇLAR' kısmındaki borçları "Çığ Yöntemi"ne (En Yüksek Faiz) göre sırala.
      
      BDDK Kuralı: Kredi kartı limiti 50.000 TL altıysa asgari %20, üstüyse %40'tır.
      
      Analizini kısa, net ve eylem odaklı yap.
      """;

      final response = await _sendRequest(promptText);
      return response ?? "Analiz yapılamadı.";
    } catch (e) {
      print("🛑 GEMINI REST HATASI: $e");
      return "Bağlantı sorunu var: $e";
    }
  }

  Future<String> getMotivationMessage(String debtName, int paidCount, int totalCount) async {
    try {
      if (_apiKey.isEmpty) return "Harika gidiyorsun! 🚀";
      
      final promptText = "Kullanıcı '$debtName' borcunun bir taksidini ödedi ($paidCount/$totalCount). Ona çok kısa (tek cümle), emojili ve motive edici bir tebrik mesajı yaz.";
      
      final response = await _sendRequest(promptText);
      return response ?? "Harika gidiyorsun! 🚀";
    } catch (e) {
      print("🛑 GEMINI MOTİVASYON HATASI: $e");
      return "Tebrikler! Bir adım daha bitti. 🎉";
    }
  }

  Future<String?> _sendRequest(String prompt) async {
    final url = Uri.parse("$_baseUrl?key=$_apiKey");
    
    final body = jsonEncode({
      "contents": [{
        "parts": [{"text": prompt}]
      }]
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['candidates'] != null && 
          (json['candidates'] as List).isNotEmpty &&
          json['candidates'][0]['content'] != null &&
          json['candidates'][0]['content']['parts'] != null &&
          (json['candidates'][0]['content']['parts'] as List).isNotEmpty) {
            
        final text = json['candidates'][0]['content']['parts'][0]['text'];
        return text;
      }
    } else {
       print("API Error: ${response.statusCode} - ${response.body}");
       try {
         final errorJson = jsonDecode(response.body);
         return "Hata: ${errorJson['error']['message']}";
       } catch (_) {
         return "API Hatası: ${response.statusCode}";
       }
    }
    return null;
  }
}

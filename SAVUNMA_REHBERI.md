# 🛡️ Kod Savunma Rehberi (Yapay Zeka İzleri Temizlendi)

Hocanızın sorabileceği kod bloklarının **yorum satırsız, yalın halleri** aşağıdadır. Sınavda kodu aynen bu şekilde yazmalısınız. Açıklamalar kodun altında yer alır.

---

## 1. Veri Modeli (`debt_model.dart`)

**Soru:** "Veritabanından gelen veriyi nesneye çeviren `fromMap` metodunu yaz."

```dart
factory Debt.fromMap(Map<String, dynamic> map, String documentId) {
  return Debt(
    id: documentId,
    userId: map['userId'] ?? '',
    name: map['name'] ?? '',
    initialPrincipal: (map['initialPrincipal'] ?? 0).toDouble(),
    currentBalance: (map['currentBalance'] ?? 0).toDouble(),
    interestRate: (map['interestRate'] ?? 0).toDouble(),
    termMonths: map['termMonths'] ?? 0,
    monthlyPayment: (map['monthlyPayment'] ?? 0).toDouble(),
    paymentDay: map['paymentDay'] ?? 1,
    installmentsPaid: map['installmentsPaid'] ?? 0,
    startDate: map['startDate'] ?? DateTime.now().millisecondsSinceEpoch,
    totalLateFees: (map['totalLateFees'] ?? 0).toDouble(),
    limit: map['limit']?.toDouble(),
    lastPaymentDate: map['lastPaymentDate'],
  );
}
```

**Satır Satır Ezber Mantığı:**
1.  `factory` kelimesiyle başla.
2.  `map['alan_adi']` ile veriyi al.
3.  `?? 0` veya `?? ''` ile boş gelirse patlamamasını sağla.
4.  `.toDouble()` ile sayıları ondalıklıya çevir.

---

## 2. Ana Ekran Veri Çekme (`dashboard_screen.dart`)

**Soru:** "Servis kullanmadan direkt `StreamBuilder` ile veriyi nasıl çektiğini yaz."

```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('debts')
      .where('userId', isEqualTo: uid)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final allDebts = snapshot.data!.docs
        .map((d) => Debt.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();

    return SingleChildScrollView(
      child: Column(children: []),
    );
  },
)
```

**Açıklama:**
-   `FirebaseFirestore.instance` ile veritabanına ulaş.
-   `.collection('debts')` ile tabloyu seç.
-   `.where` ile sadece giriş yapan kullanıcının verisini al.
-   `snapshots()` ile canlı yayın (stream) başlat.

---

## 3. Borç Ekleme İşlemi (`add_debt_screen.dart`)

**Soru:** "Kaydet butonuna basınca çalışan `_save` fonksiyonunu veritabanı koduyla yaz."

```dart
Future<void> _save() async {
  if (_monthlyPayment == 0 || _nameCtrl.text.isEmpty) return;
  setState(() => _loading = true);

  // ... (Tarih Hesaplama Kısımları) ...

  final debt = Debt(
    id: '',
    userId: FirebaseAuth.instance.currentUser!.uid,
    name: _nameCtrl.text,
    initialPrincipal: double.parse(_principalCtrl.text),
    currentBalance: _totalDebt, 
    interestRate: double.parse(_rateCtrl.text),
    termMonths: int.parse(_termCtrl.text),
    monthlyPayment: _monthlyPayment,
    paymentDay: day,
    installmentsPaid: paid,
    startDate: calculatedStartDate.millisecondsSinceEpoch,
    limit: double.tryParse(_limitCtrl.text),
    lastPaymentDate: _lastPaymentDate?.millisecondsSinceEpoch,
  );

  await FirebaseFirestore.instance.collection('debts').add(debt.toMap());
  if (mounted) Navigator.pop(context);
}
```

**Açıklama:**
-   `FirebaseAuth` ile kullanıcı ID'sini al (`currentUser!.uid`).
-   Formdan gelenleri `name: _nameCtrl.text` gibi nesneye doldur.
-   En kritik satır: `collection('debts').add(debt.toMap())` -> Veritabanına JSON olarak atar.

---

## 4. Yapay Zeka İstegi (`gemini_service.dart`)

**Soru:** "HTTP paketi ile API'ye nasıl istek atıyorsun?"

```dart
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
    return json['candidates'][0]['content']['parts'][0]['text'];
  }
  return null;
}
```

**Açıklama:**
-   `Uri.parse` ile linki hazırla.
-   `jsonEncode` ile body kısmını standart formata çevir.
-   `http.post` ile isteği gönder.
-   `response.statusCode == 200` ise başarılıdır, cevabı `jsonDecode` ile parçala.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/debt_model.dart';

class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _nameCtrl = TextEditingController();
  final _principalCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _termCtrl = TextEditingController();
  final _paidCountCtrl = TextEditingController(text: "0");
  final _dayCtrl = TextEditingController(text: DateTime.now().day.toString());
  final _limitCtrl = TextEditingController();
  DateTime? _lastPaymentDate;

  double _monthlyPayment = 0;
  double _totalDebt = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _principalCtrl.addListener(_calculate);
    _rateCtrl.addListener(_calculate);
    _termCtrl.addListener(_calculate);
    _paidCountCtrl.addListener(_calculate);
  }

  void _calculate() {
    double p = double.tryParse(_principalCtrl.text) ?? 0;
    double r = double.tryParse(_rateCtrl.text) ?? 0;
    int n = int.tryParse(_termCtrl.text) ?? 0;
    int paid = int.tryParse(_paidCountCtrl.text) ?? 0;

    if (p > 0 && n > 0) {
      if (r == 0) {
        setState(() {
          _monthlyPayment = p / n;
          
          _totalDebt = p - (_monthlyPayment * paid);
        });
      } else {
        double rate = r / 100;
        double x = pow(1 + rate, n).toDouble();
        setState(() {
          _monthlyPayment = p * (rate * x) / (x - 1);
           
          _totalDebt = (_monthlyPayment * n) - (_monthlyPayment * paid); 
        });
      }
      if (_totalDebt < 0) _totalDebt = 0;
    }
  }

  Future<void> _save() async {
    if (_monthlyPayment == 0 || _nameCtrl.text.isEmpty) return;
    setState(() => _loading = true);

    int paid = int.tryParse(_paidCountCtrl.text) ?? 0;
    int day = int.tryParse(_dayCtrl.text) ?? 1;
    if (day < 1) day = 1;
    if (day > 31) day = 31;
    
    _calculate();

    DateTime now = DateTime.now();
    DateTime nextPaymentDate;
    
    if (now.day <= day) {
      nextPaymentDate = DateTime(now.year, now.month, day);
    } else {
      nextPaymentDate = DateTime(now.year, now.month + 1, day);
    }

    DateTime calculatedStartDate = DateTime(
      nextPaymentDate.year, 
      nextPaymentDate.month - paid, 
      nextPaymentDate.day
    );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Yeni Borç"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _input("Borç Adı (Örn: İhtiyaç Kredisi)", _nameCtrl),
            const SizedBox(height: 16),
            _input("Çekilen Tutar (Ana Para)", _principalCtrl, isNumber: true),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _input("Faiz Oranı (%)", _rateCtrl, isNumber: true),
                ),
                const SizedBox(width: 16),
                Expanded(child: _input("Vade (Ay)", _termCtrl, isNumber: true)),
              ],
            ),
            const SizedBox(height: 16),
            _input("Kart Limiti (Opsiyonel - Kredi Kartıysa)", _limitCtrl, isNumber: true),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _lastPaymentDate = date);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).cardColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _lastPaymentDate == null
                          ? "En Son Ödeme Tarihi (Opsiyonel)"
                          : DateFormat('dd.MM.yyyy').format(_lastPaymentDate!),
                      style: TextStyle(
                        color: _lastPaymentDate == null
                            ? Theme.of(context).hintColor
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
             Row(
              children: [
                 Expanded(
                  child: _input("Taksit Günü (1-31)", _dayCtrl, isNumber: true),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _input("Ödenmiş Taksit", _paidCountCtrl, isNumber: true),
                ),
              ],
            ),

            const SizedBox(height: 30),

            if (_monthlyPayment > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Aylık Taksit:"),
                        Text(
                          NumberFormat.currency(
                            symbol: '₺',
                          ).format(_monthlyPayment),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Kalan Toplam Borç:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          NumberFormat.currency(symbol: '₺').format(_totalDebt),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                     if ((int.tryParse(_paidCountCtrl.text) ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "(${_paidCountCtrl.text} taksit ödenmiş olarak hesaplandı)",
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "KAYDET",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(
    String hint,
    TextEditingController ctrl, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
    );
  }
}

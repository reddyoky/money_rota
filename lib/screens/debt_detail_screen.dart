import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/debt_model.dart';
import '../services/gemini_service.dart';

class DebtDetailScreen extends StatefulWidget {
  final String debtId;

  const DebtDetailScreen({super.key, required this.debtId});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  final GeminiService _geminiService = GeminiService();
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');


  Future<void> _toggleInstallment(Debt debt, int index, bool isPaying) async {
    int newPaidCount = debt.installmentsPaid;

    if (isPaying) {
      if (index != debt.installmentsPaid) return;
      newPaidCount++;
    } else {
      if (index != debt.installmentsPaid - 1) return;
      newPaidCount--;
    }

    double totalRepayment = debt.monthlyPayment * debt.termMonths;
    double newBalance = totalRepayment - (debt.monthlyPayment * newPaidCount);
    if (newBalance < 0) newBalance = 0;

    
    double addedFee = 0;
    if (isPaying) {
      DateTime startDate = DateTime.fromMillisecondsSinceEpoch(debt.startDate);
      DateTime installmentDate = DateTime(startDate.year, startDate.month + index, startDate.day);
      
      
      
      if (DateTime.now().isAfter(installmentDate.add(const Duration(days: 1)))) {
        addedFee = await _askForLateFee(installmentDate);
      }
    }

    await FirebaseFirestore.instance.collection('debts').doc(debt.id).update({
      'installmentsPaid': newPaidCount,
      'currentBalance': newBalance,
      'totalLateFees': FieldValue.increment(addedFee), 
    });

    if (isPaying && mounted) {
      _showMotivation(debt.name, newPaidCount, debt.termMonths);
    }
  }

  Future<double> _askForLateFee(DateTime dueDate) async {
    if (!mounted) return 0;
    final dateStr = DateFormat("d MMM").format(dueDate);
    
    
    final controller = TextEditingController();
    
    return await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Geç Ödeme Tespit Edildi ($dateStr)"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Bu taksit için herhangi bir gecikme faizi / ceza ödediniz mi?"),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Ekstra Ödenen Tutar (Varsa)",
                hintText: "0",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 0.0),
            child: const Text("Hayır, Ek Ücret Yok"),
          ),
          ElevatedButton(
            onPressed: () {
              double val = double.tryParse(controller.text) ?? 0;
              Navigator.pop(context, val);
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    ) ?? 0;
  }

  void _showMotivation(String debtName, int paidCount, int totalCount) async {
    
    final message = await _geminiService.getMotivationMessage(
      debtName,
      paidCount,
      totalCount,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Borcu Sil"),
        content: const Text("Bu kaydı kalıcı olarak silmek istiyor musun?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('debts')
                  .doc(widget.debtId)
                  .delete();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text("Sil", style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Borç Detayı",
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Theme.of(context).colorScheme.onSurface),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('debts')
            .doc(widget.debtId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text("Bir hata oluştu"));
          if (!snapshot.hasData || !snapshot.data!.exists)
            return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final debt = Debt.fromMap(data, snapshot.data!.id);

          DateTime startDate = DateTime.fromMillisecondsSinceEpoch(
            debt.startDate,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        debt.name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Kalan Bakiye",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(debt.currentBalance),
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      LinearProgressIndicator(
                        value: debt.termMonths == 0
                            ? 0
                            : debt.installmentsPaid / debt.termMonths,
                        backgroundColor: AppColors.background,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.secondary,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${debt.installmentsPaid} / ${debt.termMonths} Taksit Ödendi",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "ÖDEME PLANI",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
                const SizedBox(height: 15),


                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: debt.termMonths,
                  itemBuilder: (context, index) {

                    DateTime installmentDate = DateTime(
                      startDate.year,
                      startDate.month + index,
                      startDate.day,
                    );
                    String dateStr = DateFormat(
                      "d MMMM yyyy",
                      "tr_TR",
                    ).format(installmentDate);

                    bool isPaid = index < debt.installmentsPaid;
                    bool isNext =
                        index ==
                        debt.installmentsPaid;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: isNext
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [

                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? AppColors.secondary.withOpacity(0.1)
                                  : Theme.of(context).dividerColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPaid
                                    ? AppColors.secondary
                                    : AppColors.textGrey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateStr,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  _currencyFormat.format(debt.monthlyPayment),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          InkWell(
                            onTap: () {
                              if (isNext)
                                _toggleInstallment(debt, index, true);
                              else if (isPaid &&
                                  index == debt.installmentsPaid - 1)
                                _toggleInstallment(
                                  debt,
                                  index,
                                  false,
                                );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? AppColors.secondary
                                    : (isNext
                                          ? AppColors.primary
                                          : Colors.transparent),
                                shape: BoxShape.circle,
                                border: isPaid || isNext
                                    ? null
                                    : Border.all(color: Colors.grey.shade300),
                              ),
                              child: Icon(
                                isPaid
                                    ? Icons.check
                                    : (isNext
                                          ? Icons.touch_app
                                          : Icons.circle_outlined),
                                color: isPaid || isNext
                                    ? Colors.white
                                    : Colors.grey.shade300,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

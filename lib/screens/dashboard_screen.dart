import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../core/app_colors.dart';
import '../models/debt_model.dart';
import '../services/gemini_service.dart';
import 'add_debt_screen.dart';
import 'debt_detail_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GeminiService _geminiService = GeminiService();
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  void _showGeminiAnalysis(List<Debt> debts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  "Finansal Asistan",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<String>(
              future: _geminiService.explainDebtOrder(debts),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Text(
                  snapshot.data ?? "Hata oluştu.",
                  style: GoogleFonts.inter(fontSize: 15, height: 1.5),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 10),
            Text(
              "Money Rota",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: Theme.of(context).colorScheme.primary, size: 28),
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('debts')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final allDebts = snapshot.data!.docs
              .map((d) => Debt.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList();

          final activeDebts = allDebts.where((d) => d.currentBalance > 0).toList();
          final completedDebts = allDebts.where((d) => d.currentBalance <= 0).toList();
          activeDebts.sort((a, b) => b.interestRate.compareTo(a.interestRate));

          double totalDebt = activeDebts.fold(0, (sum, item) => sum + item.currentBalance);
          double totalPaid = allDebts.fold(0, (sum, item) => sum + (item.monthlyPayment * item.installmentsPaid));
          double grandTotal = totalDebt + totalPaid;
          double percent = grandTotal == 0 ? 0 : totalPaid / grandTotal;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary,
                        AppColors.secondary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TOPLAM BORÇ",
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currencyFormat.format(totalDebt),
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => _showGeminiAnalysis(activeDebts),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Neden bu sıra?",
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      CircularPercentIndicator(
                        radius: 40,
                        lineWidth: 8,
                        percent: percent > 1 ? 1 : percent,
                        center: Text(
                          "%${(percent * 100).toStringAsFixed(0)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        progressColor: Colors.white,
                        backgroundColor: Colors.white24,
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                
                Text(
                  "ÖDEMELER",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 10),

                if (activeDebts.isEmpty)
                   Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: Text("Aktif borcunuz bulunmuyor. Harika!", style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeDebts.length,
                    itemBuilder: (context, index) {
                      final debt = activeDebts[index];
                      final isPriority = index < 2; 

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: isPriority
                              ? BorderSide(color: AppColors.secondary, width: 2)
                              : BorderSide.none,
                        ),
                        child: ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (c) => DebtDetailScreen(debtId: debt.id)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: isPriority
                                ? AppColors.secondary.withOpacity(0.2)
                                : Theme.of(context).dividerColor.withOpacity(0.1),
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(
                                color: isPriority ? AppColors.secondary : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                debt.name,
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                              ),
                              if (isPriority) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "Öncelikli",
                                    style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                )
                              ]
                            ],
                          ),
                          subtitle: Text(
                            "%${debt.interestRate} Faiz Oranı",
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            _currencyFormat.format(debt.monthlyPayment),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                if (completedDebts.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  Text(
                    "KAPATILAN BORÇLAR",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: completedDebts.length,
                    itemBuilder: (context, index) {
                      final debt = completedDebts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Theme.of(context).cardColor.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (c) => DebtDetailScreen(debtId: debt.id)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.check, color: Colors.white),
                          ),
                          title: Text(
                            debt.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold, 
                              decoration: TextDecoration.lineThrough,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                          subtitle: const Text(
                            "Tamamlandı",
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          ),
                          trailing: const Text("🎉", style: TextStyle(fontSize: 20)),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const AddDebtScreen()),
        ),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

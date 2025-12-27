class Debt {
  final String id;
  final String userId;
  final String name;
  final double initialPrincipal;
  final double currentBalance;
  final double interestRate;
  final int termMonths;
  final double monthlyPayment;
  final int paymentDay;
  final int installmentsPaid;
  final int startDate;
  final double totalLateFees;

  Debt({
    required this.id,
    required this.userId,
    required this.name,
    required this.initialPrincipal,
    required this.currentBalance,
    required this.interestRate,
    required this.termMonths,
    required this.monthlyPayment,
    required this.paymentDay,
    required this.installmentsPaid,
    required this.startDate,
    this.totalLateFees = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'initialPrincipal': initialPrincipal,
      'currentBalance': currentBalance,
      'interestRate': interestRate,
      'termMonths': termMonths,
      'monthlyPayment': monthlyPayment,
      'paymentDay': paymentDay,
      'installmentsPaid': installmentsPaid,
      'startDate': startDate,
      'totalLateFees': totalLateFees,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

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
    );
  }
}
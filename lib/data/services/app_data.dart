import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/accounts/account.dart';
import '../../features/accounts/currency.dart';
import '../../features/accounts/investment_account.dart';
import '../../features/accounts/transaction_entry.dart';

enum Period { day, week, month, year, threeYears, all }

/// ใช้เป็นค่า default ของพารามิเตอร์ note/satisfaction ใน updateTransaction
/// เพื่อแยกให้ออกว่า "ไม่ได้ส่งค่ามา (ไม่แก้ไข)" กับ "ส่ง null มาตั้งใจล้างค่า"
const Object _unset = Object();

/// ปัดเศษจำนวนเงินให้เหลือทศนิยม 2 ตำแหน่งเสมอ
/// ใช้ทุกครั้งก่อนคำนวณ/บันทึกยอดเงิน เพื่อกันปัญหาจุดทศนิยมเพี้ยนสะสม
/// (เช่น 0.1 + 0.2 ที่คอมพิวเตอร์อาจได้ 0.30000000000000004)
double round2(double value) => (value * 100).round() / 100;

/// อัตราแลกเปลี่ยนเริ่มต้น
/// จำนวนบาทต่อ 1 หน่วยของสกุลเงินนั้น
///
/// ตัวอย่าง:
/// THB  = 1
/// CNY  = 4.9  -> ¥1 = ฿4.9
/// USD  = 34   -> $1 = ฿34
const Map<Currency, double> _defaultRatesToThb = {
  Currency.thb: 1.0,
  Currency.cny: 4.9,
  Currency.usd: 30.0,
};

class AppData extends ChangeNotifier {
  static const _storageKey = 'finance_app_data_v1';

  final List<Account> accounts = [];
  final List<MoneyTransaction> transactions = [];
  final List<InvestmentAccount> investmentAccounts = [];

  /// ชื่อผู้ใช้ (ถามครั้งแรกที่หน้าแนะนำตัว/หน้าโปรไฟล์)
  /// null หรือค่าว่าง = ยังไม่เคยตั้งชื่อ
  String? userName;

  /// เปิด/ปิดการมองเห็นยอดรวม (เช่น ยอดเงินรวมทุกบัญชี, มูลค่าพอร์ตรวม)
  /// true = แสดงตัวเลขปกติ, false = ซ่อนด้วยจุด •
  bool balanceVisible = true;

  /// อัตราแลกเปลี่ยน:
  /// จำนวนบาทต่อ 1 หน่วยของ currency
  final Map<Currency, double> exchangeRates =
      Map.of(_defaultRatesToThb);

  int _idCounter = 0;
  SharedPreferences? _prefs;

  String _newId() => (_idCounter++).toString();

  static Future<AppData> load() async {
    final data = AppData._();
    data._prefs = await SharedPreferences.getInstance();
    await data._load();
    return data;
  }

  AppData._();

  // ============================================================
  // LOAD / SAVE
  // ============================================================

  Future<void> _load() async {
    final raw = _prefs?.getString(_storageKey);

    if (raw == null) {
      // ผู้ใช้ยังไม่เคยบันทึกข้อมูลใดๆ -> เริ่มต้นด้วยค่าว่างเปล่า
      // (ไม่สร้างบัญชี/ข้อมูลตัวอย่างให้อัตโนมัติ)
      await _save();
      return;
    }

    try {
      final root = jsonDecode(raw) as Map<String, dynamic>;

      _idCounter =
          (root['idCounter'] as num?)?.toInt() ?? 0;

      accounts
        ..clear()
        ..addAll(
          ((root['accounts'] as List?) ?? const []).map(
            (e) => Account.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          ),
        );

      transactions
        ..clear()
        ..addAll(
          ((root['transactions'] as List?) ?? const []).map(
            (e) => MoneyTransaction.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          ),
        );

      investmentAccounts
        ..clear()
        ..addAll(
          ((root['investmentAccounts'] as List?) ?? const []).map(
            (e) => InvestmentAccount.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          ),
        );

      // โหลดชื่อผู้ใช้ (ข้อมูลเก่าจะไม่มีค่านี้ -> null -> ถือว่ายังไม่เคยตั้งชื่อ)
      userName = root['userName'] as String?;

      // โหลดค่าเปิด/ปิดการมองเห็นยอดรวม (ข้อมูลเก่าจะไม่มีค่านี้ -> ค่าเริ่มต้น true)
      balanceVisible = (root['balanceVisible'] as bool?) ?? true;

      // โหลดอัตราแลกเปลี่ยน
      // ถ้าเป็นข้อมูลเก่าที่ไม่มี exchangeRates
      // จะใช้ค่า default
      final ratesJson = root['exchangeRates'] as Map?;

      if (ratesJson != null) {
        for (final c in Currency.values) {
          final value = ratesJson[c.code];

          if (value is num) {
            exchangeRates[c] = value.toDouble();
          }
        }
      }
    } catch (_) {
      accounts.clear();
      transactions.clear();
      investmentAccounts.clear();

      _idCounter = 0;

      await _save();
    }
  }

  Future<void> _save() async {
    final root = <String, dynamic>{
      'idCounter': _idCounter,

      'accounts':
          accounts.map((e) => e.toJson()).toList(),

      'transactions':
          transactions.map((e) => e.toJson()).toList(),

      'investmentAccounts':
          investmentAccounts.map((e) => e.toJson()).toList(),

      'userName': userName,

      'balanceVisible': balanceVisible,

      'exchangeRates': {
        for (final c in Currency.values)
          c.code: exchangeRates[c],
      },
    };

    await _prefs?.setString(
      _storageKey,
      jsonEncode(root),
    );
  }

  // ============================================================
  // USER PROFILE
  // ============================================================

  /// ตั้ง/แก้ไขชื่อผู้ใช้ (ใช้ในหน้าแนะนำตัวตอนเปิดแอปครั้งแรก)
  void setUserName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    userName = trimmed;

    notifyListeners();
    _save();
  }

  /// สลับเปิด/ปิดการมองเห็นยอดรวม (ยอดเงินรวมทุกบัญชี / มูลค่าพอร์ตรวม)
  void toggleBalanceVisibility() {
    balanceVisible = !balanceVisible;

    notifyListeners();
    _save();
  }

  // ============================================================
  // ACCOUNT
  // ============================================================

  Account accountById(String id) =>
      accounts.firstWhere((a) => a.id == id);

  Account? accountByIdOrNull(String? id) {
    if (id == null) return null;

    for (final account in accounts) {
      if (account.id == id) {
        return account;
      }
    }

    return null;
  }

  void addAccount(
    String name, [
    double initialBalance = 0,
    Currency currency = Currency.thb,
  ]) {
    accounts.add(
      Account(
        id: _newId(),
        name: name,
        balance: round2(initialBalance),
        currency: currency,
      ),
    );

    notifyListeners();
    _save();
  }

  /// แก้ไขชื่อ/สกุลเงินของบัญชี
  ///
  /// หมายเหตุ: ยอดเงิน (balance) ไม่ได้แก้ตรงๆ ที่นี่
  /// เพราะยอดเงินคำนวณมาจากรายการธุรกรรม
  /// ถ้าต้องการปรับยอด ให้ใช้ adjustAccountBalance แทน
  void updateAccount(
    String accountId, {
    String? name,
    Currency? currency,
  }) {
    final account = accountById(accountId);

    if (name != null && name.trim().isNotEmpty) {
      account.name = name.trim();
    }

    if (currency != null) {
      account.currency = currency;
    }

    notifyListeners();
    _save();
  }

  /// ปรับยอดคงเหลือของบัญชีแบบตรงๆ (เช่น แก้ยอดให้ตรงกับความเป็นจริง)
  void adjustAccountBalance(
    String accountId,
    double newBalance,
  ) {
    final account = accountById(accountId);
    account.balance = round2(newBalance);

    notifyListeners();
    _save();
  }

  /// ลบบัญชี
  ///
  /// รายการธุรกรรม/การโอนที่เคยผูกกับบัญชีนี้จะไม่ถูกลบตาม
  /// แต่จะถูกตั้งเป็น "ไม่ระบุบัญชี" (accountId/toAccountId = null)
  /// เพื่อไม่ให้ประวัติการเงินหายไป
  void deleteAccount(String accountId) {
    for (final t in transactions) {
      if (t.accountId == accountId) {
        t.accountId = null;
      }

      if (t.toAccountId == accountId) {
        t.toAccountId = null;
      }
    }

    accounts.removeWhere((a) => a.id == accountId);

    notifyListeners();
    _save();
  }

  /// รายการโอนเงินทั้งหมด (ใช้กับหน้าประวัติเดิมของแอป)
  List<MoneyTransaction> get transfers =>
      transactions.where((t) => t.type == TransactionType.transfer).toList();

  // ============================================================
  // CURRENCY
  // ============================================================

  /// ตั้งอัตราแลกเปลี่ยน
  ///
  /// ตัวอย่าง:
  /// setExchangeRate(Currency.cny, 4.9)
  ///
  /// หมายถึง:
  /// ¥1 = ฿4.9
  void setExchangeRate(
    Currency currency,
    double thbPerUnit,
  ) {
    if (thbPerUnit <= 0) return;

    exchangeRates[currency] = thbPerUnit;

    notifyListeners();
    _save();
  }

  /// แปลงเงินจากสกุลหนึ่งไปอีกสกุลหนึ่ง
  double convert(
    double amount,
    Currency from,
    Currency to,
  ) {
    if (from == to) {
      return amount;
    }

    final fromRate =
        exchangeRates[from] ?? 1.0;

    final toRate =
        exchangeRates[to] ?? 1.0;

    final amountInThb =
        amount * fromRate;

    return round2(amountInThb / toRate);
  }

  /// แปลงเงินเป็น THB
  double toThb(
    double amount,
    Currency currency,
  ) {
    return convert(
      amount,
      currency,
      Currency.thb,
    );
  }

  /// มูลค่าของ transaction เป็น THB
  double amountInThb(
    MoneyTransaction transaction,
  ) {
    final account =
        accountByIdOrNull(transaction.accountId);

    // ยังไม่ผูกบัญชี -> ถือเป็น THB
    if (account == null) {
      return transaction.amount;
    }

    return toThb(
      transaction.amount,
      account.currency,
    );
  }

  // ============================================================
  // TRANSACTION
  // ============================================================

  /// เพิ่มรายการรายรับ / รายจ่าย / โอนเงิน
  ///
  /// income / expense:
  /// amount = จำนวนเงินจริงในสกุลของ accountId
  ///
  /// transfer:
  /// amount = จำนวนที่หักจากต้นทาง
  /// destAmount = จำนวนที่เข้าปลายทาง
  void addTransaction({
    String? accountId,
    String? toAccountId,
    required double amount,
    double? destAmount,
    required String category,
    required TransactionType type,
    String? note,
    DateTime? date,
    String? satisfaction,
  }) {
    assert(
      type != TransactionType.transfer ||
          (
            accountId != null &&
            toAccountId != null &&
            accountId != toAccountId
          ),
      'Transfer ต้องระบุ accountId และ toAccountId ที่ไม่ซ้ำกัน',
    );

    final tx = MoneyTransaction(
      id: _newId(),
      accountId: accountId,
      toAccountId: toAccountId,
      amount: round2(amount),
      destAmount: destAmount == null ? null : round2(destAmount),
      category: category,
      type: type,
      note: note,
      date: date ?? DateTime.now(),
      satisfaction: satisfaction,
    );

    transactions.insert(0, tx);

    _applyTransactionEffect(tx);

    notifyListeners();
    _save();
  }

  // ============================================================
  // TRANSFER
  // ============================================================

  /// โอนเงินระหว่างบัญชี
  ///
  /// ตัวอย่าง:
  ///
  /// บัญชีต้นทาง = THB
  /// บัญชีปลายทาง = CNY
  /// destAmount = 500
  ///
  /// ระบบจะคำนวณเองว่า
  /// ต้องหัก THB เท่าไร
  ///
  /// เช่น:
  /// ¥500 × 4.9 = ฿2,450
  ///
  /// ผล:
  /// ต้นทาง -฿2,450
  /// ปลายทาง +¥500
  void addTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double destAmount,
    String? note,
    DateTime? date,
  }) {
    final fromAcc =
        accountById(fromAccountId);

    final toAcc =
        accountById(toAccountId);

    final sourceAmount = convert(
      destAmount,
      toAcc.currency,
      fromAcc.currency,
    );

    addTransaction(
      accountId: fromAccountId,
      toAccountId: toAccountId,
      amount: sourceAmount,
      destAmount: destAmount,
      category: 'โอนเงินระหว่างบัญชี',
      type: TransactionType.transfer,
      note: note,
      date: date,
    );
  }

  // ============================================================
  // MOVE TRANSACTION
  // ============================================================

  void moveTransactionToAccount(
    String transactionId,
    String newAccountId,
  ) {
    final tx = transactions.firstWhere(
      (t) => t.id == transactionId,
    );

    if (tx.accountId == newAccountId) {
      return;
    }

    _applyTransactionEffect(
      tx,
      reverse: true,
    );

    tx.accountId = newAccountId;

    _applyTransactionEffect(tx);

    notifyListeners();
    _save();
  }

  // ============================================================
  // UPDATE TRANSACTION
  // ============================================================

  void updateTransaction(
    String transactionId, {
    double? amount,
    double? destAmount,
    String? category,
    TransactionType? type,
    DateTime? date,
    String? accountId,
    String? toAccountId,
    Object? note = _unset,
    Object? satisfaction = _unset,
  }) {
    final tx = transactions.firstWhere(
      (t) => t.id == transactionId,
    );

    // คืนยอดเดิมก่อน
    _applyTransactionEffect(
      tx,
      reverse: true,
    );

    // อัปเดตข้อมูล
    if (amount != null) {
      tx.amount = round2(amount);
    }

    if (destAmount != null) {
      tx.destAmount = round2(destAmount);
    }

    if (category != null) {
      tx.category = category;
    }

    if (type != null) {
      tx.type = type;
    }

    if (date != null) {
      tx.date = date;
    }

    if (accountId != null) {
      tx.accountId = accountId;
    }

    if (toAccountId != null) {
      tx.toAccountId = toAccountId;
    }

    if (!identical(note, _unset)) {
      tx.note = note as String?;
    }

    if (!identical(
      satisfaction,
      _unset,
    )) {
      tx.satisfaction =
          satisfaction as String?;
    }

    // ใส่ผลกระทบใหม่
    _applyTransactionEffect(tx);

    notifyListeners();
    _save();
  }

  // ============================================================
  // DELETE
  // ============================================================

  void deleteTransaction(
    String transactionId,
  ) {
    final idx =
        transactions.indexWhere(
      (t) => t.id == transactionId,
    );

    if (idx == -1) return;

    final tx = transactions[idx];

    _applyTransactionEffect(
      tx,
      reverse: true,
    );

    transactions.removeAt(idx);

    notifyListeners();
    _save();
  }

  // ============================================================
  // APPLY TRANSACTION EFFECT
  // ============================================================

  /// จุดศูนย์กลางในการคำนวณผลกระทบต่อบัญชี
  ///
  /// income:
  /// +amount
  ///
  /// expense:
  /// -amount
  ///
  /// transfer:
  /// ต้นทาง -amount
  /// ปลายทาง +destAmount
  ///
  /// reverse:
  /// ทำตรงข้ามกับปกติ
  void _applyTransactionEffect(
    MoneyTransaction tx, {
    bool reverse = false,
  }) {
    final sign = reverse ? -1 : 1;

    switch (tx.type) {
      case TransactionType.income:
        final acc =
            accountByIdOrNull(tx.accountId);

        if (acc != null) {
          acc.balance = round2(
            acc.balance + sign * tx.amount,
          );
        }

        break;

      case TransactionType.expense:
        final acc =
            accountByIdOrNull(tx.accountId);

        if (acc != null) {
          acc.balance = round2(
            acc.balance - sign * tx.amount,
          );
        }

        break;

      case TransactionType.transfer:
        // -------------------------
        // ต้นทาง
        // -------------------------
        final from =
            accountByIdOrNull(tx.accountId);

        if (from != null) {
          from.balance = round2(
            from.balance - sign * tx.amount,
          );
        }

        // -------------------------
        // ปลายทาง
        // -------------------------
        final to =
            accountByIdOrNull(
          tx.toAccountId,
        );

        if (to != null) {
          // สำคัญ:
          // ปลายทางต้องใช้ destAmount
          // ไม่ใช่ amount
          final received =
              tx.destAmount ??
                  tx.amount;

          to.balance = round2(
            to.balance + sign * received,
          );
        }

        break;
    }
  }

  // ============================================================
  // REPEAT
  // ============================================================

  void repeatTransaction(
    MoneyTransaction tx,
  ) {
    addTransaction(
      accountId: tx.accountId,
      toAccountId: tx.toAccountId,
      amount: tx.amount,
      destAmount: tx.destAmount,
      category: tx.category,
      type: tx.type,
      note: tx.note,
      satisfaction: tx.satisfaction,
    );
  }

  // ============================================================
  // INVESTMENT
  // ============================================================

  void addInvestmentAccount(
    String name,
    double initialAmount, [
    Currency currency = Currency.thb,
  ]) {
    investmentAccounts.add(
      InvestmentAccount(
        id: _newId(),
        name: name,
        initialAmount: round2(initialAmount),
        currency: currency,
      ),
    );

    notifyListeners();
    _save();
  }

  void addProfitLoss(
    String investmentId,
    double amount, {
    String? note,
  }) {
    final inv =
        investmentAccounts.firstWhere(
      (i) => i.id == investmentId,
    );

    inv.entries.add(
      ProfitLossEntry(
        id: _newId(),
        amount: round2(amount),
        date: DateTime.now(),
        note: note,
      ),
    );

    notifyListeners();
    _save();
  }

  /// แก้ไขชื่อ/สกุลเงินบัญชีลงทุน
  void updateInvestmentAccount(
    String investmentId, {
    String? name,
    Currency? currency,
  }) {
    final inv = investmentAccounts.firstWhere(
      (i) => i.id == investmentId,
    );

    if (name != null && name.trim().isNotEmpty) {
      inv.name = name.trim();
    }

    if (currency != null) {
      inv.currency = currency;
    }

    notifyListeners();
    _save();
  }

  /// ลบบัญชีลงทุนทั้งหมด (รวมประวัติกำไร/ขาดทุนของบัญชีนั้น)
  void deleteInvestmentAccount(String investmentId) {
    investmentAccounts.removeWhere((i) => i.id == investmentId);

    notifyListeners();
    _save();
  }

  /// ลบรายการกำไร/ขาดทุนรายการเดียวออกจากบัญชีลงทุน
  void deleteProfitLoss(
    String investmentId,
    String entryId,
  ) {
    final inv = investmentAccounts.firstWhere(
      (i) => i.id == investmentId,
    );

    inv.entries.removeWhere((e) => e.id == entryId);

    notifyListeners();
    _save();
  }

  /// ถอนเงินจากบัญชีลงทุน ไปเข้าบัญชีเงินปกติ (เช่น บัญชีธนาคาร/เงินสด)
  ///
  /// amount = จำนวนเงินที่ถอน หน่วยเป็นสกุลเงินของบัญชีลงทุนนั้น
  /// ระบบจะแปลงเป็นสกุลเงินของบัญชีปลายทางให้อัตโนมัติ
  ///
  /// การถอนจะลด initialAmount ของกองทุนลง (ไม่นับเป็นขาดทุน)
  /// และสร้างรายการ "รายรับ" ในบัญชีปลายทาง เพื่อให้เห็นในประวัติด้วย
  void withdrawFromInvestment(
    String investmentId,
    String targetAccountId,
    double amount, {
    String? note,
  }) {
    final inv = investmentAccounts.firstWhere(
      (i) => i.id == investmentId,
    );

    if (amount <= 0) {
      throw StateError('จำนวนเงินที่ถอนต้องมากกว่า 0');
    }

    if (amount > inv.currentValue) {
      throw StateError('ยอดเงินในบัญชีลงทุนไม่พอสำหรับการถอนนี้');
    }

    final targetAccount = accountById(targetAccountId);

    final destAmount = convert(
      amount,
      inv.currency,
      targetAccount.currency,
    );

    inv.initialAmount = round2(inv.initialAmount - amount);

    addTransaction(
      accountId: targetAccountId,
      amount: destAmount,
      category: 'ถอนเงินจากการลงทุน',
      type: TransactionType.income,
      note: note ?? 'ถอนจาก ${inv.name}',
    );
  }

  // ============================================================
  // TOTAL BALANCE
  // ============================================================

  /// ยอดเงินรวมทุกบัญชี
  ///
  /// สำคัญ:
  /// ทุกบัญชีจะถูกแปลงเป็น THB ก่อนรวม
  ///
  /// เช่น:
  /// THB 5,000
  /// CNY ¥1,000 = ฿4,900
  ///
  /// total = ฿9,900
  double get totalBalance {
    return round2(
      accounts.fold(
        0.0,
        (sum, account) =>
            sum +
            toThb(
              account.balance,
              account.currency,
            ),
      ),
    );
  }

  /// มูลค่าพอร์ตลงทุนรวมทั้งหมด
  ///
  /// สำคัญ: ทุกกองทุนจะถูกแปลงเป็น THB ก่อนรวม
  /// เหมือนกับ totalBalance
  double get totalPortfolioValue =>
      round2(
        investmentAccounts.fold(
          0.0,
          (sum, investment) =>
              sum +
              toThb(
                investment.currentValue,
                investment.currency,
              ),
        ),
      );

  // ============================================================
  // PERIOD
  // ============================================================

  DateTime? _periodStart(
    Period p,
  ) {
    final now = DateTime.now();

    switch (p) {
      case Period.day:
        return DateTime(
          now.year,
          now.month,
          now.day,
        );

      case Period.week:
        return DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(
          Duration(
            days: now.weekday - 1,
          ),
        );

      case Period.month:
        return DateTime(
          now.year,
          now.month,
          1,
        );

      case Period.year:
        return DateTime(
          now.year,
          1,
          1,
        );

      case Period.threeYears:
        return DateTime(
          now.year - 3,
          now.month,
          now.day,
        );

      case Period.all:
        return null;
    }
  }

  List<MoneyTransaction> transactionsInPeriod(
    Period p,
  ) {
    final start = _periodStart(p);

    if (start == null) {
      return transactions;
    }

    return transactions
        .where(
          (t) => !t.date.isBefore(start),
        )
        .toList();
  }

  // ============================================================
  // INCOME / EXPENSE
  // ============================================================

  /// รายรับรวมในช่วงเวลา
  /// ทุกสกุลเงินจะถูกแปลงเป็น THB ก่อนรวม
  double incomeInPeriod(
    Period p,
  ) {
    return round2(
      transactionsInPeriod(p)
          .where(
            (t) =>
                t.type ==
                TransactionType.income,
          )
          .fold(
            0.0,
            (sum, transaction) =>
                sum +
                amountInThb(transaction),
          ),
    );
  }

  /// รายจ่ายรวมในช่วงเวลา
  /// ทุกสกุลเงินจะถูกแปลงเป็น THB ก่อนรวม
  double expenseInPeriod(
    Period p,
  ) {
    return round2(
      transactionsInPeriod(p)
          .where(
            (t) =>
                t.type ==
                TransactionType.expense,
          )
          .fold(
            0.0,
            (sum, transaction) =>
                sum +
                amountInThb(transaction),
          ),
    );
  }

  // ============================================================
  // FREQUENCY / ใช้บ่อย
  // ============================================================

  /// นับความถี่ของ "หมวดหมู่" ที่เคยบันทึกไว้ แล้วคืน 5 อันดับที่ซ้ำมากที่สุด
  ///
  /// ใช้แสดงเป็นปุ่มลัดในหน้าบันทึกรายรับ/รายจ่าย
  /// เรียงจากมากไปน้อย ถ้าความถี่เท่ากันจะเอาอันที่ใช้ล่าสุดขึ้นก่อน
  List<String> topCategories(
    TransactionType type, {
    int limit = 5,
  }) {
    final counts = <String, int>{};
    final lastUsedIndex = <String, int>{};

    // transactions เรียงจากใหม่ไปเก่าอยู่แล้ว (insert(0, tx))
    // ดังนั้น index ยิ่งน้อย = ยิ่งใหม่
    for (var i = 0; i < transactions.length; i++) {
      final t = transactions[i];
      if (t.type != type) continue;

      counts[t.category] = (counts[t.category] ?? 0) + 1;
      lastUsedIndex.putIfAbsent(t.category, () => i);
    }

    final sorted = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        if (byCount != 0) return byCount;
        return lastUsedIndex[a]!.compareTo(lastUsedIndex[b]!);
      });

    return sorted.take(limit).toList();
  }

  /// นับความถี่ของ "บันทึกช่วยจำ" (note) ที่เคยพิมพ์ไว้ แล้วคืน 5 อันดับที่ซ้ำมากที่สุด
  ///
  /// ใช้แสดงเป็นปุ่มลัดให้กดใส่ได้เลย ไม่ต้องพิมพ์ซ้ำ
  /// นับเฉพาะ note ที่ซ้ำอย่างน้อย 2 ครั้ง (ถ้าพิมพ์ครั้งเดียวไม่ถือว่า "ใช้บ่อย")
  List<String> topNotes(
    TransactionType type, {
    int limit = 5,
    int minCount = 2,
  }) {
    final counts = <String, int>{};
    final lastUsedIndex = <String, int>{};

    for (var i = 0; i < transactions.length; i++) {
      final t = transactions[i];
      if (t.type != type) continue;

      final note = t.note?.trim();
      if (note == null || note.isEmpty) continue;

      counts[note] = (counts[note] ?? 0) + 1;
      lastUsedIndex.putIfAbsent(note, () => i);
    }

    final sorted = counts.keys.where((k) => counts[k]! >= minCount).toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        if (byCount != 0) return byCount;
        return lastUsedIndex[a]!.compareTo(lastUsedIndex[b]!);
      });

    return sorted.take(limit).toList();
  }

  /// จำนวนครั้งที่เคยใช้หมวดหมู่นี้ (ใช้โชว์เป็นตัวเลขเล็กๆ ข้างปุ่มลัด)
  int categoryUseCount(String category, TransactionType type) {
    return transactions
        .where((t) => t.type == type && t.category == category)
        .length;
  }

  // ============================================================
  // PERIOD แบบกำหนดเอง (ค้นหาตามวันที่/เดือน/ปี)
  // ============================================================

  /// รายการธุรกรรมในช่วงวันที่ที่กำหนดเอง (รวมวันเริ่มและวันสิ้นสุด)
  List<MoneyTransaction> transactionsBetween(
    DateTime start,
    DateTime end,
  ) {
    final from = DateTime(start.year, start.month, start.day);
    final to = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

    return transactions
        .where((t) => !t.date.isBefore(from) && !t.date.isAfter(to))
        .toList();
  }

  /// รายรับรวมในช่วงวันที่ที่กำหนดเอง (แปลงเป็น THB ก่อนรวม)
  double incomeBetween(DateTime start, DateTime end) => round2(
        transactionsBetween(start, end)
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (sum, t) => sum + amountInThb(t)),
      );

  /// รายจ่ายรวมในช่วงวันที่ที่กำหนดเอง (แปลงเป็น THB ก่อนรวม)
  double expenseBetween(DateTime start, DateTime end) => round2(
        transactionsBetween(start, end)
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (sum, t) => sum + amountInThb(t)),
      );

  /// รายจ่ายแยกตามหมวดหมู่ในช่วงวันที่ที่กำหนดเอง
  Map<String, double> expenseByCategoryBetween(
    DateTime start,
    DateTime end,
  ) {
    final map = <String, double>{};

    for (final t in transactionsBetween(start, end)
        .where((t) => t.type == TransactionType.expense)) {
      map[t.category] = round2((map[t.category] ?? 0) + amountInThb(t));
    }

    return map;
  }

  // ============================================================
  // EXPENSE BY CATEGORY
  // ============================================================

  /// รายจ่ายแยกตามหมวดหมู่
  ///
  /// ทุกสกุลเงินจะถูกแปลงเป็น THB ก่อนรวม
  Map<String, double> expenseByCategory(
    Period p,
  ) {
    final map = <String, double>{};

    for (final t in transactionsInPeriod(p)
        .where(
          (t) =>
              t.type ==
              TransactionType.expense,
        )) {
      final amount =
          amountInThb(t);

      map[t.category] = round2(
        (map[t.category] ?? 0) + amount,
      );
    }

    return map;
  }
}

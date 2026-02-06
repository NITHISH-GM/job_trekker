import 'package:hive_flutter/hive_flutter.dart';
import 'package:job_trekker/domain/models/linked_account.dart';

class AccountRepository {
  static const String _boxName = 'linked_accounts';

  Box<LinkedAccount> get _box => Hive.box<LinkedAccount>(_boxName);

  List<LinkedAccount> getAllAccounts() {
    return _box.values.toList();
  }

  Future<void> addAccount(LinkedAccount account) async {
    await _box.put(account.email, account);
  }

  Future<void> removeAccount(String email) async {
    await _box.delete(email);
  }

  Future<void> toggleAccountStatus(String email) async {
    final account = _box.get(email);
    if (account != null) {
      final updated = LinkedAccount(
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        isActive: !account.isActive,
      );
      await _box.put(email, updated);
    }
  }

  Stream<List<LinkedAccount>> watchAccounts() {
    return _box.watch().map((_) => getAllAccounts());
  }
}

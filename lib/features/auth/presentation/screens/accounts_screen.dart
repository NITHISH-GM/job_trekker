import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_trekker/domain/models/linked_account.dart';
import 'package:job_trekker/core/services/auth_service.dart';
import 'package:job_trekker/core/providers.dart';

final accountsStreamProvider = StreamProvider<List<LinkedAccount>>((ref) {
  return ref.watch(accountRepositoryProvider).watchAccounts();
});

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Managed Accounts'),
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(child: Text('No accounts linked yet.'));
          }
          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: account.photoUrl != null ? NetworkImage(account.photoUrl!) : null,
                  child: account.photoUrl == null ? Text(account.displayName[0]) : null,
                ),
                title: Text(account.displayName),
                subtitle: Text(account.email),
                trailing: Switch(
                  value: account.isActive,
                  onChanged: (_) => ref.read(accountRepositoryProvider).toggleAccountStatus(account.email),
                ),
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Remove Account'),
                      content: Text('Are you sure you want to remove ${account.email}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () {
                            ref.read(accountRepositoryProvider).removeAccount(account.email);
                            Navigator.pop(context);
                          },
                          child: const Text('Remove', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final userCredential = await authService.signInWithGoogle();
          if (userCredential != null && userCredential.user != null) {
            final user = userCredential.user!;
            await ref.read(accountRepositoryProvider).addAccount(
              LinkedAccount(
                email: user.email!,
                displayName: user.displayName ?? 'User',
                photoUrl: user.photoURL,
              ),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Account'),
      ),
    );
  }
}

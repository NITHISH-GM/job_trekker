import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:job_trekker/data/repositories/application_repository.dart';
import 'package:job_trekker/data/repositories/account_repository.dart';
import 'package:job_trekker/core/services/auth_service.dart';

final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  return ApplicationRepository();
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStreamProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

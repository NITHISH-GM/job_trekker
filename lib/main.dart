import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:job_trekker/core/app_theme.dart';
import 'package:job_trekker/core/constants/app_strings.dart';
import 'package:job_trekker/features/auth/presentation/screens/login_screen.dart';
import 'package:job_trekker/features/home/presentation/screens/main_screen.dart';
import 'package:job_trekker/domain/models/job_application.dart';
import 'package:job_trekker/domain/models/linked_account.dart';
import 'package:job_trekker/core/services/notification_service.dart';
import 'package:job_trekker/data/repositories/application_repository.dart';
import 'package:job_trekker/data/repositories/account_repository.dart';
import 'package:job_trekker/data/repositories/hive_repository.dart';
import 'package:job_trekker/core/providers.dart';
import 'package:job_trekker/firebase_options.dart';
import 'package:job_trekker/features/settings/presentation/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final hiveRepo = HiveRepository();
  try {
    // This now handles initialization AND opening of all required boxes
    await hiveRepo.init();
  } catch (e) {
    debugPrint('Hive init error: $e');
  }

  final appRepository = ApplicationRepository();
  final accountRepository = AccountRepository();

  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (e) {
    debugPrint('Firebase initialization failed: $e. App will run in offline mode.');
  }

  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        applicationRepositoryProvider.overrideWithValue(appRepository),
        accountRepositoryProvider.overrideWithValue(accountRepository),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStreamProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const MainScreen();
          }
          return const LoginScreen();
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Scaffold(body: Center(child: Text('An error occurred: $err'))),
      ),
    );
  }
}

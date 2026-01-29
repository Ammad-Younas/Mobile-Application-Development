import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olxapp/providers/auth_provider.dart';
import 'package:olxapp/services/local_notifications_service.dart';
import 'package:olxapp/services/fcm_service.dart';
import 'auth_screens/login_screen.dart';
import 'bottom_bar.dart';
import 'firebase_options.dart';
import 'on_boarding_screen.dart';
import 'main_screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Initialize local notifications
  await LocalNotificationService().initialize();
  
  // ✅ Initialize FCM
  await FCMService().initialize();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Get Cars',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A5F),
          primary: const Color(0xFF1E3A5F),
        ),
      ),

      // 🚀 This decides where user goes depending on login state
      home: authState.when(
        data: (user) =>
        user != null ? PersistentNavWrapper() : LoginScreen(),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          body: Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
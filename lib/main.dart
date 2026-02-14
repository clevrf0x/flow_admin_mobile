// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Make status bar transparent globally
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const FlowAdminApp());
}

class FlowAdminApp extends StatelessWidget {
  const FlowAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flow Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto', // System default — can swap to custom font later
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B7ACC),
          brightness: Brightness.light,
        ),
        // Remove default splash/highlight on InkWell for cleaner look
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      routerConfig: appRouter,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'core/routes.dart';
import 'core/logger.dart';
import 'pages/login_page.dart';
import 'database/database_helper.dart';
import 'theme/app_theme.dart';
import 'providers/provider_setup.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized first
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  
  // Initialize database factory BEFORE running app
  // This is critical for desktop platforms (Windows, Linux, macOS)
  DatabaseHelper.initDatabaseFactory();
  
  logger.i('🚀 App initialized successfully');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderSetup.wrapWithProviders(
      MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.light(),
        home: const LoginPage(),
        routes: AppRoutes.getRoutes(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

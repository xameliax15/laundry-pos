import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';

/// Setup all providers untuk aplikasi
class ProviderSetup {
  static List<ChangeNotifierProvider> getAllProviders() {
    return [
      /// Auth Provider
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(),
      ),

      /// Transaksi Provider
      ChangeNotifierProvider<TransaksiProvider>(
        create: (_) => TransaksiProvider(),
      ),
    ];
  }

  /// Wrap MaterialApp dengan MultiProvider
  static Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: getAllProviders(),
      child: child,
    );
  }
}

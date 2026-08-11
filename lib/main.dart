import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_almacen_plus/core/data/drift/app_database.dart';
import 'package:mi_almacen_plus/core/providers/app_providers.dart';
import 'package:mi_almacen_plus/core/routing/app_router.dart';
import 'package:mi_almacen_plus/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await AppDatabase.open();
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: const MiAlmacenApp(),
    ),
  );
}

/// App root: ProviderScope bootstrap + MaterialApp.router (design D7, D11).
class MiAlmacenApp extends StatelessWidget {
  const MiAlmacenApp({super.key, this.router});

  /// Router to use; defaults to the shared [appRouter] singleton.
  /// Tests pass a freshly built router so navigator state never leaks
  /// between test cases.
  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mi Almacén',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router ?? appRouter,
    );
  }
}
